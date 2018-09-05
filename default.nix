{ config, pkgs, lib, ...}: {

  options.simple-hydra = {
    hostName = lib.mkOption {
      description = ''
        The hostname to use for nginx, acme, and the notification
        sender.
      '';
      type = lib.types.str;
      example = "hydra.example.org";
    };

    enable = lib.mkOption {
      description = ''
        Enable the simple Hydra setup. This will enable
        `services.postfix`, `services.postgresql`, and configure
        various `hydra` services.
      '';
      type = lib.types.bool;
      default = false;
    };

    localBuilder = {
      enable = lib.mkOption {
        description = ''
          Whether to use localhost as a build machine. This adds
          localhost to `nix.buildMachines`.
        '';
        type = lib.types.bool;
        default = true;
      };

      maxJobs = lib.mkOption {
        description = ''
          Number of jobs to use with `useLocalBuilder`. Defaults to
          `nix.maxJobs`.
        '';
        type = lib.types.int;
        default = config.nix.maxJobs;
      };

      systems = lib.mkOption {
        description = ''
          The systems the local builder can build.
        '';
        type = lib.types.listOf lib.types.str;
        default = ["x86_64-linux" "i686-linux"];
      };

      supportedFeatures = lib.mkOption {
        description = ''
          Features to supply for `supportedFeatures`.
        '';
        type = lib.types.listOf lib.types.string;
        default = [];
      };
    };

    useNginx = lib.mkOption {
      description = ''
        Configure
        `services.nginx.virtualHosts.''${simple-hydra.hostName}` as an
        HTTP(S) proxy. This will automatically configure
        ACME/LetsEncrypt and redirect HTTP to HTTPS.
      '';
      type = lib.types.bool;
      default = true;
    };

    recommendedNixSettings = lib.mkOption {
      description = ''
        Configures automatic Nix GC and store optimisation.
      '';
      type = lib.types.bool;
      default = false;
    };

    store_uri = lib.mkOption {
      description = ''
      '';
      type = lib.types.str;
      defaultText = "file:///var/lib/hydra/cache?secret-key=/etc/nix/\${hostName}/secret";
    };
  };

  config = let
    hostName = config.simple-hydra.hostName;
  in lib.mkIf config.simple-hydra.enable {
    services.postfix = {
      enable = true;
      setSendmail = true;
      domain = hostName;
    };

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql; 
    };

    simple-hydra.store_uri = lib.mkOptionDefault "file:///var/lib/hydra/cache?secret-key=/etc/nix/${hostName}/secret";

    programs.ssh.extraConfig = ''
      StrictHostKeyChecking no
    '';

    services.hydra = {
      enable = true;  
      hydraURL = lib.mkOptionDefault "https://${hostName}";
      notificationSender = "hydra@${hostName}";
      useSubstitutes = true;
      smtpHost = "localhost";
      extraConfig = ''
        store_uri = ${config.simple-hydra.store_uri}
      ''; 
    };

    services.nginx = lib.mkIf config.simple-hydra.useNginx {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts."${hostName}" = {
        forceSSL = true;
        enableACME = true;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.services.hydra.port}";
      };
    };

    systemd.services.hydra-manual-setup = {
      description = "Initial setup for Hydra";
      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = true;
      wantedBy = [ "multi-user.target" ];
      requires = [ "hydra-init.service" ];
      after = [ "hydra-init.service" ];
      environment = builtins.removeAttrs (config.systemd.services.hydra-init.environment) ["PATH"];
      script = ''
        if [ ! -e ~hydra/.setup-is-complete ]; then
          # create signing keys
          /run/current-system/sw/bin/install -d -m 551 /etc/nix/${hostName}
          /run/current-system/sw/bin/nix-store --generate-binary-cache-key ${hostName} /etc/nix/${hostName}/secret /etc/nix/${hostName}/public
          /run/current-system/sw/bin/chown -R hydra:hydra /etc/nix/${hostName}
          /run/current-system/sw/bin/chmod 440 /etc/nix/${hostName}/secret
          /run/current-system/sw/bin/chmod 444 /etc/nix/${hostName}/public
          # create cache
          /run/current-system/sw/bin/install -d -m 755 /var/lib/hydra/cache
          /run/current-system/sw/bin/chown -R hydra-queue-runner:hydra /var/lib/hydra/cache
          # done
          touch ~hydra/.setup-is-complete
        fi
      '';
    };

    nix.gc = lib.mkIf config.simple-hydra.recommendedNixSettings {
      automatic = true;
      dates = "15 3 * * *";
    };
    nix.autoOptimiseStore = lib.mkIf config.simple-hydra.recommendedNixSettings true;

    nix.trustedUsers = ["hydra" "hydra-evaluator" "hydra-queue-runner"];

    nix.buildMachines = lib.mkIf config.simple-hydra.localBuilder.enable [
      {
        hostName = "localhost";
        systems = config.simple-hydra.localBuilder.systems;
        maxJobs = config.simple-hydra.localBuilder.maxJobs;
        supportedFeatures = config.simple-hydra.localBuilder.supportedFeatures;
      }
    ];
  };
}

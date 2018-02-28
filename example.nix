# Use this with `nixos-rebuild build-vm` to build a VM for testing Hydra.
#
#   $ nixos-rebuild -I nixos-config=`pwd`/example.nix build-vm
#   $ ./result/bin/run-nixos-vm

{ pkgs, config, ... }:

{
  imports = [./. <nixpkgs/nixos/modules/virtualisation/qemu-vm.nix>];

  users.users.root.initialPassword = "test";

  virtualisation = {
    graphics = false;
    memorySize = 8000; # M
    diskSize = 50000; # M
    writableStoreUseTmpfs = false;
  };

  # Uncomment and fill in to support remote builders, like macOS.
  # nix.buildMachines = [
  #   {
  #     hostName = "<host>";
  #     sshUser = "<uxer>";
  #     sshKey = "<path to key>";
  #     system = "x86_64-darwin";
  #     maxJobs = 1;
  #   }
  # ];

  simple-hydra.enable = true;
  simple-hydra.hostName = "hydra.example.org";
  simple-hydra.useNginx = false;

  networking.firewall.allowedTCPPorts = [ 3000 ];
}

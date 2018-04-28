`simple-hydra`
---

`simple-hydra` is a NixOS module for easily setting up hydra. To
use it, simply add this to your `configuration.nix`:

```nix
{ pkgs, config, lib, ... }:
{

  # ...

  imports = [./simple-hydra];
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  simple-hydra = {
    enable = true;
    hostName = "example.org";
  };

  # ...

}
```

See `default.nix` for descriptions of other available options.

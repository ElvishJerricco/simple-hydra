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

Once the server is running, you need to create an admin user on the
command line.

```bash
hydra-create-user USERNAME --full-name 'FULL NAME' --email-address 'EMAIL' --password 12345 --role admin
```

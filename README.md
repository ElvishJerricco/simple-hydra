`simple-hydra`
---

`simple-hydra.nix` is a NixOS module for easily setting up hydra. To
use it, simply add this to your `configuration.nix`:

```nix
{ pkgs, config, lib, ... }:
{

  # ...

  imports = [./simple-hydra];
  simple-hydra = {
    enable = true;
    hostName = "example.org";
  };

  # ...

}
```

See `simple-hydra.nix` for descriptions of other available options.

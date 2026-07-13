{ lib, ... }:
{
  # Values that should not appear in this repo; nix-private defines them.
  options.private.storeHost = lib.mkOption {
    type = lib.types.str;
    description = "SSH-reachable address of the host serving the nix store.";
  };
}

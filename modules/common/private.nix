{ lib, ... }:
let
  mkStr =
    description:
    lib.mkOption {
      type = lib.types.str;
      inherit description;
    };
in
{
  # Values that should not appear in this repo; nix-private defines them.
  options.private = {
    cacheHost = mkStr "Pull hostname for the binary cache.";
    s3Host = mkStr "S3 API hostname on the ocar proxy.";
    niks3Host = mkStr "niks3 API hostname on the ocar proxy.";
    webRootDomain = mkStr "Garage web endpoint root_domain, with leading dot.";
    cachePublicKey = mkStr "Narinfo signing public key for the binary cache.";
  };
}

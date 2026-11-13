# Reroute

OCI ARM host. `reroute.nix` owns its hardware, networking and deployment values;
`reroute-disk-config.nix` describes only the 50 GB boot volume. The existing
`/data` volume is mounted separately and is never formatted by disko.

This initial configuration provides administration access, not the full running
application deployment. Do not switch the live host to this intermediate branch:
its application services will be added in subsequent commits.

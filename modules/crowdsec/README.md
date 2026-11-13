# CrowdSec

Importing this module enables CrowdSec and its nftables firewall bouncer.
It consumes SSH and Traefik journal entries. Traefik must emit JSON access logs
with the User-Agent header retained; the reverse proxy is configured separately.

The host supplies exceptional static-media paths by domain. Only matching HTTP
404 events are excluded; there is no client-IP exemption. The Reroute exception
covers Jellyfin image endpoints on `furizon.ff15.eu`.

Decisions apply only to the configured TCP ports (22, 80, 443 by default).
WireGuard's UDP transport remains reachable. Bouncer credentials are generated
at runtime outside the Nix store. This module does not enable Fail2ban.

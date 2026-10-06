{
  lib,
  fetchzip,
  addons,
}:
let
  bottle = addons.buildKodiAddon rec {
    pname = "bottle";
    namespace = "script.module.bottle";
    version = "0.13.2";
    src = fetchzip {
      url = "https://mirrors.kodi.tv/addons/omega/${namespace}/${namespace}-${version}.zip";
      hash = "sha256-lrFGT+oGl8ulq+tL8E00Yl9EmhMUkZHVR4TiglS2NF4=";
    };
    passthru.pythonPath = "lib";
    meta.license = lib.licenses.mit;
  };
in
addons.buildKodiAddon {
  pname = "tubecast";
  namespace = "script.tubecast";
  version = "1.5.0+matrix.1";
  src = fetchzip {
    url = "https://github.com/enen92/script.tubecast/archive/fb52487cc31119df56012c1c9ee058c25c76c77d.tar.gz";
    hash = "sha256-GbMj6wY6rnmPp/PYNfapeTWeyROLJTrOIEHTjwnDjsw=";
  };
  propagatedBuildInputs = [
    bottle
    addons.requests
    addons.youtube
  ];
  # Manual pairing needs device_id too, not just SSDP pairing:
  # https://github.com/enen92/script.tubecast/issues/53#issuecomment-890308376
  patches = [ ./tubecast-pairing.patch ];
  # Upstream picks a random TCP port; pin it so the firewall stays narrow.
  postPatch = ''
    substituteInPlace resources/lib/tubecast/chromecast.py \
      --replace-fail "args=('0.0.0.0', 0)" "args=('0.0.0.0', 8008)"
  '';
  meta = {
    description = "YouTube Cast V1 receiver for Kodi";
    homepage = "https://github.com/enen92/script.tubecast";
    license = lib.licenses.mit;
  };
}

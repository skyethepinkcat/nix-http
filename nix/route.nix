{
  pkgs ? import <nixpkgs> { },
  http ? import ./lib/httplib.nix { inherit pkgs; },
  request,
}:
  (pkgs.lib.evalModules {
    modules = [
      ./n4Modules
    ];
    specialArgs = {
      inherit http request;
    };
  }).config.finalReply

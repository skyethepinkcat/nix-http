{
  pkgs ? import <nixpkgs> { },
}:
let
  inherit (pkgs) lib;
  inherit (lib) types;
in
rec {

  directory = types.attrsOf (types.oneOf types.path directory);

}

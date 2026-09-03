{
  pkgs ? import <nixpkgs> { },
}:
with pkgs.lib;
with builtins;
let
  request_text = readFile ./request.txt;
  request_split = splitString "\n" request_text;
  body_start_index = lists.findFirstIndex (i: i == "\n") null request_split;
  headers_text = filter (e: e != "") (
    if body_start_index != null then
      lists.drop 1 (lists.take body_start_index request_split)
    else
      lists.drop 1 request_split
  );

  request = {
    type = elemAt (splitString " " (elemAt request_split 0)) 0;
    path = elemAt (splitString " " (elemAt request_split 0)) 1;
    protocol = elemAt (splitString " " (elemAt request_split 0)) 2;
    headers = listToAttrs (
      map (
        header_text:
        let
          header_name = elemAt (splitString ": " header_text) 0;
          header_value = elemAt (splitString ": " header_text) 1;
        in
        {
          name = header_name;
          value = header_value;
        }
      ) headers_text
    );
    body =
      if body_start_index == null then null else (join "\n" (lists.drop body_start_index request_split));
  };
  route = import ./route.nix { inherit pkgs; };
in
pkgs.writeTextFile {
  name = "http-reply";
  text = route request;
}

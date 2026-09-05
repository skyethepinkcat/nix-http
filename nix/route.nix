{
  pkgs ? import <nixpkgs> { },
}:
request: state_in:
with builtins;
with pkgs.lib;
let
  routes = {
    "GET" = {
      "/" = mkReply {
        body = ''
          <html>
          <head>
          <title>I hate this</title>
          </head>
          <body>
          <h1> Hello world! </h1>
          </body>
          </head>
        '';
      };
      "/bounce" = mkReply {
        body = toJSON request;
        headers = {
          Content-Type = "application/json";
          Server = "nix";
        };
      };
      "POST" = {
      };
    };
  };
in
routes.${request.type}.${request.path} or (mkReply {
  status = {
    code = 404;
    reason = "Not Found";
  };
  body = ''
    <html>
    <head>
    <title>I hate this</title>
    </head>
    <body>
    <h1> 404 Not Found </h1>
    </body>
    </head>
  '';
})

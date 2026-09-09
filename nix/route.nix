{
  pkgs ? import <nixpkgs> { },
  http ? import ./lib/httplib.nix { inherit pkgs; },
}:
request:
with builtins;
with pkgs.lib;
let
  routes = {
    "GET" = {
      "/" = http.buildReply {
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
      "/bounce" = http.buildReply {
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
routes.${request.type}.${request.path} or (http.buildReply {
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
    </head>'';
})

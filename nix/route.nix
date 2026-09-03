{
  pkgs ? import <nixpkgs> { },
}:
request:
with builtins;
with pkgs.lib;
let
  mkReply =
    {
      protocol ? "HTTP/1.1",
      body ? "",
      status ? {
        code = 200;
        reason = "OK";
      },
      headers ? {
        Content-Type = "text/html";
        Server = "nix";
        Cache-Control = "public, max-age=3600";
      },
    }:
    let
      headers_text = join "\n" (mapAttrsToList (name: value: "${name}: ${value}") headers);
    in
    ''
      ${protocol} ${toString status.code} ${status.reason}
      ${headers_text}

      ${body}
    '';
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

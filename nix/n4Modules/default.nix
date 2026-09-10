{
  pkgs,
  http,
  lib,
  request,
  config,
  ...
}:
let
  routeModule = lib.types.submodule (
    # This is an attribute set for the submodule
    attrs: {
      options = {
        method = lib.mkOption {
          # TODO This should probably be an enum.
          type = lib.types.str;
          description = "The HTTP method this route uses.";
          example = "POST";
          default = "GET";
        };
        path = lib.mkOption {
          type = lib.types.str;
          description = "The absolute path the route uses. This can be a regex.";
          default = "/";
          example = "/api/.*";
        };
        host = lib.mkOption {
          type = lib.types.str;
          description = "A specific host to apply to. This can be a regex.";
          default = ".*";
          example = "localhost";
        };
        match = lib.mkOption {
          type = lib.types.anything;
          # TODO This is fucking stupid we should definetly be able to handle at least some logic.
          description = "The function that defines what matches this route. Currently the user must handle ordering.";
          internal = true;
        };

        reply = lib.mkOption {
          type = lib.types.nullOr replyModule;
          default = null;
          description = "The reply to use for this route. If function is set, this is ignored.";
        };

        function = lib.mkOption {
          type = lib.types.anything;
          description = "The function to call with the request. This should take a single request argument, and defaults to a singleton that returns reply.";
        };
      };
      config = {
        match =
          request:
          let
            inherit (request.headers) host;
            inherit (request) path method;
            matchHost = (host == attrs.config.host) || (builtins.match attrs.config.host host != null);
            matchPath = (path == attrs.config.path) || (builtins.match attrs.config.path path != null);
            matchMethod =
              (method == attrs.config.method) || (builtins.match attrs.config.method method != null);
          in
          matchHost && matchPath && matchMethod;
        function = _: attrs.config.reply;
      };
    }
  );
  replyModule = lib.types.submodule {
    options = {
      protocol = lib.mkOption {
        type = lib.types.str;
        default = "HTTP/1.1";
      };
      body = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      status = lib.mkOption {
        type = lib.types.submodule {
          options = {
            code = lib.mkOption {
              type = lib.types.int;
              description = "HTTP Response code.";
              default = 200;
              example = 404;
            };
            reason = lib.mkOption {
              type = lib.types.str;
              description = "HTTP response reason.";
              default = "OK";
              example = "Not Found";
            };
          };
        };
      };
      headers = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = {
          content-type = "application/json";
        };
      };
    };
  };
  route404 = {
    method = ".*";
    host = ".*";
    path = ".*";
    reply = config.default404;
  };
in
{
  imports = [
    ./landing.nix
  ];

  options = {

    default404 = lib.mkOption {
      type = replyModule;
      default = {
        status = {
          code = 404;
          reason = "Not Found";
        };
        body = builtins.readFile ./static/404.html;
      };
    };

    routes = lib.mkOption {
      type = lib.types.listOf routeModule;
    };
    finalReply = lib.mkOption {
      type = lib.types.anything;
      description = "The final reply to be run through buildReply and sent to the server.";
      internal = true;
    };
  };
  config = {

    finalReply = # Filter out all the matching routes, and then take the first.
      http.buildReply (
        (builtins.elemAt (lib.lists.take 1 (builtins.filter (r: r.match request) config.routes)) 0).function
          request
      );

    # The 404 page will match anything, so it should always be last.
    routes = lib.mkOrder 99999 [
      route404
    ];

  };

}

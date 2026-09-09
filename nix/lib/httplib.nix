{
  pkgs ? import <nixpkgs> { },
}:
rec {
  /*
    This function returns a given element if a condition is true, otherwise returns null.

    # Type

    ```
    orNull :: Boolean -> a -> (a|null)
    ```

    # Arguments

    cond
    : The condition to be checked

    e
    : The element to be returned.
  */
  orNull = cond: e: if cond then e else null;

  /*
    This function returns null if elem is null, otherwise continues to evaluate.

    # Type

    ```
    unlessNull :: a -> b -> (b|null)
    ```

    # Arguments

    e
    : The element to be checked

    continue
    : The following evaluation to be returned.
  */
  unlessNull = e: continue: if e == null then null else continue;

  /*
    This function turns a comma seperated string into a list. Noteably, it handles ignoring whitespace.

    # Type
    ```
    commaSeperatedToList :: String -> [String]
    ```

    # Arguments

    comma_seperated
    : The string that contains a comma seperated list.
  */
  commaSeperatedToList =
    with builtins;
    comma_seperated:
    assert (isString comma_seperated);
    filter isString (split ",[[:space:]]?");

  buildReply =
    with builtins;
    with pkgs.lib;
    {
      protocol ? "HTTP/1.1",
      body ? "",
      status ? {
        code = 200;
        reason = "OK";
      },
      headers ? { },
    }:
    let
      default_headers = {
        Content-Type = "text/html";
        Server = "nix";
        Cache-Control = "public, max-age=3600";
        # TODO Currently keeping a connection alive is not supported, so we need to close every
        # message. Ideally, we should allow keepalive, but this would require implementing session
        # tracking.
        Connect = "Close";
      };
      headers_text = join "\n" (
        mapAttrsToList (name: value: "${name}: ${value}") (default_headers // headers)
      );
    in
    {
      response = ''
        ${protocol} ${toString status.code} ${status.reason}
        ${headers_text}

        ${body}'';
    };

  # Returns a derivation containing the response message as the file "response".
  mkReply =
    with builtins;
    reply:
    pkgs.stdenv.mkDerivation {
      name = "http-reply";
      src = pkgs.emptyDirectory;
      dontBuild = true;
      dontFixup = true;
      outputs = [
        "out"
      ];
      installPhase = ''
        runHook preInstall
        mkdir -p $out

        ln -s ${toFile "response" reply.response} $out/response

        runHook postInstall
      '';

    };
  errorReply =
    code: reason:
    mkReply (buildReply {
      status = {
        inherit code;
        inherit reason;

      };
    });
}

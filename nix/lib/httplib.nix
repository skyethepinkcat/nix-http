{
  pkgs ? import <nixpkgs> { },
  helpers ? import ./helpers.nix { inherit pkgs; },
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

  #
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

  commaSeperatedToList =
    e:
    assert (isString e);
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
      headers ? {
        Content-Type = "text/html";
        Server = "nix";
        Cache-Control = "public, max-age=3600";
      },
    }:
    let
      headers_text = join "\n" (mapAttrsToList (name: value: "${name}: ${value}") headers);
    in
    {
      response = ''
        ${protocol} ${toString status.code} ${status.reason}
        ${headers_text}

        ${body}
      '';
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
    mkReply buildReply {
      status = {
        inherit code;
        inherit reason;

      };
    };
}

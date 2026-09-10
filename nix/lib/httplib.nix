{
  pkgs ? import <nixpkgs> { },
}:
with builtins;
with pkgs.lib;
rec {
  # Contains various regex expressions that might be too complicated to inline.
  # None of these include capture groups, as they're intended to be used in larger regex
  # expressions.
  regex = {
    # Matches a token in HTTP.
    token = "[[:alnum:]!#$%&'*+.^_`|~-]+";
  };

  /*
    This function returns a copy of string with backslashes escaped.

    # Type

    ```
    handleBackslash :: String -> String
    ```

    # Arguments
    str
    : The string to be parsed.
  */
  handleBackslash = str: join "" (flatten (split ''\\(.)'' str));

  /*
    This function returns a copy of the contents of a double quoted string. Backslashes are correctly
    handled.

    # Type

    ```
    readQuote :: String -> String
    ```

    # Arguments
    str
    : The string to be parsed.
  */
  readQuote = str: handleBackslash (elemAt (match ''"(([^"]|\\")*)"'' str) 0);

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
    comma_seperated:
    assert (isString comma_seperated);
    filter isString (split ",[[:space:]]?");

  buildReply =
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
        content-type = "text/html";
        server = "nix";
        cache-control = "public, max-age=3600";
        # TODO Currently keeping a connection alive is not supported, so we need to close every
        # message. Ideally, we should allow keepalive, but this would require implementing session
        # tracking.
        connect = "Close";
      };
      combined_headers = concatMapAttrs (name: value: { ${toLower name} = value; }) (
        default_headers // headers
      );
      headers_text = join "\n" (mapAttrsToList (name: value: "${name}: ${value}") combined_headers);
    in
    # Its not possible to get the current time in a nix evaluation (and you shouldn't do it in a
    # nix derivation). As such, we should be considered a server without a clock, and so we cannot
    # respond with a date header.
    assert !hasAttr "date" combined_headers;
    {
      response = ''
        ${protocol} ${toString status.code} ${status.reason}
        ${headers_text}

        ${body}'';
    };

  # Returns a derivation containing the response message as the file "response".
  mkReply =
    reply:
    (pkgs.stdenv.mkDerivation {
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

    });
  errorReply =
    code: reason:
    mkReply (buildReply {
      status = {
        inherit code;
        inherit reason;
      };
    });
  replyWith = file: {
    status = {
      code = 200;
      reason = "OK";
    };

  } ;
}

# Request_path is outside of the attrset argument to avoid
{
  pkgs ? import <nixpkgs> { },
  http ? import ./lib/httplib.nix { inherit pkgs; },
  request_path,
}:
with pkgs.lib;
with builtins;
let
  dropFirstCharacter = string: (substring 1 (-1) string);

  message_text = readFile request_path;

  message_split = splitString "\n" message_text;
  body_start_index = lists.findFirstIndex (i: i == "\n" || i == "\r" || i == "") null message_split;
  headers_text = filter (e: e != "" && e != "\r" && e != "\n") (
    if body_start_index != null then
      lists.drop 1 (lists.take body_start_index message_split)
    else
      lists.drop 1 message_split
  );

  # Parses a path string (the second portion of the request) into a path attrset.
  #
  parseTarget =
    path_string:
    let
      # Here we create a 3 element array with the first being the absolute path, the second being
      # queries (prefixed with ?) and the third being the fragment (prefixed with #).
      # If the queries or fragment don't exist, they will instead be null.
      path_components = match ''^([[:alnum:]_\-./]+)(\?[[:alnum:]_\-.\/]+)?(#[[:alnum:]\\-.\\/]+)?$'' path_string;
    in
    {
      absolutePath = elemAt path_components 0;
      queries =
        let
          component = elemAt path_components 1;
        in
        http.orNull (component != null) (splitString "&" dropFirstCharacter component);
      fragment =
        let
          component = elemAt path_components 2;
        in
        http.unlessNull component (dropFirstCharacter component);

    };

  attrNameHasTrailingWhiteSpace =
    attr: any (a: !isNull (match "[[:space:]]" (last (stringToCharacters a)))) (attrNames attr);

  request_split = splitString " " (elemAt message_split 0);

  target = parseTarget (elemAt request_split 1);

  message = {
    inherit (target) queries fragment;

    path = target.absolutePath;
    type = elemAt request_split 0;
    protocol = elemAt (splitString " " (elemAt message_split 0)) 2;

    # TODO RFC 9112: HTTP/1.1 Section 5.2 requires that we handle obselete line folding. This
    # shouldn't be *too* bad.
    headers = listToAttrs (
      map (
        header_text:
        let
          invalid_characters = [
            "\n" # LF
            "\r" # CR
            "�" # NUL, I don't think there's any nice way to represent the null character, so I had to resort to this.
          ];

          # We use map here to make sure each character becomes a space
          replacements = map (_: " ") invalid_characters;
          header_split = match "^([[:alnum:]!#$%&'*+\-.^_`|~]+): ?(.*)$" header_text;
          header_name = elemAt header_split 0;

          header_value = replaceStrings invalid_characters replacements (elemAt header_split 1);
        in
        {
          # According to RFC 9110: HTTP section 5.1, headers are case-insensitive, so we'll downcase
          # them here. From here on, all header names should be assumed to be lowercase.
          name = toLower header_name;
          value = header_value;
        }
      ) headers_text
    );
    body =
      if body_start_index == null then null else (join "\n" (lists.drop body_start_index message_split));
  };
  route = import ./route.nix { inherit pkgs http; };

  reply = route message;

in
if
  length request_split != 3
  || (!hasAttr "host" message.headers)
  || (attrNameHasTrailingWhiteSpace message.headers)
then
  http.errorReply 400 "Bad Request"
else

/*
  TODO Currently we don't handle chunked or compressed encoding. Compressed encoding isn't a huge
      deal, but lacking chunked encoding support unfortunately makes this server non-compliant
      according to RFC 9112: HTTP/1.1
      https://www.rfc-editor.org/info/rfc9112/#field.transfer-encoding

  The issue is that we can't read from a socket in a Nix evaluation, so we have to parse the TCP
  packets one by one, and each packet can get exactly one response. There's two work arounds I can
  see:

  1. Allow the TCP server wrapper to evaluate chunked encodings and relay the proper packets
  2. Output a "continue" derivation to indicate to the wrapper we aren't done, and to read from the
     TCP socket again and append it to the current request.
  3. Just use the HTTP/1.0 standard.
  4. I'm overthinking this

  I'm realizing number 4 might be the key here. I don't think chunked encoding gets sent across
  multiple HTTP requests, although I could be wrong.

  Compressed encoding is much less important since its not required by the standard, but we could
  support it by just making a derivation that decompresses the content. Alternatively, if someone
  really hates themselves they could implement the gzip algorithm in pure nix, which would be *really*
  funny.

  Anyway, for now we'll just return 501 for any request with a stated transfer-encoding.
*/

if hasAttr "transfer-encoding" message.headers then

  http.errorReply 501 "Not Implemented"
else
  http.mkReply reply

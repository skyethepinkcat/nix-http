The worst thing I've ever conceptualized

This is a "pure" nix http server. A small ruby script is needed to handle TCP, but parsing the HTTP, routing, and responses are handled with nix evalutaion. The script reads the derivation output and sends it back over TCP as a response.

TODO:
- NOSQL is just JSON anyway, right? we can handle state "easily" by having an additional JSON input and JSON output
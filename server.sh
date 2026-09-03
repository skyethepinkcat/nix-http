#!/usr/bin/bash
set -e

listener="$(mktemp -u)"
mkfifo "$listener"

do_reply() {
  dir=$(mktemp -d)
  cp -r nix/* $dir
  pushd $dir
  tee request.txt
  nix-build default.nix
  cat result > $listener
  popd
}

echo "Listening on $listener"
while true; do
  cat $listener | nc -lN 3000 | do_reply "$(pwd)"

done

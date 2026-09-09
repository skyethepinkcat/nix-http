#!/usr/bin/env ruby
# frozen_string_literal: true

PORT = 3000
BUILD_PATH = ENV.fetch('NIX_HTTP_BUILD_PATH', Dir.pwd)
DEBUG = ENV.fetch('DEBUG', false)

require 'tempfile'
require 'tmpdir'
require 'socket'
require 'fileutils'

# server = TCPServer.new 3000 # Server bind to port 2000
# Sequential echo server.
# It services only one client at a time.
warn "Starting tcp server on #{PORT}"
server = TCPServer.new(3000)
loop do
  out = ''
  client = server.accept
  req = client.recvmsg[0]
  rand 1..100_000_000
  warn req if DEBUG

  Tempfile.create do |f|
    f.puts(req)
    f.rewind
    path = `nix-build #{__dir__}/nix/default.nix --arg request_path "#{f.path}" --no-out-link --show-trace`.chomp
    out = File.read("#{path}/response")
  end

  client.puts out
  client.close
end

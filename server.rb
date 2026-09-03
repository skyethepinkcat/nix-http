#!/usr/bin/env ruby
# frozen_string_literal: true

PORT = 3000
BUILD_PATH = ENV.fetch('NIX_HTTP_BUILD_PATH', Dir.pwd)

require 'tempfile'
require 'tmpdir'
require 'socket'
require 'fileutils'

# server = TCPServer.new 3000 # Server bind to port 2000
# Sequential echo server.
# It services only one client at a time.
warn "Starting tcp server on #{PORT}"
Socket.tcp_server_loop(PORT) do |sock, _client_addrinfo|
  current = Dir.pwd
  out = nil
  req = sock.gets

  begin
    Dir.mktmpdir do |dir|
      `cp -r #{BUILD_PATH}/nix/*.nix #{dir}`
      Dir.chdir(dir)
      File.write('request.txt', req)
      puts `nix-build default.nix`
      out = File.read('result')
      Dir.chdir(current)
    end
    sock.puts out
  ensure
    sock.close
    Dir.chdir(current)
  end
end

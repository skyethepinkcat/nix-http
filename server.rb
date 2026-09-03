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
Socket.tcp_server_loop(3000) do |sock, _client_addrinfo|
  warn 'Waiting for new connection...'
  current = Dir.pwd
  out = nil
  req = sock.gets

  begin
    Dir.mktmpdir do |dir|
      puts BUILD_PATH
      `cp -r #{BUILD_PATH}/nix/*.nix #{dir}`
      Dir.chdir(dir)
      File.write('request.txt', req)
      `nix-build default.nix`
      out = File.read('result')
      Dir.chdir(current)
    end
    sock.puts out
  ensure
    sock.close
    Dir.chdir(current)
  end
end

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
  client = server.accept
  current = Dir.pwd
  out = nil
  req = client.recvmsg[0]
  warn req if DEBUG

  begin
    Dir.mktmpdir do |dir|
      `cp -r #{BUILD_PATH}/nix/*.nix #{dir}`
      Dir.chdir(dir)
      File.write('request.http', req)
      puts `nix-build default.nix --show-trace`
      out = File.read('result')
      Dir.chdir(current)
    end
    client.puts out
  ensure
    client.close
    Dir.chdir(current)
  end
end

#!/usr/bin/env ruby

require 'mill'

server = Mill::Server.new(
  root: ENV['INTERPOSE_ROOT'],
  use_x_sendfile: true,
  multihosting: true)
server.run(server: :fastcgi, environment: 'deployment')
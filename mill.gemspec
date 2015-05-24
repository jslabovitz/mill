#encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'mill/version'

Gem::Specification.new do |s|
  s.name          = 'mill'
  s.version       = Mill::VERSION
  s.summary       = 'A simple but useful static site generator.'
  s.author        = 'John Labovitz'
  s.email         = 'johnl@johnlabovitz.com'
  s.description   = %q{
    Mill provides a simple but useful static site generator.
  }
  s.homepage      = 'http://github.com/jslabovitz/mill'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_path  = 'lib'

  s.add_dependency 'addressable'
  s.add_dependency 'image_size'
  s.add_dependency 'kramdown'
  s.add_dependency 'mime-types'
  s.add_dependency 'nokogiri'
  s.add_dependency 'path'
  s.add_dependency 'RedCloth'
  s.add_dependency 'rubypants'
  s.add_dependency 'simple-server'
  s.add_dependency 'term-ansicolor'
  s.add_dependency 'tidy_ffi'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
end
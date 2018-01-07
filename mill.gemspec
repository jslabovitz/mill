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
  s.licenses      = %w{MIT}
  s.homepage      = 'http://github.com/jslabovitz/mill'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_path  = 'lib'

  s.add_dependency 'addressable', '~> 2.5'
  s.add_dependency 'image_size', '~> 1.5'
  s.add_dependency 'kramdown', '~> 1.16'
  s.add_dependency 'mime-types', '~> 3.1'
  s.add_dependency 'nokogiri', '~> 1.8'
  s.add_dependency 'path', '~> 2.0'
  s.add_dependency 'RedCloth', '~> 4.3'
  s.add_dependency 'rubypants', '~> 0.6'
  s.add_dependency 'sass', '~> 3.5'
  s.add_dependency 'web-checker', '~> 0.1'
end
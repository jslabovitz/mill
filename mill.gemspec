#encoding: utf-8

require_relative 'lib/mill/version'

Gem::Specification.new do |s|
  s.name          = 'mill'
  s.version       = Mill::VERSION
  s.summary       = 'A simple but useful static site generator.'
  s.author        = 'John Labovitz'
  s.email         = 'johnl@johnlabovitz.com'
  s.description   = %q{
    Mill provides a simple but useful static site generator.
  }
  s.license       = 'MIT'
  s.homepage      = 'http://github.com/jslabovitz/mill'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_path  = 'lib'

  s.add_dependency 'addressable', '~> 2.7'
  s.add_dependency 'image_size', '~> 2.0'
  s.add_dependency 'kramdown', '~> 2.1'
  s.add_dependency 'mime-types', '~> 3.3'
  s.add_dependency 'nokogiri', '~> 1.10'
  s.add_dependency 'path', '~> 2.0'
  s.add_dependency 'RedCloth', '~> 4.3'
  s.add_dependency 'rubypants', '~> 0.7'
  s.add_dependency 'sassc', '~> 2.2'
  s.add_dependency 'web-checker', '~> 0.4'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rubygems-tasks', '~> 0.2'
end
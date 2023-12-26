Gem::Specification.new do |s|
  s.name          = 'mill'
  s.version       = '0.17'
  s.summary       = 'A simple but useful static site generator.'
  s.author        = 'John Labovitz'
  s.email         = 'johnl@johnlabovitz.com'
  s.description   = %q{
    Mill provides a simple but useful static site generator.
  }
  s.license       = 'MIT'
  s.homepage      = 'https://github.com/jslabovitz/mill'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_path  = 'lib'

  s.add_dependency 'addressable', '~> 2.8'
  s.add_dependency 'hashstruct', '~> 1.5'
  s.add_dependency 'http', '~> 5.1'
  s.add_dependency 'image_size', '~> 3.3'
  s.add_dependency 'kramdown', '~> 2.4'
  s.add_dependency 'mime-types', '~> 3.5'
  s.add_dependency 'nokogiri', '~> 1.15'
  s.add_dependency 'path', '~> 2.1'
  s.add_dependency 'RedCloth', '~> 4.3'
  s.add_dependency 'rubypants', '~> 0.7'
  s.add_dependency 'rubytree', '~> 2.0'
  s.add_dependency 'sassc', '~> 2.4'
  s.add_dependency 'set_params', '~> 0.2'
  s.add_dependency 'simple-command', '~> 0.4'
  s.add_dependency 'simple-config', '~> 0.1'
  s.add_dependency 'simple-builder', '~> 0.3'
  s.add_dependency 'simple-printer', '~> 0.3'

  s.add_development_dependency 'bundler', '~> 2.5'
  s.add_development_dependency 'minitest', '~> 5.20'
  s.add_development_dependency 'minitest-power_assert', '~> 0.3'
  s.add_development_dependency 'rake', '~> 13.1'
end
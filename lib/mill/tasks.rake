$LOAD_PATH.unshift 'lib'

desc 'Clean site directories.'
task :clean do
  $site.clean
end

desc 'Load site.'
task :load => :clean do
  $site.load
end

desc 'Build site.'
task :build => :load do
  $site.build
end

desc 'Check for syntax, links, etc.'
task :check => :build do
  $site.check
end

desc 'Publish site (final).'
task :publish => :check do
  $site.publish(:final)
end

desc 'Publish site (beta).'
task 'publish:beta' => :check do
  $site.publish(:beta)
end

desc 'Run a test server.'
task :server => :check do
  $site.server
end
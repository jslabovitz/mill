$LOAD_PATH.unshift 'lib'

desc 'Clean site directories.'
task :clean do
  $mill.clean
end

desc 'Load site.'
task :load => :clean do
  $mill.load
end

desc 'Build site.'
task :build => :load do
  $mill.build
end

desc 'Publish site (final).'
task :publish => :build do
  $mill.publish(:final)
end

desc 'Publish site (beta).'
task 'publish:beta' => :build do
  $mill.publish(:beta)
end

desc 'Run a test server.'
task :server => :build do
  $mill.server
end

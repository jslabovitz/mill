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
task :publish do
  $mill.publish(:final)
end

desc 'Publish site (beta).'
task 'publish:beta' do
  $mill.publish(:beta)
end

desc 'Run a test server.'
task :server do
  $mill.server
end

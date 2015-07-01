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

desc 'Publish site.'
task :publish do
  $mill.publish
end

desc 'Run a test server.'
task :server do
  $mill.server
end
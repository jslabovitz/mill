$LOAD_PATH.unshift 'lib'

desc 'Build.'
task :build do
  $mill.build
end

desc 'Clean.'
task :clean do
  $mill.clean
end

desc 'Run web server.'
task :server => 'build' do
  $mill.server
end
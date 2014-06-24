$LOAD_PATH.unshift 'lib'

desc 'Import files into resources.'
task :import do
  $mill.import
end

desc 'Build resources into site.'
task :build do
  $mill.build
end

desc 'Clean resources and site directories.'
task :clean do
  $mill.clean
end

desc 'Run web server on site directory.'
task :server => 'build' do
  $mill.server
end
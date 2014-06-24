$LOAD_PATH.unshift 'lib'

desc 'Clean resources and site directories.'
task :clean do
  $mill.clean
end

desc 'Import files into resources.'
task :import => :clean do
  $mill.import
end

desc 'Build resources into site.'
task :build => :import do
  $mill.build
end

desc 'Run web server on site directory.'
task :server => :build do
  $mill.server
end
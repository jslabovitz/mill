$LOAD_PATH.unshift 'lib'

task :clean do
  $site.clean
end

task :build do
  files = ARGV
  files.shift
  $site.build(*files)
end

task :validate do
  $site.validate
end

task :server => [:build, :validate] do
  $site.server
end

task :publish => [:clean, :build, :validate] do
  #FIXME
end
$LOAD_PATH.unshift 'lib'

desc 'Clean site directories.'
task :clean do
  $site.clean
end

desc 'Make site.'
task :make => :clean do
  $site.make
end

desc 'Check for syntax, links, etc.'
task :check => :make do
  $site.check
end
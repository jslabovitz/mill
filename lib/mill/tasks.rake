$LOAD_PATH.unshift 'lib'

desc 'Clean site directories.'
task :clean do
  $site.clean
end

desc 'Build site.'
task :build => :clean do
  $site.import
  $site.load
  $site.build
  $site.save
end

desc 'Check for syntax, links, etc.'
task :check => :build do
  $site.check
end

desc 'Publish site (final).'
task :publish => :check do
  $site.publish_final
end

desc 'Publish site (beta).'
task 'publish:beta' => :check do
  $site.publish_beta
end

desc 'Run a test server.'
task :server => :check do
  $site.server
end
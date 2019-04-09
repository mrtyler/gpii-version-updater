task :default => [:test]

desc "Run tests"
task :test do
  sh "bundle exec rspec"
end

desc "Sync images"
task :sync do
  sh "bundle exec ruby -e 'require \"./sync_images.rb\"; main()'"
end


# vim: set et ts=2 sw=2:

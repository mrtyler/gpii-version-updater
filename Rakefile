BUNDLE_PATH = "vendor/bundle"

task :default => [:test]

desc "Install dependencies"
task :install do
  sh "bundle install --path #{BUNDLE_PATH}"
end

desc "Uninstall dependencies"
task :uninstall do
  sh "rm -rf #{BUNDLE_PATH}"
end

desc "Destroy volume containing docker image cache"
task :clean_cache do
  sh "docker volume rm -f version-updater-docker-cache"
end

desc "Run tests"
task :test do
  sh "bundle exec rspec"
end

desc "Sync images -- positional args are config_file, desired_components, push_to_gcr, registry_url"
task :sync, [:config_file, :desired_components, :push_to_gcr, :registry_url] do |taskname, args|
  sh "bundle exec ruby -e '\
    require \"./sync_images.rb\";
    main(
      config_file=\"#{args[:config_file]}\",
      desired_components=\"#{args[:desired_components]}\",
      push_to_gcr=\"#{args[:push_to_gcr]}\",
      registry_url=\"#{args[:registry_url]}\",
    ); \
  '"
end


# vim: set et ts=2 sw=2:

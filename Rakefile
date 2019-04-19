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

desc "Sync images -- positional args are config_file, registry_url, push_to_gcr, desired_components"
task :sync, [:config_file, :registry_url, :push_to_gcr, :desired_components] do |taskname, args|
  sh "bundle exec ruby -e '\
    require \"./sync_images.rb\";
    main(
      config_file=\"#{args[:config_file]}\",
      registry_url=\"#{args[:registry_url]}\",
      push_to_gcr=\"#{args[:push_to_gcr]}\",
      desired_components=\"#{args[:desired_components]}\",
    ); \
  '"
end


# vim: set et ts=2 sw=2:

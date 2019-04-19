task :default => [:test]

desc "Run tests"
task :test do
  sh "bundle exec rspec"
end

desc "Sync images"
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

desc "Destroy volume containing docker image cache"
task :clean do
  sh "docker volume rm -f version-updater-docker-cache"
end


# vim: set et ts=2 sw=2:

task :default => [:test]

desc "Run tests"
task :test do
  sh "bundle exec rspec"
end

desc "Sync images"
task :sync, [:config_file] do |taskname, args|
  main_cmd = "main()"
  if args[:config_file]
    main_cmd = "main(config_file=\"#{args[:config_file]}\")"
  end
  sh "bundle exec ruby -e 'require \"./sync_images.rb\"; #{main_cmd}'"
end


# vim: set et ts=2 sw=2:

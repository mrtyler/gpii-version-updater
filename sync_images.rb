#!/usr/bin/env ruby


require "docker-api"
require "yaml"

class SyncImages

  CONFIG_FILE = "../gpii-infra/shared/versions.yml"
  CREDS_FILE = "./creds.json"
  DESIRED_COMPONENTS = nil  # "nil" means all components
  PUSH_TO_GCR = true
  REGISTRY_URL = "gcr.io/gpii-common-prd"

  def self.load_config(config_file)
    return YAML.load(File.read(config_file))
  end

  def self.login()
    puts "Logging in with credentials from #{SyncImages::CREDS_FILE}..."
    creds = File.read(SyncImages::CREDS_FILE)
    Docker.authenticate!(
      "username" => "_json_key",
      "password" => creds,
      "serveraddress" => "https://gcr.io",
    )
  end

  def self.process_config(config, registry_url, push_to_gcr, desired_components)
    desired_components_table = {}  # Empty hash means "all components"
    unless desired_components.nil?
      desired_components.split(",").each do |dc|
        desired_components_table[dc] = true
      end
    end

    config.keys.sort.each do |component|
      # Ruby style suggests "unless X or Y", but I find that more confusing than
      # "if not X and not Y".
      #
      # Anyway, skip this component if desired_components were specified AND
      # this component is not in the set of desired_components.
      next if (not desired_components_table.empty? and not desired_components_table.has_key?(component))
      image_name = config[component]["upstream_image"]
      (new_image_name, sha, tag) = self.process_image(component, image_name, registry_url, push_to_gcr)
      config[component]["generated"] = {
        "image" => new_image_name,
        "sha" => sha,
        "tag" => tag,
      }
    end
    return config
  end

  def self.process_image(component, image_name, registry_url, push_to_gcr)
    puts "Processing image for #{component}..."
    image = self.pull_image(image_name)
    if push_to_gcr
      new_image_name = self.retag_image(image, registry_url, image_name)
      new_image_name_without_tag, tag = Docker::Util.parse_repo_tag(new_image_name)
      sha = self.get_sha_from_image(image, new_image_name_without_tag)
      self.push_image(image, new_image_name)
    else
      new_image_name = image_name
      new_image_name_without_tag, tag = Docker::Util.parse_repo_tag(new_image_name)
      sha = self.get_sha_from_image(image, new_image_name_without_tag)
    end
    puts "Done with #{component}."
    puts

    return [new_image_name_without_tag, sha, tag]
  end

  def self.pull_image(image_name)
    puts "Pulling #{image_name}..."
    image = Docker::Image.create({"fromImage" => image_name}, creds: {})
    return image
  end

  def self.get_sha_from_image(image, new_image_name_without_tag)
    sha = nil

    # First, try to find an image matching our re-tagged image name.
    image.info["RepoDigests"].each do |digest|
      if digest.start_with?(new_image_name_without_tag)
        sha = digest.split('@')[1]
        break
      end
    end

    # If that doesn't work (sometimes Docker doesn't have a RepoDigest for the
    # re-tagged image), try to return the first RepoDigest.
    unless sha
      begin
        image_with_sha = image.info["RepoDigests"][0]
        sha = image_with_sha.split('@')[1]
      rescue
        raise ArgumentError, "Could not find sha! image.info was #{image.info}"
      end
    end

    puts "Got image with sha #{sha}..."
    return sha
  end

  def self.retag_image(image, registry_url, image_name)
    new_image_name = "#{registry_url}/#{image_name}"
    puts "Retagging #{image_name} as #{new_image_name}..."
    image.tag("repo" => new_image_name)
    return new_image_name
  end

  def self.push_image(image, new_image_name)
    puts "Pushing #{new_image_name}..."
    # Docker.push collects output from the API call via 'response_block()', a
    # kind of callback function. Docker.push ignores errors and discards
    # output, though the output is available to a block passed to Docker.push.
    # Hence, we use a block to look for errors and explode if we find one.
    image.push(nil, repo_tag: new_image_name) do |output_line|
      puts "...output from push: #{output_line}"
      if output_line.include? '"error":'
        raise ArgumentError, "Found error message in output (see above)!"
      end
    end
  end

  def self.write_new_config(config_file, config)
    header = """# versions.yml
#
# This file is managed by https://github.com/gpii-ops/gpii-version-updater.
#
# See the README for details on how to modify which images are used or to add
# components.
"""
    File.open(config_file, "w") do |f|
      f.write(header)
      f.write(YAML.dump(config))
    end
  end

end


def main(config_file, registry_url, push_to_gcr, desired_components)
  if config_file.nil? or config_file.empty?
    config_file = SyncImages::CONFIG_FILE
  end
  if registry_url.nil? or registry_url.empty?
    registry_url = SyncImages::REGISTRY_URL
  end
  if push_to_gcr.nil? or push_to_gcr.empty?
    push_to_gcr = SyncImages::PUSH_TO_GCR
  end
  # Due to how we pass arguments through rake, 'false' ends up as a string.
  # Correct it into a boolean.
  push_to_gcr = false if push_to_gcr == "false"
  if desired_components.nil? or desired_components.empty?
    desired_components = SyncImages::DESIRED_COMPONENTS
  end
  config = SyncImages.load_config(config_file)
  SyncImages.login()
  SyncImages.process_config(config, registry_url, push_to_gcr, desired_components)
  SyncImages.write_new_config(config_file, config)
end


# vim: et ts=2 sw=2:

require "./sync_images.rb"

describe SyncImages do

  # It is not necessary or desirable to test File.read or YAML.load, but this
  # validates some plumbing.
  it "load_config returns parsed yaml" do
    fake_config_file = "path/to/versions.yml"
    fake_yaml = "foo: bar"
    allow(File).to receive(:read).with(fake_config_file).and_return(fake_yaml)

    expected = {"foo" => "bar"}
    actual = SyncImages.load_config(fake_config_file)
    expect(actual).to eq(expected)
  end

  it "process_config calls process_image on each image when desired_components is nil" do
    fake_config = {
      "dataloader" => {
        "upstream_image" => "gpii/universal:latest",
      },
      "flowmanager" => {
        "upstream_image" => "gpii/universal:latest",
      },
    }
    fake_registry_url = "gcr.fake/fake-project"
    fake_push_to_gcr = true
    fake_desired_components = nil

    allow(SyncImages).to receive(:process_image)

    SyncImages.process_config(fake_config, fake_registry_url, fake_push_to_gcr, fake_desired_components)

    expect(SyncImages).to have_received(:process_image).with("dataloader", "gpii/universal:latest", fake_registry_url, fake_push_to_gcr)
    expect(SyncImages).to have_received(:process_image).with("flowmanager", "gpii/universal:latest", fake_registry_url, fake_push_to_gcr)
  end

  it "process_config calls process_image on some images when desired_components is specified" do
    fake_config = {
      "dataloader" => {
        "upstream_image" => "gpii/universal:latest",
      },
      "flowmanager" => {
        "upstream_image" => "gpii/universal:latest",
      },
      "something_else" => {
        "upstream_image" => "gpii/something_else:1.0.0",
      },
    }
    fake_registry_url = "gcr.fake/fake-project"
    fake_push_to_gcr = true
    fake_desired_components = "flowmanager|something_else"

    allow(SyncImages).to receive(:process_image)

    SyncImages.process_config(fake_config, fake_registry_url, fake_push_to_gcr, fake_desired_components)

    expect(SyncImages).not_to have_received(:process_image).with("dataloader", "gpii/universal:latest", fake_registry_url, fake_push_to_gcr)
    expect(SyncImages).to have_received(:process_image).with("flowmanager", "gpii/universal:latest", fake_registry_url, fake_push_to_gcr)
    expect(SyncImages).to have_received(:process_image).with("something_else", "gpii/something_else:1.0.0", fake_registry_url, fake_push_to_gcr)
  end

  it "process_config generates new config" do
    # Keys are out of lexical order to test that they get sorted at the end
    # (and thus get the shas in the right order).
    fake_config = {
      "flowmanager" => {
        "upstream_image" => "gpii/universal:latest",
      },
      "dataloader" => {
        "upstream_image" => "gpii/universal:latest",
      },
    }
    fake_registry_url = "gcr.fake/fake-project"
    fake_push_to_gcr = true
    fake_desired_components = nil
    fake_new_image_name = "fake-registry/gpii/universal"
    fake_sha_1 = "sha256:c0ffee"
    fake_sha_2 = "sha256:50da"
    fake_tag = "latest"
    expected_config = {
      "dataloader" => {
        "upstream_image" => "gpii/universal:latest",
        "generated" => {
          "image" => fake_new_image_name,
          "sha" => fake_sha_1,
          "tag" => fake_tag,
        },
      },
      "flowmanager" => {
        "upstream_image" => "gpii/universal:latest",
        "generated" => {
          "image" => fake_new_image_name,
          "sha" => fake_sha_2,
          "tag" => fake_tag,
        },
      },
    }

    allow(SyncImages).to receive(:process_image).and_return(
      [fake_new_image_name, fake_sha_1, fake_tag],
      [fake_new_image_name, fake_sha_2, fake_tag],
    )
    allow(SyncImages).to receive(:write_new_config)

    actual = SyncImages.process_config(fake_config, fake_registry_url, fake_push_to_gcr, fake_desired_components)
    expect(actual).to eq(expected_config)
  end

  it "process_image calls all helpers on image when push_to_gcr is true" do
    fake_component = "fake_component"
    fake_image = "fake Docker::Image object"
    fake_image_name = "fake_org/fake_img:fake_tag"
    fake_image_name_without_tag = "fake_org/fake_img"
    fake_registry_url = "gcr.fake/fake-project"
    fake_new_image_name = "#{SyncImages::REGISTRY_URL}/#{fake_image_name}"
    fake_new_image_name_without_tag = "#{SyncImages::REGISTRY_URL}/#{fake_image_name_without_tag}"
    fake_sha = "sha256:c0ffee"
    fake_tag = "fake_tag"
    fake_push_to_gcr = true

    allow(SyncImages).to receive(:pull_image).and_return(fake_image)
    allow(SyncImages).to receive(:retag_image).and_return(fake_new_image_name)
    allow(SyncImages).to receive(:get_sha_from_image).and_return(fake_sha)
    allow(SyncImages).to receive(:push_image)

    actual = SyncImages.process_image(fake_component, fake_image_name, fake_registry_url, fake_push_to_gcr)

    expect(SyncImages).to have_received(:pull_image).with(fake_image_name)
    expect(SyncImages).to have_received(:retag_image).with(fake_image, fake_registry_url, fake_image_name)
    expect(SyncImages).to have_received(:get_sha_from_image).with(fake_image, fake_new_image_name_without_tag)
    expect(SyncImages).to have_received(:push_image).with(fake_image, fake_new_image_name)
    expect(actual).to eq([fake_new_image_name_without_tag, fake_sha, fake_tag])
  end

  it "process_image calls some helpers on image when push_to_gcr is false" do
    fake_component = "fake_component"
    fake_image = "fake Docker::Image object"
    fake_image_name = "fake_org/fake_img:fake_tag"
    fake_registry_url = "gcr.fake/fake-project"
    fake_new_image_name_without_tag = "fake_org/fake_img"
    fake_sha = "sha256:c0ffee"
    fake_tag = "fake_tag"
    fake_push_to_gcr = false

    allow(SyncImages).to receive(:pull_image).and_return(fake_image)
    allow(SyncImages).to receive(:retag_image)
    allow(SyncImages).to receive(:get_sha_from_image).and_return(fake_sha)
    allow(SyncImages).to receive(:push_image)

    actual = SyncImages.process_image(fake_component, fake_image_name, fake_registry_url, fake_push_to_gcr)

    expect(SyncImages).to have_received(:pull_image).with(fake_image_name)
    expect(SyncImages).not_to have_received(:retag_image)
    expect(SyncImages).to have_received(:get_sha_from_image).with(fake_image, fake_new_image_name_without_tag)
    expect(SyncImages).not_to have_received(:push_image)
    expect(actual).to eq([fake_new_image_name_without_tag, fake_sha, fake_tag])
  end

  it "pull_image pulls image" do
    fake_image_name = "fake_org/fake_img:fake_tag"
    fake_image = "fake docker image object"
    allow(Docker::Image).to receive(:create).and_return(fake_image)
    actual = SyncImages.pull_image(fake_image_name)
    expect(actual).to eq(fake_image)
    expect(Docker::Image).to have_received(:create).with({"fromImage" => fake_image_name}, creds: {})
  end

  it "get_sha_from_image gets sha that starts with new_image_name" do
    fake_image = double(Docker::Image)
    fake_new_image_name_without_tag = "fake_org/fake_img"
    fake_sha = "sha256:c0ffee"
    allow(fake_image).to receive(:info).and_return({
      "RepoDigests" => [
        "another_org/another_img@sha256:50da",
        # Target is not first so that we avoid a false negative when
        # get_sha_from_image falls back to "return first RepoDigest" behavior.
        "#{fake_new_image_name_without_tag}@#{fake_sha}",
      ]
    })
    actual = SyncImages.get_sha_from_image(fake_image, fake_new_image_name_without_tag)
    expect(actual).to eq(fake_sha)
  end

  it "get_sha_from_image gets first sha if no digest starts with new_image_name" do
    fake_image = double(Docker::Image)
    fake_new_image_name_without_tag = "this image name is not in RepoDigests"
    fake_sha = "sha256:c0ffee"
    allow(fake_image).to receive(:info).and_return({
      "RepoDigests" => [
        "fake_org/fake_img@#{fake_sha}",
        "another_org/another_img@sha256:50da",
      ]
    })
    actual = SyncImages.get_sha_from_image(fake_image, fake_new_image_name_without_tag)
    expect(actual).to eq(fake_sha)
  end

  it "get_sha_from_image explodes when RepoDigests is empty" do
    fake_image = double(Docker::Image)
    fake_new_image_name_without_tag = "fake_org/fake_img"
    allow(fake_image).to receive(:info).and_return({
      "RepoDigests" => [],
    })
    expect { SyncImages.get_sha_from_image(fake_image, fake_new_image_name_without_tag) }.to raise_error(ArgumentError, /Could not find sha!/)
  end

  it "retag_image retags iamge" do
    fake_image = double(Docker::Image)
    fake_registry_url = "gcr.fake/fake-project"
    fake_image_name = "fake_org/fake_img:fake_tag"
    fake_new_image_name = "#{fake_registry_url}/#{fake_image_name}"

    allow(fake_image).to receive(:tag)
    actual = SyncImages.retag_image(fake_image, fake_registry_url, fake_image_name)
    expect(fake_image).to have_received(:tag).with({"repo" => fake_new_image_name})
    expect(actual).to eq(fake_new_image_name)
  end

  it "push_image pushes image" do
    fake_image = double(Docker::Image)
    fake_new_image_name = "fake_registry/fake_org/fake_img:fake_tag"
    allow(fake_image).to receive(:push)
    SyncImages.push_image(fake_image, fake_new_image_name)
    expect(fake_image).to have_received(:push).with(nil, "repo_tag": fake_new_image_name)
  end

  it "push_image explodes if push output contains error" do
    fake_image = double(Docker::Image)
    fake_new_image_name = "fake_registry/fake_org/fake_img:fake_tag"
    # Based on real output when I accidentally mismatched credentials and
    # registry.
    fake_output = [
      '{"status":"The push refers to repository [docker.io/library/fake_img]"}',
      '{"status":"Preparing","progressDetail":{},"id":"123456789abc"}',
      '{"errorDetail":{"message":"unauthorized: incorrect username or password"},"error":"unauthorized: incorrect username or password"}',
    ]
    allow(fake_image).to receive(:push).and_yield(fake_output[0]).and_yield(fake_output[1]).and_yield(fake_output[2])
    expect { SyncImages.push_image(fake_image, fake_new_image_name) }.to raise_error(ArgumentError, /Found error message in output/)
  end

  # It is not necessary or desirable to test File.write or YAML.dump, but this
  # validates some plumbing.
  it "write_new_config dumps and writes yaml" do
    fake_config_file = "./fake-versions.yml"
    fake_config = {
      "foo" => "bar",
    }
    buffer = StringIO.new()
    allow(File).to receive(:open).and_yield(buffer)
    SyncImages.write_new_config(fake_config_file, fake_config)
    # Look for static header
    expect(buffer.string.start_with?("# versions.yml")).to eq(true)
    # Look for value from fake_config
    expect(buffer.string.include?("foo: bar\n")).to eq(true)
  end

end


# vim: set et ts=2 sw=2:

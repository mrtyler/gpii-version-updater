# GPII Version Updater

This repo contains a Docker image for tracking components to be deployed to GPII infrastructure. It works as a bridge between the independent CI projects that build, test, and upload Docker images (e.g. [GPII universal](https://github.com/GPII/universal/)) and the [gpii-infra repo](https://github.com/gpii-ops/gpii-infra/), which manages the infrastructure for operating and deploying GPII components.

For more about the general CI/CD picture, see [Continuous Integration / Continuous Delivery in gpii-infra](https://github.com/gpii-ops/gpii-infra/blob/master/CI-CD.md).

This module contains:
* `Rakefile`, the primary entry point.
   * `rake test` to run unit tests
   * `rake sync` to run `sync_images.rb` (see below)
      * You can override some defaults: `rake sync"[./my_versions.yml, gcr.io/gpii2test-common-stg]"`
   * `rake clean` to destroy the Docker `/var/lib/docker` cache volume. The volume and cache will be re-created on the next run.
* `sync_images.rb`, which calculates the latest sha256 for each component, uploads the image to our production Google Container Registry, and writes `shared/versions.yml` in the [gpii-infra repo](https://github.com/gpii-ops/gpii-infra/).
* `sync_images_wrapper`, a script that runs `sync_images` in a loop, committing and pushing `shared/versions.yml` if it changes.
   * This requires commit and push privileges on `gpii-infra`. These privileges are provided via an [ssh key](https://github.com/gpii-ops/gpii-infra/blob/master/aws/README.md#configure-ssh) and some configuration of [Github](https://github.com/gpii-ops/gpii-infra/blob/master/CI-CD.md#configure-github).
* `Dockerfile`, to build a Docker image that runs `sync_images_wrapper`.
   * A container based on this Docker image is deployed to `i46` and managed by an [Ansible role](https://github.com/idi-ops/ansible-gpii-version-updater) and a [wrapper playbook](https://github.com/inclusive-design/ops/blob/master/ansible/config_host_gpii_version_updater.yml).

## Generating `shared/versions.yml` manually

`sync_images` can be useful for local GPII development. See [gpii-infra: I want to test my local changes to GPII components in my cluster](https://github.com/gpii-ops/gpii-infra/blob/master/gcp/README.md#i-want-to-test-my-local-changes-to-gpii-components-in-my-cluster).

## Adding or modifying a component

`sync_images` reads a specified `versions.yml` file.

Each top-level key is a `component`. The component's name is arbitrary, but should correlate with a gpii-infra module since gpii-infra will populate environment variables like `TF_VAR_<component_name>_(repository|tag|sha)` based on data under the component key in `versions.yml`.

`sync_images` pulls the image specified by the component's `upstream_image` key, optionally processes the image further (e.g. push it to GCR), then populates the component's `generated` key with caluclated values.

### To add a new component

1. Add a new top-level key, `my_component`.
   * Use `snake_case`, not `kebab-case`.
1. Add a key underneath `my_component` called `repository`. Its value is the upstream location of the image, e.g. `mrtyler/universal` or `couchdb`.
1. Add a key underneath `my_component` called `tag`. Its value is the tag on the upstream repository, e.g. `latest` or `2.3`.
1. `rake sync"[/path/to/gpii-infra/shared/versions.yml, UNUSED, false, my_component]"`
   * `desired_components` (the last argument) accepts multiple, pipe-separated values: `flowmanager|preferences|dataloader`
1. Review the changes made to `versions.yml` and commit.

### To modify a component

1. Find the component, e.g. `your_component`.
1. Modify `repository` and `tag`.
1. Ignore everything under `generated`; it will be re-generated.
1. `rake sync"[/path/to/gpii-infra/shared/versions.yml, UNUSED, false, your_component]"`
1. Review the changes made to `versions.yml` and commit.

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
* `update-version-wrapper`, a script that runs `sync_images` in a loop, committing and pushing `shared/versions.yml` if it changes.
   * This requires commit and push privileges on `gpii-infra`. These privileges are provided via an [ssh key](https://github.com/gpii-ops/gpii-infra/blob/master/aws/README.md#configure-ssh) and some configuration of [Github](https://github.com/gpii-ops/gpii-infra/blob/master/CI-CD.md#configure-github).
* `Dockerfile`, to build a Docker image that runs `update-version-wrapper`.
   * A container based on this Docker image is deployed to `i46` and managed by an [Ansible role](https://github.com/idi-ops/ansible-gpii-version-updater) and a [wrapper playbook](https://github.com/inclusive-design/ops/blob/master/ansible/config_host_gpii_version_updater.yml).

## Generating `shared/versions.yml` manually

`sync_images` can be useful for local GPII development. See [gpii-infra: I want to test my local changes to GPII components in my cluster](https://github.com/gpii-ops/gpii-infra/blob/master/gcp/README.md#i-want-to-test-my-local-changes-to-gpii-components-in-my-cluster).

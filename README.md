# GPII Version Updater

This repo contains a Docker image for tracking versions of GPII components to be deployed to GPII infrastructure. It works as a bridge between the independent CI projects that build, test, and upload Docker images for GPII components (e.g. [GPII universal](https://github.com/GPII/universal/)) and the [gpii-infra repo](https://github.com/gpii-ops/gpii-infra/), which manages the infrastructure for running and deploying GPII components.

For more about the general CI/CD picture, see [Continuous Integration / Continuous Delivery in gpii-infra](https://github.com/gpii-ops/gpii-infra/blob/master/CI-CD.md).

This module contains:
* `update-version`, which calculates the latest sha256 for each component and writes `version.yml` in the [gpii-infra repo](https://github.com/gpii-ops/gpii-infra/).
* `components.conf`, a list of GPII components and the Docker images and tags that run them. This file is consumed by `update-version`.
* `update-version-wrapper`, a script that runs `update-version` in a loop, committing and pushing `version.yml` if it changes.
   * This requires commit and push privileges on `gpii-infra`. These privileges are provided via an [ssh key](https://github.com/gpii-ops/gpii-infra/#configure-ssh) and some configuration of [Github](https://github.com/gpii-ops/gpii-infra/blob/master/CI-CD.md#configure-github) and [Gitlab](https://github.com/gpii-ops/gpii-infra/blob/master/CI-CD.md#configure-gitlab).
* `Dockerfile`, to build a Docker image that runs `update-version-wrapper`.
   * A container based on this Docker image is deployed to `i46` and managed by an [Ansible role](https://github.com/idi-ops/ansible-gpii-version-updater) and a [wrapper playbook](https://github.com/inclusive-design/ops/blob/master/ansible/config_host_gpii_version_updater.yml).

## Generating `version.yml` manually

`update-version` can be useful for local GPII development. See [gpii-infra: I want to test my local changes to GPII components in my cluster](https://github.com/gpii-ops/gpii-infra#i-want-to-test-my-local-changes-to-gpii-components-in-my-cluster).

# GPII Version Updater

This repo contains a Docker image for tracking versions of GPII components to be deployed to GPII infrastructure. It works as a bridge between the independent CI projects that build, test, and upload Docker images for GPII components (e.g. [GPII universal](https://github.com/GPII/universal/)) and the [gpii-terraform repo](https://github.com/gpii-ops/gpii-terraform/), which manages the infrastructure for running and deploying GPII components.

This module contains:
* `update-version`, which calculates the latest sha256 for each component and writes `version.yml` in the [gpii-terraform repo](https://github.com/gpii-ops/gpii-terraform/).
* `update-version-wrapper`, a script that runs `update-version` in a loop, committing and pushing `version.yml` if it changes.
* `Dockerfile`, to build a Docker image that runs `update-version-wrapper`.
   * A container based on this Docker image is deployed to `i46` and managed by [ansible](https://github.com/inclusive-design/ops).

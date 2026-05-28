# Rust Container Build CI Template

A GitLab CI template for building, tagging, pushing, signing and scanning
container images using Buildah, skopeo and Trivy.

## Usage

Include the template in your `.gitlab-ci.yml`.
Your project must define a `.template_vars` section with the `FLAVORS` matrix:

```yaml
.template_vars:
  FLAVORS:
    - alpine
    - trixie

include:
  - project: 'opentalk/ci/templates/rust-container-build'
    ref: v2
    file: '.gitlab-ci-template.yml'
    inputs:
      default_flavor: trixie
      harbor_namespace_suffix: controller
```

The template references `.template_vars.FLAVORS` as the parallel matrix for
every per-flavor job, so the section is required.

For a single-image build without flavors, use an empty string:

```yaml
.template_vars:
  FLAVORS:
    - ""
```

Each flavor requires a corresponding `Dockerfile-<flavor>` in the configured
dockerfile directory. When using an empty flavor, the template expects a plain
`Dockerfile`.

For scheduled container scanning, provide a `.trivyignore-<flavor>` file per
flavor (the prefix is configurable via `trivy_ignore_prefix`).

## Inputs

### `dockerfile_dir` (string, default `$CI_PROJECT_DIR`)

Directory containing the Dockerfile(s).

### `default_flavor` (string, default `trixie`)

Flavor used for untagged image aliases (e.g. `latest`, `vX.Y.Z`).

### `harbor_push_project` (string)

GitLab project path of the push-and-sign pipeline.

Default:
`opentalk/opentalk-devops/push-and-sign-images-for-the-opentalk-namespace`.

### `harbor_namespace_suffix` (string, required)

Namespace suffix used in Harbor.

### `additional_labels` (string, default `''`)

Additional labels for container scanning, usually the team label.

### `trivy_ignore_prefix` (string, default `.trivyignore-`)

Prefix of the per-flavor `.trivyignore` file (joined with `<flavor>`).

## Jobs

All jobs run in the `package` stage.

### `package:container-build-mr`

- **Trigger:** Merge request events, manual, allowed to fail.
- **Image:** `quay.io/buildah/stable:v1.43.0`
- **Image tag:**
  - With flavor: `$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG-$FLAVOR`
  - Without flavor: `$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG`

### `package:container-build`

- **Trigger:** Version tags (`v*.*.*`), default branch, or release branches
  (`release/vX.Y.x`).
- **Image:** `quay.io/buildah/stable:v1.43.0`
- **Image tag:** `$CI_REGISTRY_IMAGE:$FLAVOR-$CI_COMMIT_SHORT_SHA`

### `package:read-tags`

- **Trigger:** Version tags or default branch.
- Collects existing `vX.Y.Z` git tags (excluding the latest) and exposes them
  as the `TAGS` dotenv variable for downstream tagging.

### `package:container-create-and-push-tags`

- **Trigger:** Version tags, default branch or release branches.
- **Needs:** `package:container-build` and (optionally) `package:read-tags`.
- Uses the [`create-container-tags`](create-container-tags.sh) helper from the
  template's own image
  (`git.opentalk.dev:5050/opentalk/ci/templates/rust-container-build:v2`)
  to compute the set of tags to publish, then copies the freshly built image
  to each tag with `skopeo`. The resulting tag list per flavor is exported as
  `TAGS_<FLAVOR>` for the Harbor pipeline.

### `push-and-sign-images-to-harbor`

- **Trigger:** Version tags, default branch or release branches.
- **Needs:** `package:container-create-and-push-tags`.
- Triggers the downstream `harbor_push_project` pipeline with
  `PIPELINE_FULL_IMAGE_NAME`, `PIPELINE_NAMESPACE_SUFFIX` (from
  `harbor_namespace_suffix`) and `PIPELINE_TAGS_ENV_NAME=TAGS_<FLAVOR>`.

### `read-trivy-ignore-file`

- **Trigger:** Scheduled pipelines.
- Reads `$CI_PROJECT_DIR/<trivy_ignore_prefix><flavor>` and exports it as the
  `TRIVY_IGNORE_STR_<FLAVOR>` dotenv variable.

### `container-scanning`

- **Trigger:** Scheduled pipelines.
- **Needs:** `package:container-build`, `read-trivy-ignore-file`.
- Triggers `opentalk/opentalk-devops/scan-container` with the per-flavor image
  (`$CI_REGISTRY_IMAGE:dev-$FLAVOR`), forwarding `additional_labels` and the
  Trivy ignore string.

## Migrating from v1

v2 is a breaking change:

- `harbor_namespace_suffix` is a new required input.
- Bump the template `ref` to `v2`.

The `.template_vars.FLAVORS` contract is unchanged from v1.

## License

SPDX-License-Identifier: EUPL-1.2

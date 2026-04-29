# Rust Container Build CI Template

A GitLab CI template for building container images using Buildah.

## Usage

Include the template in your `.gitlab-ci.yml`:

```yaml
include:
  - project: 'opentalk/ci-templates/rust-container-build'
    ref: v1
    file: '.gitlab-ci-template.yml'
    inputs:
      dockerfile_dir: $CI_PROJECT_DIR  # optional, defaults to $CI_PROJECT_DIR
```

### Prerequisites

Your project must define a `.template_vars` section with the `FLAVORS` matrix:

```yaml
.template_vars:
  FLAVORS:
    - alpine
    - debian
    # add your flavors here
```

For single-image builds without flavors, use an empty string:

```yaml
.template_vars:
  FLAVORS:
    - ""
```

Each flavor requires a corresponding `Dockerfile-<flavor>` in the configured
dockerfile directory. When using an empty flavor, the template expects a plain
`Dockerfile`.

## Jobs

### `package:container-build-mr`

- **Trigger:** Merge request events (manual, allowed to fail)
- **Image tag:**
  - With flavor: `$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG-$FLAVOR`
  - Without flavor: `$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG`

### `package:container-build`

- **Trigger:** Version tags (`v*.*.*`) or commits to the default branch
- **Image tag:** `$CI_REGISTRY_IMAGE:$FLAVOR-$CI_COMMIT_SHORT_SHA`

## Inputs

| Input            | Default           | Description                          |
| ---------------- | ----------------- | ------------------------------------ |
| `dockerfile_dir` | `$CI_PROJECT_DIR` | Directory containing the Dockerfiles |

## License

SPDX-License-Identifier: EUPL-1.2

# Colorfy IoT Keel Kubernetes Terraform module

Terraform Module to deploy a [Keel](https://keel.sh/) instance with all the necessary components into an existing Kubernetes cluster.

Keel is a background service that automatically updates Kubernetes workloads. Enable keel for your workload by adding the annotations to its deployment. See also the [docs](https://keel.sh/docs/) and the example below.

## Table of contents

<!-- TOC is automatically generated using pre-commit hook -->

<!-- toc -->

- [Repository naming scheme](#repository-naming-scheme)
- [Getting started](#getting-started)
- [Used git branching model](#used-git-branching-model)
- [Repository layout](#repository-layout)
- [Module documentation](#module-documentation)
    * [Requirements](#requirements)
    * [Providers](#providers)
    * [Inputs](#inputs)
    * [Modules](#modules)
    * [Resources](#resources)
    * [Outputs](#outputs)
- [Examples](#examples)
    * [Simple example](#simple-example)

<!-- tocstop -->

## Repository naming scheme

This repository **does not** follow the [Colorfy Repository naming scheme](https://colorfy.atlassian.net/wiki/spaces/COLORFY/pages/1585119460/Git+Guidelines#Repository-naming-scheme).
This is due to the [Terraform Module registry restrictions](https://www.terraform.io/cloud-docs/registry/publish-modules#preparing-a-module-repository) where the repository name must be in the format of `terraform-<PROVIDER>-<NAME>`.

> Module repositories must use this three-part name format, where `<NAME>` reflects
> the type of infrastructure the module manages and `<PROVIDER>` is the main provider
> where it creates that infrastructure. The `<PROVIDER>` segment must be all lowercase.
> The `<NAME>` segment can contain additional hyphens. Examples: `terraform-google-vault`
> or `terraform-aws-ec2-instance`.

## Getting started

To use this module, see the [examples](examples) or go to the module registry [app.terraform.io/app/colorfy/registry/private/modules](https://app.terraform.io/app/colorfy/registry/private/modules).

Used tooling in this repository:

-   [Install Terraform](https://www.terraform.io/downloads)
-   (optional) Install [pre-commit](https://pre-commit.com/#installation) and configure git hooks by running `pre-commit install` to set up the git hook scripts.

## Used git branching model

The repository uses simple feature branches and tags to deploy automatic releases
to the Terraform registry. The branches ared:

-   `main`: The main branch of approved features.
-   `feature/feature-name`: Feature to be tested.

## Repository layout

The repository layout is split up into the following directories:

-   [docs](docs): Documentation and related content.
-   [examples](examples): Examples on how to use this module.
-   [modules](modules): Reusable (private) modules See [Terraform modules](https://www.terraform.io/docs/modules/index.html)

## Module documentation

The following sections shows the module's documentation. This section is is generated using `terraform-docs`.

<!-- terraform-docs will automatically update the rest of the documentations -->
<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.7.1 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.7.1 |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_values"></a> [additional\_values](#input\_additional\_values) | Additional Helm chart values. | `any` | `{}` | no |
| <a name="input_cert_manager_cluster_issuer"></a> [cert\_manager\_cluster\_issuer](#input\_cert\_manager\_cluster\_issuer) | What cert-manager cluster issuer to use. | `string` | n/a | yes |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Keel hostname for the embedded dashboard. E.g. keel.example.com | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where Keel will be deployed in. | `string` | n/a | yes |
| <a name="input_password"></a> [password](#input\_password) | Password for the web interface. | `string` | n/a | yes |
| <a name="input_username"></a> [username](#input\_username) | Username for the web interface. | `string` | `"admin"` | no |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [helm_release.keel](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

### Outputs

No outputs.

## Examples

Here are some examples on how to use this module.

### Simple example

```hcl
# Generate a password for the web interface
resource "random_password" "keel" {
  length  = 200
  numeric = true
  special = false
  upper   = true
}

# Install Keel into the cluster, this can work together with colorfy-iot-ingress-nginx module
module "keel" {
  source                      = "app.terraform.io/colorfy/colorfy-iot-keel/kubernetes"
  version                     = "~> 1.0"
  cert_manager_cluster_issuer = module.ingress.cert_manager_cluster_issuer_name
  hostname                    = "keel.example.com"
  namespace                   = "keel"
  username                    = "admin"
  password                    = random_password.keel.result
}

# Deploy workload that can be automatically updated by
# - Monitoring the same tag and updating the deployment when it changes
# - Monitoring a newer semver tag
# - or one of the other methods as described here https://keel.sh/docs/#policies
resource "kubernetes_deployment" "this" {
  metadata {
    name      = "whoami"
    namespace = "application"
    labels = {
      app = "whoami"
    }
    annotations = {
      "keel.sh/trigger"      = "poll"      # Poll the container registry for changes
      "keel.sh/policy"       = "force"     # Enable updates of non-semver tags
      "keel.sh/pollSchedule" = "@every 1m" # Poll every 1 minute
      "keel.sh/matchTag"     = "true"      # Match the actual tag, and don't get the latest new tag
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "whoami"
      }
    }
    template {
      metadata {
        labels = {
          app = "whoami"
        }
      }
      spec {
        container {
          image             = "docker.io/traefik/whoami:latest"
          name              = "whoami"
          image_pull_policy = "Always"
          port {
            container_port = 80
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [
      # Keel can update this annotation so that the deployment gets triggers,
      # for terraform, this can be ignored
      spec[0].template[0].metadata[0].annotations["keel.sh/update-time"],
    ]
  }
}
```
<!-- END_TF_DOCS -->

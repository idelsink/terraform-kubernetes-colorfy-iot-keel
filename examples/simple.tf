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

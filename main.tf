# Versioning of this chart is not well documented, here is a list of versions to get an idea of what can be found where
# Chart versions | Git reference
# 0.8.22         | tag v0.16.1
# 0.9.0          | tag v0.17.0-rc1
# 0.9.10         | revision 1c809fceecb6da5ec26f9039e08d308a5e8ddb1e : Introduced the ingress networking kind
# 0.9.11         | revision 22bb02ed8a48c9c310b4ab9a054c7366e3f3c961

resource "helm_release" "keel" {
  name       = "keel"
  chart      = "keel"
  repository = "https://charts.keel.sh"
  version    = "0.9.11"
  namespace  = var.namespace

  set_sensitive {
    name  = "basicauth.password"
    value = var.password
  }

  values = [
    jsonencode({
      basicauth = {
        enabled = true
        user    = var.username
        # password set via set_sensitive
      }
      helmProvider = {
        enabled = false # disabling Keel's helm provider here as we are only going to work with Kubernetes manifests
      }
      ingress = {
        enabled          = true
        ingressClassName = "nginx"
        annotations = {
          "cert-manager.io/cluster-issuer" = var.cert_manager_cluster_issuer
        }
        hosts = [{
          host  = var.hostname
          paths = ["/"]
        }]
        tls = [{
          secretName = "tls-${replace(var.hostname, ".", "-")}"
          hosts      = [var.hostname]
        }]
      }
      service = {
        # Enabling service for the ingress entry
        enabled      = true
        type         = "ClusterIP"
        externalPort = 9300
      }
    }),
    jsonencode(var.additional_values),
  ]
}

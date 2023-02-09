variable "additional_values" {
  description = "Additional Helm chart values."
  type        = any
  default     = {}
}

variable "cert_manager_cluster_issuer" {
  description = "What cert-manager cluster issuer to use."
  type        = string
}

variable "hostname" {
  description = "Keel hostname for the embedded dashboard. E.g. keel.example.com"
  type        = string
}

variable "namespace" {
  description = "Namespace where Keel will be deployed in."
  type        = string
}

variable "password" {
  description = "Password for the web interface."
  type        = string
  sensitive   = true
}

variable "username" {
  description = "Username for the web interface."
  type        = string
  default     = "admin"
}

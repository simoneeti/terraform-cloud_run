variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "service_name" {
  description = "Service name"
  type        = string
}
variable "region" {
  description = "Region to deploy to"
  type        = string
  default     = "us-central1"
}
variable "db_name" {
  description = "Creds database name"
  type        = string
}

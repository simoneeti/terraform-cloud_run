terraform {
  required_version = ">= 0.14"

  required_providers {
    # Cloud Run support was added on 3.3.0
    google = ">= 3.3"
  }
}

provider "google" {
  # Replace `PROJECT_ID` with your project
  project = var.project_id
}

# secret manager


# Enables the Cloud Run API
resource "google_project_service" "run_api" {
  service = "run.googleapis.com"

  disable_on_destroy = true
}



resource "google_cloud_run_service" "run_service" {
  name     = join("_", [var.service_name, "terraform"])
  location = var.region
  autogenerate_revision_name = true
  template {
    spec {
      containers {
        image = join("", ["gcr.io/", var.project_id, "/", var.service_name])
        env {
          name = "DB_PASSWORD"
          value_from {
            secret_key_ref {
              name = "DB_PASSWORD"
              key  = "latest"
            }
          }
        }

      }
      service_account_name = join("", [var.project_id, "@appspot.gserviceaccount.com"])
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"      = "1000"
        "run.googleapis.com/cloudsql-instances" = join(":", [var.project_id, var.region, var.db_name])
        "run.googleapis.com/client-name"        = "terraform"
      }
    }

  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  # Waits for the Cloud Run API to be enabled
  depends_on = [google_project_service.run_api]

}

# allow unauth
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.run_service.location
  project  = google_cloud_run_service.run_service.project
  service  = google_cloud_run_service.run_service.name

  policy_data = data.google_iam_policy.noauth.policy_data
}


output "service_url" {
  value = google_cloud_run_service.run_service.status[0].url
}

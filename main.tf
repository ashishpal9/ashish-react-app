provider "google" {
  project = var.project_id   # Reference the project ID from the variables
  region  = "us-central1"    # Set the desired region
}

resource "google_artifact_registry_repository" "my_repo" {
  repository_id = var.artifact_registry_repo
  location      = "us-central1"  # Specify the location for your Artifact Registry
  format        = "DOCKER"
  description   = "Artifact Registry for Docker images"
}

resource "google_cloud_run_service" "my_service" {
  name     = "my-service"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "us-central1-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repo}/${var.image_name}:${var.image_tag}"

        # Optional: Define environment variables
        env {
          name  = "ENV_VAR_NAME"
          value = "value"  # Modify this as needed for your application
        }
      }
    }

    # Enable public access to the service
    traffic {
      percent        = 100
    }
  }
}

# Output the Cloud Run service URL
output "service_url" {
  value = google_cloud_run_service.my_service.status[0].url
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "artifact_registry_repo" {
  description = "Artifact Registry Repository name"
  type        = string
}

variable "image_name" {
  description = "Docker image name"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
}

# IAM role for Cloud Run service account to pull images
resource "google_project_iam_member" "cloud_run_service_account" {
  project = var.project_id  # Reference the project ID from the variables
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_cloud_run_service.my_service.service_account_email}"
}

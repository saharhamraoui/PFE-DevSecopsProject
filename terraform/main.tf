terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

# Artifact Registry repository
resource "google_artifact_registry_repository" "repo" {
  repository_id = var.artifact_registry_repo
  location      = var.region
  format        = "DOCKER"
  description   = "Docker images for ${var.app_name}"

  depends_on = [google_project_service.apis]
}

# Cloud Run service
resource "google_cloud_run_v2_service" "app" {
  name     = var.app_name
  location = var.region

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repo}/${var.app_name}:latest"

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    scaling {
      min_instance_count = 1
      max_instance_count = 3
    }

    service_account = google_service_account.deployer.email
  }

  depends_on = [google_project_service.apis]
}

# Allow unauthenticated access to Cloud Run
resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ─── Grafana Cloud Run Service ─────────────────────────────────────────────

resource "google_cloud_run_v2_service" "grafana" {
  name     = "grafana"
  location = var.region

  template {
    containers {
      # Placeholder image used only on first terraform apply.
      # The CI/CD pipeline replaces this with the real Grafana image on every deploy.
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      # Grafana listens on 3000 by default
      ports {
        container_port = 3000
      }

      # Admin password injected at deploy time (override via GF_SECURITY_ADMIN_PASSWORD)
      env {
        name  = "GF_SECURITY_ADMIN_PASSWORD"
        value = var.grafana_admin_password
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    # Dedicated SA with monitoring.viewer — provides ADC for the Cloud Monitoring datasource
    service_account = google_service_account.grafana.email
  }

  depends_on = [google_project_service.apis]

  # Ignore image changes — the CI/CD pipeline owns the image tag after first deploy
  lifecycle {
    ignore_changes = [template[0].containers[0].image]
  }
}

# Allow unauthenticated access to Grafana (login required for admin)
resource "google_cloud_run_v2_service_iam_member" "grafana_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.grafana.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

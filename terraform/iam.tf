# Service account for GitHub Actions deployments
resource "google_service_account" "deployer" {
  account_id   = var.service_account_name
  display_name = "Cloud Run Deployer (GitHub Actions)"
}

# Grant Artifact Registry write access
resource "google_artifact_registry_repository_iam_member" "registry_writer" {
  repository = google_artifact_registry_repository.repo.repository_id
  location   = var.region
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.deployer.email}"
}

# Grant Cloud Run admin access
resource "google_project_iam_member" "cloud_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

# Grant Monitoring Viewer access (for Stackdriver exporter)
resource "google_project_iam_member" "monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

# Grant service account user on default compute SA (required by Cloud Run)
resource "google_service_account_iam_member" "act_as_compute" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.project_number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deployer.email}"
}

# Workload Identity Pool
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = var.wif_pool_id
  display_name              = "GitHub Actions Pool"
  depends_on                = [google_project_service.apis]
}

# Workload Identity Provider (OIDC for GitHub Actions)
resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.wif_provider_id
  display_name                       = "GitHub Actions Provider"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository=='${var.github_repo}'"
}

# Allow GitHub Actions to impersonate the deployer service account
resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

# ─── Grafana Service Account ───────────────────────────────────────────────

# Dedicated SA for the Grafana Cloud Run service
resource "google_service_account" "grafana" {
  account_id   = "grafana-cloud-run"
  display_name = "Grafana Cloud Run"
}

# Grant Grafana SA read access to Cloud Monitoring metrics (used by GCM datasource via ADC)
resource "google_project_iam_member" "grafana_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.grafana.email}"
}

# Allow the deployer SA to set the grafana SA on Cloud Run (required by gcloud run deploy)
resource "google_service_account_iam_member" "act_as_grafana" {
  service_account_id = google_service_account.grafana.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deployer.email}"
}

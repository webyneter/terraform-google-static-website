resource "google_storage_bucket" "website" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
  # https://cloud.google.com/storage/docs/hosting-static-website#create-bucket
  provider = google

  project = var.project

  name                        = "${var.website_name}-bucket"
  location                    = upper(var.bucket_region)
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  website {
    main_page_suffix = var.website_index_page_file_name

    # Why: https://stackoverflow.com/a/40786636/1557013
    # How so: https://cloud.google.com/storage/docs/gsutil/commands/web
    not_found_page = var.website_index_page_file_name
  }
}

resource "google_storage_bucket_iam_member" "website_public" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam
  provider = google

  bucket = google_storage_bucket.website.name

  # https://cloud.google.com/storage/docs/hosting-static-website#sharing
  role = "roles/storage.legacyObjectReader"

  member = "allUsers"
}

resource "google_service_account" "website" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account
  provider = google

  project = var.project

  # Forcing the name to match the pre-defined regex "^[a-z](?:[-a-z0-9]{4,28}[a-z0-9])$":
  account_id = trim(substr(google_storage_bucket.website.name, 0, 28), "-")
}

resource "google_storage_bucket_iam_member" "website_internal" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam
  provider = google

  bucket = google_storage_bucket.website.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.website.email}"
}

resource "google_service_account_key" "website" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_key
  provider = google

  service_account_id = google_service_account.website.name
}

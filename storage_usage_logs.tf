resource "google_storage_bucket" "website_usage_logs" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
  provider = google

  project = var.project

  name                        = "${local.website_bucket_name}-usage-logs-bucket"
  location                    = upper(var.bucket_region)
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "website_usage_logs" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam
  provider = google

  bucket = google_storage_bucket.website_usage_logs.name

  # https://cloud.google.com/storage/docs/access-logs#delivery
  member = "group:cloud-storage-analytics@google.com"
  role   = "roles/storage.legacyBucketWriter"
}

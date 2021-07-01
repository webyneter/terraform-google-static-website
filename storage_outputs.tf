output "bucket_name" {
  value = google_storage_bucket.website.name
}

output "bucket_service_account_id" {
  value = google_service_account.website.account_id
}

output "bucket_service_account_private_key" {
  value     = google_service_account_key.website.private_key
  sensitive = true
}

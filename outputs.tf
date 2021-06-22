output "bucket_name" {
  value = google_storage_bucket.website.name
}

output "bucket_service_account_private_key_filename" {
  value = local_file.website_service_account_private_key.filename
}

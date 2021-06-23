output "bucket_name" {
  value = google_storage_bucket.website.name
}

output "bucket_service_account_id" {
  value = google_service_account.website.account_id
}

output "bucket_service_account_private_key_filename" {
  value = local_file.website_service_account_private_key.filename
}

output "website_external_ip_name" {
  value = google_compute_global_address.website_external_ip.name
}

output "website_ssl_certificate_name" {
  value = google_compute_managed_ssl_certificate.website.name
}

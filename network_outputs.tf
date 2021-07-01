output "website_external_ip_name" {
  value = google_compute_global_address.website_external_ip.name
}

output "website_ssl_certificate_name" {
  value = google_compute_managed_ssl_certificate.website.name
}

output "website_http_to_https_redirect_url_map_name" {
  value = google_compute_url_map.website_http_to_https_redirect.name
}

output "website_http_to_https_redirect_target_http_proxy_name" {
  value = google_compute_target_http_proxy.website_http_to_https_redirect.name
}

output "website_http_to_https_redirect_global_forwarding_rule" {
  value = google_compute_global_forwarding_rule.website_http_to_https_redirect.name
}

output "website_url_map" {
  value = google_compute_url_map.website.name
}

output "website_target_https_proxy" {
  value = google_compute_target_https_proxy.website.name
}

output "website_global_forwarding_rule" {
  value = google_compute_global_forwarding_rule.website.name
}

output "bucket_backend_name" {
  value = google_compute_backend_bucket.website.name
}

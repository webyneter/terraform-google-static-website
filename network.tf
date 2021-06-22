resource "google_compute_global_address" "website_external_ip" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address
  provider = google

  name         = coalesce(var.compat_website_external_ip_name, "${var.website_name}-external-ip")
  address_type = "EXTERNAL"
}

resource "random_id" "website_ssl_certificate" {
  # https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id
  byte_length = 4
  keepers = {
    domains = var.website_domain
  }
}

resource "google_compute_managed_ssl_certificate" "website" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_managed_ssl_certificate
  provider = google

  name = "${coalesce(var.compat_website_ssl_certificate_name, "${var.website_name}-ssl-certificate")}-${random_id.website_ssl_certificate.hex}"

  managed {
    domains = [var.website_domain]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_backend_bucket" "website" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_bucket
  provider = google-beta

  name        = "${google_storage_bucket.website.name}-backend"
  bucket_name = google_storage_bucket.website.name
  custom_response_headers = [
    # https://cloud.google.com/load-balancing/docs/https/setting-up-http-https-redirect#adding_a_custom_header
    "Strict-Transport-Security:max-age=31536000; includeSubDomains; preload"
  ]
}

resource "google_compute_url_map" "website_http_to_https_redirect" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map
  provider = google

  name = "${var.website_name}-http-to-https-redirect-urlmap"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "website_http_to_https_redirect" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_http_proxy
  provider = google

  name    = "${var.website_name}-http-proxy"
  url_map = google_compute_url_map.website_http_to_https_redirect.id
}

resource "google_compute_global_forwarding_rule" "website_http_to_https_redirect" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule
  provider = google

  name       = "${var.website_name}-http-forwarding-rule"
  ip_address = google_compute_global_address.website_external_ip.id
  port_range = 80
  target     = google_compute_target_http_proxy.website_http_to_https_redirect.id
}

resource "google_compute_url_map" "website" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map
  provider = google

  name = "${var.website_name}-urlmap"

  test {
    host    = var.website_domain
    path    = "/"
    service = google_compute_backend_bucket.website.id
  }

  host_rule {
    hosts = [
      var.website_domain
    ]
    path_matcher = "path"
  }
  default_service = google_compute_backend_bucket.website.id

  path_matcher {
    name            = "path"
    default_service = google_compute_backend_bucket.website.id

    path_rule {
      paths   = ["/"]
      service = google_compute_backend_bucket.website.id
    }
  }
}

resource "google_compute_target_https_proxy" "website" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_https_proxy
  provider = google

  name    = "${var.website_name}-https-proxy"
  url_map = google_compute_url_map.website.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.website.id
  ]
}

resource "google_compute_global_forwarding_rule" "website" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule
  provider = google

  name       = "${var.website_name}-https-forwarding-rule"
  ip_address = google_compute_global_address.website_external_ip.id
  port_range = 443
  target     = google_compute_target_https_proxy.website.id
}

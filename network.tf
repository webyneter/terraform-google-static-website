resource "google_compute_global_address" "website_external_ip" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address
  provider = google

  project = var.project

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

  project = var.project

  name = "${coalesce(var.compat_website_ssl_certificate_name, "${var.website_name}-ssl-certificate")}-${random_id.website_ssl_certificate.hex}"

  managed {
    domains = [
      var.website_domain
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_backend_bucket" "website" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_bucket
  provider = google-beta

  project = var.project

  name                    = "${google_storage_bucket.website.name}-backend"
  bucket_name             = google_storage_bucket.website.name
  custom_response_headers = var.bucket_backend_custom_response_headers
}

resource "google_compute_url_map" "website_http_to_https_redirect" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map
  provider = google

  project = var.project

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

  project = var.project

  name    = "${var.website_name}-http-proxy"
  url_map = google_compute_url_map.website_http_to_https_redirect.id
}

resource "google_compute_global_forwarding_rule" "website_http_to_https_redirect" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule
  provider = google

  project = var.project

  name       = "${var.website_name}-http-forwarding-rule"
  ip_address = google_compute_global_address.website_external_ip.id
  port_range = 80
  target     = google_compute_target_http_proxy.website_http_to_https_redirect.id
}

resource "google_compute_url_map" "website" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map
  provider = google

  project = var.project

  name = "${var.website_name}-urlmap"

  test {
    description = coalesce(var.website_url_map_test.description, "Root path test case")
    host        = coalesce(var.website_url_map_test.host, var.website_domain)
    path        = coalesce(var.website_url_map_test.path, "/")
    service     = coalesce(var.website_url_map_test.service, google_compute_backend_bucket.website.id)
  }
  dynamic "test" {
    for_each = var.website_url_map_tests
    content {
      description = test.value.description
      host        = test.value.host
      path        = test.value.path
      service     = test.value.service
    }
  }

  default_service = coalesce(var.website_url_map_default_service, google_compute_backend_bucket.website.id)

  host_rule {
    description = coalesce(var.website_url_map_host_rule.description, "Host rule")
    hosts = coalesce(var.website_url_map_host_rule.hosts, [
      var.website_domain
    ])
    path_matcher = coalesce(var.website_url_map_host_rule.path_matcher, local.website_url_map_path_name)
  }
  dynamic "host_rule" {
    for_each = var.website_url_map_host_rules
    content {
      description  = host_rule.value.description
      hosts        = host_rule.value.hosts
      path_matcher = host_rule.value.path_matcher
    }
  }

  path_matcher {
    name            = coalesce(var.website_url_map_path_matcher.name, local.website_url_map_path_name)
    default_service = coalesce(var.website_url_map_path_matcher.default_service, google_compute_backend_bucket.website.id)

    path_rule {
      paths = coalesce(var.website_url_map_path_matcher.path_rule_paths, ["/"])

      # coalesce would opt for the default BOTH for "" and null whereas null is a valid value here.
      service = local.website_url_map_path_matcher.path_rule_service != "" ? local.website_url_map_path_matcher.path_rule_service : google_compute_backend_bucket.website.id

      dynamic "route_action" {
        for_each = coalesce(var.website_url_map_path_matcher.path_rule_route_action, [])
        content {
          dynamic "cors_policy" {
            for_each = coalesce(route_action.value.cors_policy, [])
            content {
              allow_credentials    = cors_policy.value.allow_credentials
              allow_headers        = cors_policy.value.allow_headers
              allow_methods        = cors_policy.value.allow_methods
              allow_origin_regexes = cors_policy.value.allow_origin_regexes
              allow_origins        = cors_policy.value.allow_origins
              disabled             = cors_policy.value.disabled
              expose_headers       = cors_policy.value.expose_headers
              max_age              = cors_policy.value.max_age
            }
          }

          dynamic "fault_injection_policy" {
            for_each = coalesce(route_action.value.fault_injection_policy, [])
            content {
              dynamic "abort" {
                for_each = coalesce(fault_injection_policy.value.abort, [])
                content {
                  http_status = abort.value.http_status
                  percentage  = abort.value.percentage
                }
              }
              dynamic "delay" {
                for_each = coalesce(fault_injection_policy.value.delay, [])
                content {
                  dynamic "fixed_delay" {
                    for_each = coalesce(delay.value.fixed_delay, [])
                    content {
                      nanos   = fixed_delay.value.nanos
                      seconds = fixed_delay.value.seconds
                    }
                  }
                  percentage = delay.value.percentage
                }
              }
            }
          }

          dynamic "request_mirror_policy" {
            for_each = coalesce(route_action.value.request_mirror_policy, [])
            content {
              backend_service = request_mirror_policy.value.backend_service
            }
          }

          dynamic "retry_policy" {
            for_each = coalesce(route_action.value.retry_policy, [])
            content {
              dynamic "per_try_timeout" {
                for_each = coalesce(retry_policy.value.per_try_timeout, [])
                content {
                  seconds = per_try_timeout.value.seconds
                  nanos   = per_try_timeout.value.nanos
                }
              }
              num_retries      = retry_policy.value.num_retries
              retry_conditions = retry_policy.value.retry_conditions
            }
          }

          dynamic "timeout" {
            for_each = coalesce(route_action.value.timeout, [])
            content {
              seconds = timeout.value.seconds
              nanos   = timeout.value.nanos
            }
          }

          dynamic "url_rewrite" {
            for_each = coalesce(route_action.value.url_rewrite, [])
            content {
              host_rewrite        = url_rewrite.value.host_rewrite
              path_prefix_rewrite = url_rewrite.value.path_prefix_rewrite
            }
          }

          dynamic "weighted_backend_services" {
            for_each = coalesce(route_action.value.weighted_backend_services, [])
            content {
              dynamic "header_action" {
                for_each = coalesce(weighted_backend_services.value.header_action, [])
                content {
                  dynamic "request_headers_to_add" {
                    for_each = coalesce(header_action.value.request_headers_to_add, [])
                    content {
                      header_name  = request_headers_to_add.value.header_name
                      header_value = request_headers_to_add.value.header_value
                      replace      = request_headers_to_add.value.replace
                    }
                  }
                  request_headers_to_remove = header_action.value.request_headers_to_remove
                  dynamic "response_headers_to_add" {
                    for_each = coalesce(header_action.value.response_headers_to_add, [])
                    content {
                      header_name  = response_headers_to_add.value.header_name
                      header_value = response_headers_to_add.value.header_value
                      replace      = response_headers_to_add.value.replace
                    }
                  }
                  response_headers_to_remove = header_action.value.response_headers_to_remove
                }
              }
              backend_service = weighted_backend_services.value.backend_service
              weight          = weighted_backend_services.value.weight
            }
          }
        }
      }

      dynamic "url_redirect" {
        for_each = coalesce(var.website_url_map_path_matcher.path_rule_url_redirect, [])
        content {
          strip_query            = url_redirect.value.strip_query
          host_redirect          = url_redirect.value.host_redirect
          https_redirect         = url_redirect.value.https_redirect
          path_redirect          = url_redirect.value.path_redirect
          prefix_redirect        = url_redirect.value.prefix_redirect
          redirect_response_code = url_redirect.value.redirect_response_code
        }
      }
    }
    dynamic "path_rule" {
      for_each = coalesce(var.website_url_map_path_matcher.extra_path_rules, [])
      content {
        paths   = path_rule.value.paths
        service = path_rule.value.service

        dynamic "route_action" {
          for_each = coalesce(path_rule.value.route_action, [])
          content {
            dynamic "cors_policy" {
              for_each = coalesce(route_action.value.cors_policy, [])
              content {
                allow_credentials    = cors_policy.value.allow_credentials
                allow_headers        = cors_policy.value.allow_headers
                allow_methods        = cors_policy.value.allow_methods
                allow_origin_regexes = cors_policy.value.allow_origin_regexes
                allow_origins        = cors_policy.value.allow_origins
                disabled             = cors_policy.value.disabled
                expose_headers       = cors_policy.value.expose_headers
                max_age              = cors_policy.value.max_age
              }
            }

            dynamic "fault_injection_policy" {
              for_each = coalesce(route_action.value.fault_injection_policy, [])
              content {
                dynamic "abort" {
                  for_each = coalesce(fault_injection_policy.value.abort, [])
                  content {
                    http_status = abort.value.http_status
                    percentage  = abort.value.percentage
                  }
                }
                dynamic "delay" {
                  for_each = coalesce(fault_injection_policy.value.delay, [])
                  content {
                    dynamic "fixed_delay" {
                      for_each = coalesce(delay.value.fixed_delay, [])
                      content {
                        nanos   = fixed_delay.value.nanos
                        seconds = fixed_delay.value.seconds
                      }
                    }
                    percentage = delay.value.percentage
                  }
                }
              }
            }

            dynamic "request_mirror_policy" {
              for_each = coalesce(route_action.value.request_mirror_policy, [])
              content {
                backend_service = request_mirror_policy.value.backend_service
              }
            }

            dynamic "retry_policy" {
              for_each = coalesce(route_action.value.retry_policy, [])
              content {
                dynamic "per_try_timeout" {
                  for_each = coalesce(retry_policy.value.per_try_timeout, [])
                  content {
                    seconds = per_try_timeout.value.seconds
                    nanos   = per_try_timeout.value.nanos
                  }
                }
                num_retries      = retry_policy.value.num_retries
                retry_conditions = retry_policy.value.retry_conditions
              }
            }

            dynamic "timeout" {
              for_each = coalesce(route_action.value.timeout, [])
              content {
                seconds = timeout.value.seconds
                nanos   = timeout.value.nanos
              }
            }

            dynamic "url_rewrite" {
              for_each = coalesce(route_action.value.url_rewrite, [])
              content {
                host_rewrite        = url_rewrite.value.host_rewrite
                path_prefix_rewrite = url_rewrite.value.path_prefix_rewrite
              }
            }

            dynamic "weighted_backend_services" {
              for_each = coalesce(route_action.value.weighted_backend_services, [])
              content {
                dynamic "header_action" {
                  for_each = coalesce(weighted_backend_services.value.header_action, [])
                  content {
                    dynamic "request_headers_to_add" {
                      for_each = coalesce(header_action.value.request_headers_to_add, [])
                      content {
                        header_name  = request_headers_to_add.value.header_name
                        header_value = request_headers_to_add.value.header_value
                        replace      = request_headers_to_add.value.replace
                      }
                    }
                    request_headers_to_remove = header_action.value.request_headers_to_remove
                    dynamic "response_headers_to_add" {
                      for_each = coalesce(header_action.value.response_headers_to_add, [])
                      content {
                        header_name  = response_headers_to_add.value.header_name
                        header_value = response_headers_to_add.value.header_value
                        replace      = response_headers_to_add.value.replace
                      }
                    }
                    response_headers_to_remove = header_action.value.response_headers_to_remove
                  }
                }
                backend_service = weighted_backend_services.value.backend_service
                weight          = weighted_backend_services.value.weight
              }
            }
          }
        }

        dynamic "url_redirect" {
          for_each = coalesce(path_rule.value.url_redirect, [])
          content {
            strip_query            = url_redirect.value.strip_query
            host_redirect          = url_redirect.value.host_redirect
            https_redirect         = url_redirect.value.https_redirect
            path_redirect          = url_redirect.value.path_redirect
            prefix_redirect        = url_redirect.value.prefix_redirect
            redirect_response_code = url_redirect.value.redirect_response_code
          }
        }
      }
    }
  }
  dynamic "path_matcher" {
    for_each = var.website_url_map_path_matchers
    content {
      name        = path_matcher.value.name
      description = path_matcher.value.description

      default_service = path_matcher.value.default_service
      dynamic "default_url_redirect" {
        for_each = coalesce(path_matcher.value.default_url_redirect, [])
        content {
          strip_query            = default_url_redirect.value.strip_query
          host_redirect          = default_url_redirect.value.host_redirect
          https_redirect         = default_url_redirect.value.https_redirect
          path_redirect          = default_url_redirect.value.path_redirect
          prefix_redirect        = default_url_redirect.value.prefix_redirect
          redirect_response_code = default_url_redirect.value.redirect_response_code
        }
      }

      dynamic "default_route_action" {
        for_each = coalesce(path_matcher.value.default_route_action, [])
        content {
          dynamic "cors_policy" {
            for_each = coalesce(default_route_action.value.cors_policy, [])
            content {
              allow_credentials    = cors_policy.value.allow_credentials
              allow_headers        = cors_policy.value.allow_headers
              allow_methods        = cors_policy.value.allow_methods
              allow_origin_regexes = cors_policy.value.allow_origin_regexes
              allow_origins        = cors_policy.value.allow_origins
              disabled             = cors_policy.value.disabled
              expose_headers       = cors_policy.value.expose_headers
              max_age              = cors_policy.value.max_age
            }
          }

          dynamic "fault_injection_policy" {
            for_each = coalesce(default_route_action.value.fault_injection_policy, [])
            content {
              dynamic "abort" {
                for_each = coalesce(fault_injection_policy.value.abort, [])
                content {
                  http_status = abort.value.http_status
                  percentage  = abort.value.percentage
                }
              }
              dynamic "delay" {
                for_each = coalesce(fault_injection_policy.value.delay, [])
                content {
                  dynamic "fixed_delay" {
                    for_each = coalesce(delay.value.fixed_delay, [])
                    content {
                      nanos   = fixed_delay.value.nanos
                      seconds = fixed_delay.value.seconds
                    }
                  }
                  percentage = delay.value.percentage
                }
              }
            }
          }

          dynamic "request_mirror_policy" {
            for_each = coalesce(default_route_action.value.request_mirror_policy, [])
            content {
              backend_service = request_mirror_policy.value.backend_service
            }
          }

          dynamic "retry_policy" {
            for_each = coalesce(default_route_action.value.retry_policy, [])
            content {
              num_retries      = retry_policy.value.num_retries
              retry_conditions = retry_policy.value.retry_conditions
              dynamic "per_try_timeout" {
                for_each = coalesce(retry_policy.value.per_try_timeout, [])
                content {
                  seconds = per_try_timeout.value.seconds
                  nanos   = per_try_timeout.value.nanos
                }
              }
            }
          }

          dynamic "timeout" {
            for_each = coalesce(default_route_action.value.timeout, [])
            content {
              seconds = timeout.value.seconds
              nanos   = timeout.value.nanos
            }
          }

          dynamic "url_rewrite" {
            for_each = coalesce(default_route_action.value.url_rewrite, [])
            content {
              host_rewrite        = url_rewrite.value.host_rewrite
              path_prefix_rewrite = url_rewrite.value.path_prefix_rewrite
            }
          }

          dynamic "weighted_backend_services" {
            for_each = coalesce(default_route_action.value.weighted_backend_services, [])
            content {
              backend_service = weighted_backend_services.value.backend_service
              weight          = weighted_backend_services.value.weight
              dynamic "header_action" {
                for_each = coalesce(weighted_backend_services.value.header_action, [])
                content {
                  dynamic "request_headers_to_add" {
                    for_each = coalesce(header_action.value.request_headers_to_add, [])
                    content {
                      header_name  = request_headers_to_add.value.header_name
                      header_value = request_headers_to_add.value.header_value
                      replace      = request_headers_to_add.value.replace
                    }
                  }
                  request_headers_to_remove = header_action.value.request_headers_to_remove
                  dynamic "response_headers_to_add" {
                    for_each = coalesce(header_action.value.response_headers_to_add, [])
                    content {
                      header_name  = response_headers_to_add.value.header_name
                      header_value = response_headers_to_add.value.header_value
                      replace      = response_headers_to_add.value.replace
                    }
                  }
                  response_headers_to_remove = header_action.value.response_headers_to_remove
                }
              }
            }
          }
        }
      }

      dynamic "header_action" {
        for_each = coalesce(path_matcher.value.header_action, [])
        content {
          request_headers_to_remove  = header_action.value.request_headers_to_remove
          response_headers_to_remove = header_action.value.response_headers_to_remove

          dynamic "request_headers_to_add" {
            for_each = coalesce(header_action.value.request_headers_to_add, [])
            content {
              header_name  = request_headers_to_add.value.header_name
              header_value = request_headers_to_add.value.header_value
              replace      = request_headers_to_add.value.replace
            }
          }

          dynamic "response_headers_to_add" {
            for_each = coalesce(header_action.value.response_headers_to_add, [])
            content {
              header_name  = response_headers_to_add.value.header_name
              header_value = response_headers_to_add.value.header_value
              replace      = response_headers_to_add.value.replace
            }
          }
        }
      }

      dynamic "path_rule" {
        for_each = coalesce(path_matcher.value.path_rule, [])
        content {
          paths   = path_rule.value.paths
          service = path_rule.value.service

          dynamic "route_action" {
            for_each = coalesce(path_rule.value.route_action, [])
            content {
              dynamic "cors_policy" {
                for_each = coalesce(route_action.value.cors_policy, [])
                content {
                  allow_credentials    = cors_policy.value.allow_credentials
                  allow_headers        = cors_policy.value.allow_headers
                  allow_methods        = cors_policy.value.allow_methods
                  allow_origin_regexes = cors_policy.value.allow_origin_regexes
                  allow_origins        = cors_policy.value.allow_origins
                  disabled             = cors_policy.value.disabled
                  expose_headers       = cors_policy.value.expose_headers
                  max_age              = cors_policy.value.max_age
                }
              }

              dynamic "fault_injection_policy" {
                for_each = coalesce(route_action.value.fault_injection_policy, [])
                content {
                  dynamic "abort" {
                    for_each = coalesce(fault_injection_policy.value.abort, [])
                    content {
                      http_status = abort.value.http_status
                      percentage  = abort.value.percentage
                    }
                  }
                  dynamic "delay" {
                    for_each = coalesce(fault_injection_policy.value.delay, [])
                    content {
                      dynamic "fixed_delay" {
                        for_each = coalesce(delay.value.fixed_delay, [])
                        content {
                          nanos   = fixed_delay.value.nanos
                          seconds = fixed_delay.value.seconds
                        }
                      }
                      percentage = delay.value.percentage
                    }
                  }
                }
              }

              dynamic "request_mirror_policy" {
                for_each = coalesce(route_action.value.request_mirror_policy, [])
                content {
                  backend_service = request_mirror_policy.value.backend_service
                }
              }

              dynamic "retry_policy" {
                for_each = coalesce(route_action.value.retry_policy, [])
                content {
                  dynamic "per_try_timeout" {
                    for_each = coalesce(retry_policy.value.per_try_timeout, [])
                    content {
                      seconds = per_try_timeout.value.seconds
                      nanos   = per_try_timeout.value.nanos
                    }
                  }
                  num_retries      = retry_policy.value.num_retries
                  retry_conditions = retry_policy.value.retry_conditions
                }
              }

              dynamic "timeout" {
                for_each = coalesce(route_action.value.timeout, [])
                content {
                  seconds = timeout.value.seconds
                  nanos   = timeout.value.nanos
                }
              }

              dynamic "url_rewrite" {
                for_each = coalesce(route_action.value.url_rewrite, [])
                content {
                  host_rewrite        = url_rewrite.value.host_rewrite
                  path_prefix_rewrite = url_rewrite.value.path_prefix_rewrite
                }
              }

              dynamic "weighted_backend_services" {
                for_each = coalesce(route_action.value.weighted_backend_services, [])
                content {
                  dynamic "header_action" {
                    for_each = coalesce(weighted_backend_services.value.header_action, [])
                    content {
                      dynamic "request_headers_to_add" {
                        for_each = coalesce(header_action.value.request_headers_to_add, [])
                        content {
                          header_name  = request_headers_to_add.value.header_name
                          header_value = request_headers_to_add.value.header_value
                          replace      = request_headers_to_add.value.replace
                        }
                      }
                      request_headers_to_remove = header_action.value.request_headers_to_remove
                      dynamic "response_headers_to_add" {
                        for_each = coalesce(header_action.value.response_headers_to_add, [])
                        content {
                          header_name  = response_headers_to_add.value.header_name
                          header_value = response_headers_to_add.value.header_value
                          replace      = response_headers_to_add.value.replace
                        }
                      }
                      response_headers_to_remove = header_action.value.response_headers_to_remove
                    }
                  }
                  backend_service = weighted_backend_services.value.backend_service
                  weight          = weighted_backend_services.value.weight
                }
              }
            }
          }

          dynamic "url_redirect" {
            for_each = coalesce(path_rule.value.url_redirect, [])
            content {
              strip_query            = url_redirect.value.strip_query
              host_redirect          = url_redirect.value.host_redirect
              https_redirect         = url_redirect.value.https_redirect
              path_redirect          = url_redirect.value.path_redirect
              prefix_redirect        = url_redirect.value.prefix_redirect
              redirect_response_code = url_redirect.value.redirect_response_code
            }
          }
        }
      }

      dynamic "route_rules" {
        for_each = coalesce(path_matcher.value.route_rules, [])
        content {
          priority = route_rules.value.priority
          service  = route_rules.value.service

          dynamic "header_action" {
            for_each = coalesce(route_rules.value.header_action, [])
            content {
              dynamic "request_headers_to_add" {
                for_each = coalesce(header_action.value.request_headers_to_add, [])
                content {
                  header_name  = request_headers_to_add.value.header_name
                  header_value = request_headers_to_add.value.header_value
                  replace      = request_headers_to_add.value.replace
                }
              }
              request_headers_to_remove = header_action.value.request_headers_to_remove
              dynamic "response_headers_to_add" {
                for_each = coalesce(header_action.value.response_headers_to_add, [])
                content {
                  header_name  = response_headers_to_add.value.header_name
                  header_value = response_headers_to_add.value.header_value
                  replace      = response_headers_to_add.value.replace
                }
              }
              response_headers_to_remove = header_action.value.response_headers_to_remove
            }
          }

          dynamic "match_rules" {
            for_each = coalesce(path_matcher.value.match_rules, [])
            content {
              full_path_match = match_rules.value.full_path_match
              ignore_case     = match_rules.value.ignore_case
              prefix_match    = match_rules.value.prefix_match
              regex_match     = match_rules.value.regex_match

              dynamic "header_matches" {
                for_each = coalesce(match_rules.value.header_matches, [])
                content {
                  header_name   = header_matches.value.header_name
                  exact_match   = header_matches.value.exact_match
                  invert_match  = header_matches.value.invert_match
                  prefix_match  = header_matches.value.prefix_match
                  present_match = header_matches.value.present_match
                  regex_match   = header_matches.value.regex_match
                  suffix_match  = header_matches.value.suffix_match
                  dynamic "range_match" {
                    for_each = coalesce(header_matches.value.range_match, [])
                    content {
                      range_start = range_match.value.range_start
                      range_end   = range_match.value.range_end
                    }
                  }
                }
              }

              dynamic "metadata_filters" {
                for_each = coalesce(match_rules.value.metadata_filters, [])
                content {
                  filter_match_criteria = metadata_filters.value.metadata_filters
                  dynamic "filter_labels" {
                    for_each = coalesce(metadata_filters.value.filter_labels, [])
                    content {
                      name  = filter_labels.value.name
                      value = filter_labels.value.value
                    }
                  }
                }
              }

              dynamic "query_parameter_matches" {
                for_each = coalesce(match_rules.value.query_parameter_matches, [])
                content {
                  name          = query_parameter_matches.value.name
                  exact_match   = query_parameter_matches.value.exact_match
                  present_match = query_parameter_matches.value.present_match
                  regex_match   = query_parameter_matches.value.regex_match
                }
              }
            }
          }

          dynamic "route_action" {
            for_each = coalesce(route_rules.value.route_action, [])
            content {
              dynamic "cors_policy" {
                for_each = coalesce(route_action.value.cors_policy, [])
                content {
                  allow_credentials    = cors_policy.value.allow_credentials
                  allow_headers        = cors_policy.value.allow_headers
                  allow_methods        = cors_policy.value.allow_methods
                  allow_origin_regexes = cors_policy.value.allow_origin_regexes
                  allow_origins        = cors_policy.value.allow_origins
                  disabled             = cors_policy.value.disabled
                  expose_headers       = cors_policy.value.expose_headers
                  max_age              = cors_policy.value.max_age
                }
              }

              dynamic "fault_injection_policy" {
                for_each = coalesce(route_action.value.fault_injection_policy, [])
                content {
                  dynamic "abort" {
                    for_each = coalesce(fault_injection_policy.value.abort, [])
                    content {
                      http_status = abort.value.http_status
                      percentage  = abort.value.percentage
                    }
                  }
                  dynamic "delay" {
                    for_each = coalesce(fault_injection_policy.value.delay, [])
                    content {
                      dynamic "fixed_delay" {
                        for_each = coalesce(delay.value.fixed_delay, [])
                        content {
                          nanos   = fixed_delay.value.nanos
                          seconds = fixed_delay.value.seconds
                        }
                      }
                      percentage = delay.value.percentage
                    }
                  }
                }
              }

              dynamic "request_mirror_policy" {
                for_each = coalesce(route_action.value.request_mirror_policy, [])
                content {
                  backend_service = request_mirror_policy.value.backend_service
                }
              }

              dynamic "retry_policy" {
                for_each = coalesce(route_action.value.retry_policy, [])
                content {
                  dynamic "per_try_timeout" {
                    for_each = coalesce(retry_policy.value.per_try_timeout, [])
                    content {
                      seconds = per_try_timeout.value.seconds
                      nanos   = per_try_timeout.value.nanos
                    }
                  }
                  num_retries      = retry_policy.value.num_retries
                  retry_conditions = retry_policy.value.retry_conditions
                }
              }

              dynamic "timeout" {
                for_each = coalesce(route_action.value.timeout, [])
                content {
                  seconds = timeout.value.seconds
                  nanos   = timeout.value.nanos
                }
              }

              dynamic "url_rewrite" {
                for_each = coalesce(route_action.value.url_rewrite, [])
                content {
                  host_rewrite        = url_rewrite.value.host_rewrite
                  path_prefix_rewrite = url_rewrite.value.path_prefix_rewrite
                }
              }

              dynamic "weighted_backend_services" {
                for_each = coalesce(route_action.value.weighted_backend_services, [])
                content {
                  dynamic "header_action" {
                    for_each = coalesce(weighted_backend_services.value.header_action, [])
                    content {
                      dynamic "request_headers_to_add" {
                        for_each = coalesce(header_action.value.request_headers_to_add, [])
                        content {
                          header_name  = request_headers_to_add.value.header_name
                          header_value = request_headers_to_add.value.header_value
                          replace      = request_headers_to_add.value.replace
                        }
                      }
                      request_headers_to_remove = header_action.value.request_headers_to_remove
                      dynamic "response_headers_to_add" {
                        for_each = coalesce(header_action.value.response_headers_to_add, [])
                        content {
                          header_name  = response_headers_to_add.value.header_name
                          header_value = response_headers_to_add.value.header_value
                          replace      = response_headers_to_add.value.replace
                        }
                      }
                      response_headers_to_remove = header_action.value.response_headers_to_remove
                    }
                  }
                  backend_service = weighted_backend_services.value.backend_service
                  weight          = weighted_backend_services.value.weight
                }
              }
            }
          }

          dynamic "url_redirect" {
            for_each = coalesce(route_rules.value.url_redirect, [])
            content {
              strip_query            = url_redirect.value.strip_query
              host_redirect          = url_redirect.value.host_redirect
              https_redirect         = url_redirect.value.https_redirect
              path_redirect          = url_redirect.value.path_redirect
              prefix_redirect        = url_redirect.value.prefix_redirect
              redirect_response_code = url_redirect.value.redirect_response_code
            }
          }
        }
      }
    }
  }
}

resource "google_compute_target_https_proxy" "website" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_https_proxy
  provider = google

  project = var.project

  name    = "${var.website_name}-https-proxy"
  url_map = google_compute_url_map.website.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.website.id
  ]
}

resource "google_compute_global_forwarding_rule" "website" {
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule
  provider = google

  project = var.project

  name       = "${var.website_name}-https-forwarding-rule"
  ip_address = google_compute_global_address.website_external_ip.id
  port_range = 443
  target     = google_compute_target_https_proxy.website.id
}

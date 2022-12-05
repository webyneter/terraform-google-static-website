# ==================
# Required variables
# ==================

variable "project" {
  description = "The project id"
  type        = string
}

variable "website_name" {
  description = "The DNS-compatible name of the website"
  type        = string
}

variable "website_domain" {
  description = "The website domain"
  type        = string
}

variable "bucket_region" {
  description = "The region of the bucket"
  type        = string
}

# ==================
# Optional variables
# ==================

variable "website_bucket_force_destroy" {
  description = "The website bucket force_destroy argument value."
  type        = bool
  default     = false
}

variable "website_usage_logs_bucket_force_destroy" {
  description = "The website usage logs bucket force_destroy argument value."
  type        = bool
  default     = false
}

variable "bucket_backend_custom_response_headers" {
  description = "Bucket backend custom response headers"
  type        = list(string)
  default = [
    # https://cloud.google.com/load-balancing/docs/https/setting-up-http-https-redirect#adding_a_custom_header
    "Strict-Transport-Security:max-age=31536000; includeSubDomains; preload"
  ]
}

variable "website_index_page_file_name" {
  description = "The name of the website's index file"
  type        = string
  default     = "index.html"
}

variable "website_url_map_test" {
  description = "The custom configuration for the URL map's pre-existing test"
  type = object({
    description = optional(string)
    host        = optional(string)
    path        = optional(string)
    service     = optional(string)
  })
  default = {}
}

variable "website_url_map_tests" {
  description = "The URL map's tests"
  type = list(object({
    description = optional(string)
    host        = string
    path        = string
    service     = string
  }))
  default = []
}

variable "website_url_map_default_service" {
  description = "The id of a service to be used as the website URL map's default_service"
  type        = string
  default     = null
}

variable "website_url_map_host_rule" {
  description = "The custom configuration for the URL map's pre-existing host rule"
  type = object({
    description  = optional(string)
    hosts        = optional(set(string))
    path_matcher = optional(string)
  })
  default = {}
}

variable "website_url_map_host_rules" {
  description = "The URL map's host rules"
  type = list(object({
    description  = optional(string)
    hosts        = set(string)
    path_matcher = string
  }))
  default = []
}

variable "website_url_map_path_matcher" {
  description = "The custom configuration for the URL map's pre-existing path matcher"
  type = object({
    name              = optional(string)
    default_service   = optional(string)
    path_rule_paths   = optional(set(string))
    path_rule_service = optional(string)

    path_rule_route_action = optional(list(object({
      cors_policy = optional(list(object({
        allow_credentials    = optional(bool)
        allow_headers        = optional(list(string))
        allow_methods        = optional(list(string))
        allow_origin_regexes = optional(list(string))
        allow_origins        = optional(list(string))
        disabled             = optional(bool)
        expose_headers       = optional(list(string))
        max_age              = optional(number)
      })))

      fault_injection_policy = optional(list(object({
        abort = optional(list(object({
          http_status = number
          percentage  = number
        })))
        delay = optional(list(object({
          fixed_delay = list(object({
            seconds = string
            nanos   = optional(number)
          }))
          percentage = number
        })))
      })))

      request_mirror_policy = optional(list(object({
        backend_service = string
      })))

      retry_policy = optional(list(object({
        per_try_timeout = optional(list(object({
          seconds = string
          nanos   = optional(number)
        })))
        num_retries      = optional(number)
        retry_conditions = optional(list(string))
      })))

      timeout = optional(list(object({
        seconds = string
        nanos   = optional(number)
      })))

      url_rewrite = optional(list(object({
        host_rewrite        = optional(string)
        path_prefix_rewrite = optional(string)
      })))

      weighted_backend_services = optional(list(object({
        header_action = optional(list(object({
          request_headers_to_add = optional(list(object({
            header_name  = string
            header_value = string
            replace      = bool
          })))
          request_headers_to_remove = optional(list(string))
          response_headers_to_add = optional(list(object({
            header_name  = string
            header_value = string
            replace      = bool
          })))
          response_headers_to_remove = optional(list(string))
        })))
        backend_service = string
        weight          = string
      })))
    })))

    path_rule_url_redirect = optional(list(object({
      strip_query            = bool
      host_redirect          = optional(string)
      https_redirect         = optional(bool)
      path_redirect          = optional(string)
      prefix_redirect        = optional(string)
      redirect_response_code = optional(string)
    })))

    extra_path_rules = optional(list(object({
      paths   = set(string)
      service = optional(string)

      route_action = optional(list(object({
        cors_policy = optional(list(object({
          allow_credentials    = optional(bool)
          allow_headers        = optional(list(string))
          allow_methods        = optional(list(string))
          allow_origin_regexes = optional(list(string))
          allow_origins        = optional(list(string))
          disabled             = optional(bool)
          expose_headers       = optional(list(string))
          max_age              = optional(number)
        })))

        fault_injection_policy = optional(list(object({
          abort = optional(list(object({
            http_status = number
            percentage  = number
          })))
          delay = optional(list(object({
            fixed_delay = list(object({
              seconds = string
              nanos   = optional(number)
            }))
            percentage = number
          })))
        })))

        request_mirror_policy = optional(list(object({
          backend_service = string
        })))

        retry_policy = optional(list(object({
          per_try_timeout = optional(list(object({
            seconds = string
            nanos   = optional(number)
          })))
          num_retries      = optional(number)
          retry_conditions = optional(list(string))
        })))

        timeout = optional(list(object({
          seconds = string
          nanos   = optional(number)
        })))

        url_rewrite = optional(list(object({
          host_rewrite        = optional(string)
          path_prefix_rewrite = optional(string)
        })))

        weighted_backend_services = optional(list(object({
          header_action = optional(list(object({
            request_headers_to_add = optional(list(object({
              header_name  = string
              header_value = string
              replace      = bool
            })))
            request_headers_to_remove = optional(list(string))
            response_headers_to_add = optional(list(object({
              header_name  = string
              header_value = string
              replace      = bool
            })))
            response_headers_to_remove = optional(list(string))
          })))
          backend_service = string
          weight          = string
        })))
      })))

      url_redirect = optional(list(object({
        strip_query            = bool
        host_redirect          = optional(string)
        https_redirect         = optional(bool)
        path_redirect          = optional(string)
        prefix_redirect        = optional(string)
        redirect_response_code = optional(string)
      })))
    })))

  })
  default = {}
}

variable "website_url_map_path_matchers" {
  description = "The URL map's path matchers"
  type = list(object({
    name        = string
    description = optional(string)

    default_service = optional(string)
    default_url_redirect = optional(list(object({
      strip_query            = bool
      host_redirect          = optional(string)
      https_redirect         = optional(bool)
      path_redirect          = optional(string)
      prefix_redirect        = optional(string)
      redirect_response_code = optional(string)
    })))

    default_route_action = optional(list(object({
      cors_policy = optional(list(object({
        allow_credentials    = optional(bool)
        allow_headers        = optional(list(string))
        allow_methods        = optional(list(string))
        allow_origin_regexes = optional(list(string))
        allow_origins        = optional(list(string))
        disabled             = optional(bool)
        expose_headers       = optional(list(string))
        max_age              = optional(number)
      })))

      fault_injection_policy = optional(list(object({
        abort = optional(list(object({
          http_status = number
          percentage  = number
        })))
        delay = optional(list(object({
          fixed_delay = list(object({
            seconds = string
            nanos   = optional(number)
          }))
          percentage = number
        })))
      })))

      request_mirror_policy = optional(list(object({
        backend_service = string
      })))

      retry_policy = optional(list(object({
        per_try_timeout = optional(list(object({
          seconds = string
          nanos   = optional(number)
        })))
        num_retries      = optional(number)
        retry_conditions = optional(list(string))
      })))

      timeout = optional(list(object({
        seconds = string
        nanos   = optional(number)
      })))

      url_rewrite = optional(list(object({
        host_rewrite        = optional(string)
        path_prefix_rewrite = optional(string)
      })))

      weighted_backend_services = optional(list(object({
        header_action = optional(list(object({
          request_headers_to_add = optional(list(object({
            header_name  = string
            header_value = string
            replace      = bool
          })))
          request_headers_to_remove = optional(list(string))
          response_headers_to_add = optional(list(object({
            header_name  = string
            header_value = string
            replace      = bool
          })))
          response_headers_to_remove = optional(list(string))
        })))
        backend_service = string
        weight          = string
      })))
    })))

    header_action = optional(list(object({
      request_headers_to_add = optional(list(object({
        header_name  = string
        header_value = string
        replace      = bool
      })))
      request_headers_to_remove = optional(list(string))
      response_headers_to_add = optional(list(object({
        header_name  = string
        header_value = string
        replace      = bool
      })))
      response_headers_to_remove = optional(list(string))
    })))

    path_rule = optional(list(object({
      paths   = set(string)
      service = optional(string)
      route_action = optional(list(object({
        cors_policy = optional(list(object({
          allow_credentials    = optional(bool)
          allow_headers        = optional(list(string))
          allow_methods        = optional(list(string))
          allow_origin_regexes = optional(list(string))
          allow_origins        = optional(list(string))
          disabled             = optional(bool)
          expose_headers       = optional(list(string))
          max_age              = optional(number)
        })))

        fault_injection_policy = optional(list(object({
          abort = optional(list(object({
            http_status = number
            percentage  = number
          })))
          delay = optional(list(object({
            fixed_delay = list(object({
              seconds = string
              nanos   = optional(number)
            }))
            percentage = number
          })))
        })))

        request_mirror_policy = optional(list(object({
          backend_service = string
        })))

        retry_policy = optional(list(object({
          per_try_timeout = optional(list(object({
            seconds = string
            nanos   = optional(number)
          })))
          num_retries      = optional(number)
          retry_conditions = optional(list(string))
        })))

        timeout = optional(list(object({
          seconds = string
          nanos   = optional(number)
        })))

        url_rewrite = optional(list(object({
          host_rewrite        = optional(string)
          path_prefix_rewrite = optional(string)
        })))

        weighted_backend_services = optional(list(object({
          header_action = optional(list(object({
            request_headers_to_add = optional(list(object({
              header_name  = string
              header_value = string
              replace      = bool
            })))
            request_headers_to_remove = optional(list(string))
            response_headers_to_add = optional(list(object({
              header_name  = string
              header_value = string
              replace      = bool
            })))
            response_headers_to_remove = optional(list(string))
          })))
          backend_service = string
          weight          = string
        })))
      })))
      url_redirect = optional(list(object({
        strip_query            = bool
        host_redirect          = optional(string)
        https_redirect         = optional(bool)
        path_redirect          = optional(string)
        prefix_redirect        = optional(string)
        redirect_response_code = optional(string)
      })))
    })))

    route_rules = optional(list(object({
      priority = number
      service  = optional(string)

      header_action = optional(list(object({
        request_headers_to_add = optional(list(object({
          header_name  = string
          header_value = string
          replace      = bool
        })))
        request_headers_to_remove = optional(list(string))
        response_headers_to_add = optional(list(object({
          header_name  = string
          header_value = string
          replace      = bool
        })))
        response_headers_to_remove = optional(list(string))
      })))

      match_rules = optional(list(object({
        full_path_match = optional(string)
        ignore_case     = optional(bool)
        prefix_match    = optional(string)
        regex_match     = optional(string)

        header_matches = optional(list(object({
          header_name   = string
          exact_match   = optional(string)
          invert_match  = optional(bool)
          prefix_match  = optional(string)
          present_match = optional(bool)
          regex_match   = optional(string)
          suffix_match  = optional(string)

          range_match = optional(list(object({
            range_start = number
            range_end   = number
          })))
        })))

        metadata_filters = optional(list(object({
          filter_match_criteria = string
          filter_labels = list(object({
            name  = string
            value = string
          }))
        })))

        query_parameter_matches = optional(list(object({
          name          = string
          exact_match   = optional(string)
          present_match = optional(bool)
          regex_match   = optional(string)
        })))
      })))

      route_action = optional(list(object({
        cors_policy = optional(list(object({
          allow_credentials    = optional(bool)
          allow_headers        = optional(list(string))
          allow_methods        = optional(list(string))
          allow_origin_regexes = optional(list(string))
          allow_origins        = optional(list(string))
          disabled             = optional(bool)
          expose_headers       = optional(list(string))
          max_age              = optional(number)
        })))

        fault_injection_policy = optional(list(object({
          abort = optional(list(object({
            http_status = number
            percentage  = number
          })))
          delay = optional(list(object({
            fixed_delay = list(object({
              seconds = string
              nanos   = optional(number)
            }))
            percentage = number
          })))
        })))

        request_mirror_policy = optional(list(object({
          backend_service = string
        })))

        retry_policy = optional(list(object({
          per_try_timeout = optional(list(object({
            seconds = string
            nanos   = optional(number)
          })))
          num_retries      = optional(number)
          retry_conditions = optional(list(string))
        })))

        timeout = optional(list(object({
          seconds = string
          nanos   = optional(number)
        })))

        url_rewrite = optional(list(object({
          host_rewrite        = optional(string)
          path_prefix_rewrite = optional(string)
        })))

        weighted_backend_services = optional(list(object({
          header_action = optional(list(object({
            request_headers_to_add = optional(list(object({
              header_name  = string
              header_value = string
              replace      = bool
            })))
            request_headers_to_remove = optional(list(string))
            response_headers_to_add = optional(list(object({
              header_name  = string
              header_value = string
              replace      = bool
            })))
            response_headers_to_remove = optional(list(string))
          })))
          backend_service = string
          weight          = string
        })))
      })))

      url_redirect = optional(list(object({
        strip_query            = bool
        host_redirect          = optional(string)
        https_redirect         = optional(bool)
        path_redirect          = optional(string)
        prefix_redirect        = optional(string)
        redirect_response_code = optional(string)
      })))
    })))
  }))
  default = []
}

# =======================================================================================
# Optional variables for backward compatibility with your system's pre-existing resources
# =======================================================================================

variable "compat_website_external_ip_name" {
  description = "The name of the pre-existing External IP to facilitate backward compatibility"
  type        = string
  default     = null
}

variable "compat_website_ssl_certificate_name" {
  description = "The name of the pre-existing SSL/TLS certificate to facilitate backward compatibility"
  type        = string
  default     = null
}

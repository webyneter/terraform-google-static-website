terraform {
  required_version = ">= 0.15"

  required_providers {
    random = {
      # https://registry.terraform.io/providers/hashicorp/random/latest/docs
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
    local = {
      # https://registry.terraform.io/providers/hashicorp/local/latest/docs
      source  = "hashicorp/local"
      version = ">= 2.1"
    }

    google = {
      # https://www.terraform.io/docs/providers/google/guides/provider_reference.html
      source  = "hashicorp/google"
      version = ">= 3.62"
    }
    google-beta = {
      # https://www.terraform.io/docs/providers/google/guides/provider_reference.html
      source  = "hashicorp/google-beta"
      version = ">= 3.62"
    }
  }
}

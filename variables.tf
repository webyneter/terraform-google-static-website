# ==================
# Required variables
# ==================

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

variable "bucket_service_account_private_key_dir_path" {
  description = "The file system path to the directory for the bucket's Service Account private key file"
  type        = string
}

# ==================
# Optional variables
# ==================

variable "website_index_page_file_name" {
  description = "The name of the website's index file"
  type        = string
  default     = "index.html"
}

# ========================================================================================
# Optional variables for backward compatibility with your system's  pre-existing resources
# ========================================================================================

variable "compat_website_external_ip_name" {
  description = "The optional name of the pre-existing External IP to facilitate backward compatibility"
  type        = string
  default     = null
}

variable "compat_website_ssl_certificate_name" {
  description = "The optional name of the pre-existing SSL/TLS certificate to facilitate backward compatibility"
  type        = string
  default     = null
}

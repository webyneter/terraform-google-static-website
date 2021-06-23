locals {
  website_url_map_path_name = "path"

  website_url_map_path_matcher = defaults(var.website_url_map_path_matcher, {
    path_rule_service = ""
  })
}

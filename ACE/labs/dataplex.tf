#// Define Dataplex datalake
resource "google_dataplex_lake" "data_lake" {
  name        = "ffot-lake"
  display_name = "FFOT-LAKE"
  description = "FFOT Dataplex lake"
  location = var.location
  project = var.project
}
#//Define zone as variables
variable "zone_names" {
  type    = list(string)
  default = ["gm360-raw", "gm360-core", "zone-pdl"]
}
#//create dataplex zones
resource "google_dataplex_zone" "data_zone" {
  for_each = toset(var.zone_names)
  name = each.value
  lake   = google_dataplex_lake.data_lake.name
  location = var.location
  type = "RAW"
  discovery_spec {
    enabled = false
  }
  resource_spec {
    location_type = "SINGLE_REGION"
  }
  project = var.project
}

variable "asset_names" {
  type    = list(string)
  default = ["gm360-raw", "gm360-core", "asset-pdl"]
}
variable "dataset_names" {
  type    = list(string)
  default = ["raw_gm360", "core_gm360", "gdl_layer"]
}

#// Define Dataplex asset
resource "google_dataplex_asset" "data_asset" {
  for_each = toset(var.asset_names)
  name     = each.value
  location = var.location
  description = "Dataplex asset for data processing"
  lake = google_dataplex_lake.data_lake.name
  dataplex_zone = google_dataplex_zone.data_zone[each.key].name

  discovery_spec {
    enabled = false
  }
  resource_spec {
    #for_each = toset(var.dataset_names)
    name = "/projects/var.project/datasets/raw_gm360"
    type = "BIGQUERY_DATASET"
  }
  project = var.project
}

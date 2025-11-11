/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  tables             = { for table in var.tables : table["table_id"] => table }
  # views              = { for view in var.views : view["view_id"] => view }
  # materialized_views = { for mat_view in var.materialized_views : mat_view["view_id"] => mat_view }
  # external_tables    = { for external_table in var.external_tables : external_table["table_id"] => external_table }
  # routines           = { for routine in var.routines : routine["routine_id"] => routine }

  iam_to_primitive = {
    "roles/bigquery.dataOwner" : "OWNER"
    "roles/bigquery.dataEditor" : "WRITER"
    "roles/bigquery.dataViewer" : "READER"
  }
}

resource "google_bigquery_dataset" "main" {
  dataset_id                      = var.dataset_id
  friendly_name                   = var.dataset_name
  description                     = var.description
  location                        = var.location
  delete_contents_on_destroy      = var.delete_contents_on_destroy
  default_table_expiration_ms     = var.default_table_expiration_ms
  max_time_travel_hours           = var.max_time_travel_hours
  storage_billing_model           = var.storage_billing_model
  project                         = var.project_id
  labels                          = var.dataset_labels
  resource_tags                   = var.resource_tags
  default_partition_expiration_ms = var.default_partition_expiration_ms

  dynamic "default_encryption_configuration" {
    for_each = var.encryption_key == null ? [] : [var.encryption_key]
    content {
      kms_key_name = var.encryption_key
    }
  }

  dynamic "access" {
    for_each = var.access
    content {
      # BigQuery API converts IAM to primitive roles in its backend.
      # This causes Terraform to show a diff on every plan that uses IAM equivalent roles.
      # Thus, do the conversion between IAM to primitive role here to prevent the diff.
      role = lookup(local.iam_to_primitive, access.value.role, access.value.role)

      # Additionally, using null as a default value would lead to a permanant diff
      # See https://github.com/hashicorp/terraform-provider-google/issues/4085#issuecomment-516923872
      domain         = lookup(access.value, "domain", "")
      group_by_email = lookup(access.value, "group_by_email", "")
      user_by_email  = lookup(access.value, "user_by_email", "")
      special_group  = lookup(access.value, "special_group", "")
    }
  }
}

resource "google_bigquery_table" "main" {
  for_each                 = local.tables
  dataset_id               = google_bigquery_dataset.main.dataset_id
  friendly_name            = each.value["table_name"] != null ? each.value["table_name"] : each.key
  table_id                 = each.key
  description              = each.value["description"]
  labels                   = each.value["labels"]
  schema                   = each.value["schema"]
  clustering               = each.value["clustering"]
  expiration_time          = each.value["expiration_time"] != null ? each.value["expiration_time"] : 0
  project                  = var.project_id
  deletion_protection      = coalesce(each.value["deletion_protection"], var.deletion_protection)
  require_partition_filter = each.value["require_partition_filter"]
  }



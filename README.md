# terraform-google-bigquery

This module allows you to create opinionated Google Cloud Platform BigQuery datasets and tables.
This will allow the user to programmatically create an empty table schema inside of a dataset, ready for loading.
Additional user accounts and permissions are necessary to begin querying the newly created table(s).

## Compatibility
This module is meant for use with Terraform 0.13+ and tested using Terraform 1.0+. If you find incompatibilities using Terraform >=0.13, please open an issue.
 If you haven't
[upgraded](https://www.terraform.io/upgrade-guides/0-13.html) and need a Terraform
0.12.x-compatible version of this module, the last released version
intended for Terraform 0.12.x is [v4.5.0](https://registry.terraform.io/modules/terraform-google-modules/-bigquery/google/v4.5.0).


## Usage

Basic usage of this module is as follows:

```hcl
module "bigquery" {
  source  = "terraform-google-modules/bigquery/google"
  version = "~> 10.2"

  dataset_id                  = "foo"
  dataset_name                = "foo"
  description                 = "some description"
  project_id                  = "<PROJECT ID>"
  location                    = "US"
  default_table_expiration_ms = 3600000
  resource_tags               = {"<PROJECT>/<TAG KEY>":"<TAG VALUE>"}

  tables = [
  {
    table_id           = "foo",
    schema             =  "<SCHEMA JSON DATA>",
    time_partitioning  = {
      type                     = "DAY",
      field                    = null,
      require_partition_filter = false,
      expiration_ms            = null,
    },
    range_partitioning = null,
    expiration_time = null,
    clustering      = ["fullVisitorId", "visitId"],
    labels          = {
      env      = "dev"
      billable = "true"
      owner    = "joedoe"
    },
  },
  {
    table_id           = "bar",
    schema             =  "<SCHEMA JSON DATA>",
    time_partitioning  = null,
    range_partitioning = {
      field = "customer_id",
      range = {
        start    = "1"
        end      = "100",
        interval = "10",
      },
    },
    expiration_time    = 2524604400000, # 2050/01/01
    clustering         = [],
    labels = {
      env      = "devops"
      billable = "true"
      owner    = "joedoe"
    }
  }
  ],

  views = [
    {
      view_id    = "barview",
      use_legacy_sql = false,
      query          = <<EOF
      SELECT
       column_a,
       column_b,
      FROM
        `project_id.dataset_id.table_id`
      WHERE
        approved_user = SESSION_USER
      EOF,
      labels = {
        env      = "devops"
        billable = "true"
        owner    = "joedoe"
      }
    }
  ]
  dataset_labels = {
    env      = "dev"
    billable = "true"
  }
}
```

Functional examples are included in the
[examples](./examples/) directory.

### Variable `tables` detailed description

The `tables` variable should be provided as a list of object with the following keys:
```hcl
{
  table_id = "some_id"                        # Unique table id (will be used as ID for table).
  table_name = "Friendly Name"                # Optional friendly name for table. If not set, the "table_id" will be used by default.
  schema = file("path/to/schema.json")        # Schema as JSON string.
  time_partitioning = {                       # Set it to `null` to omit partitioning configuration for the table.
        type                     = "DAY",     # The only type supported is DAY, which will generate one partition per day based on data loading time.
        field                    = null,      # The field used to determine how to create a time-based partition. If time-based partitioning is enabled without this value, the table is partitioned based on the load time. Set it to `null` to omit configuration.
        require_partition_filter = false,     # If set to true, queries over this table require a partition filter that can be used for partition elimination to be specified. Set it to `null` to omit configuration.
        expiration_ms            = null,      # Number of milliseconds for which to keep the storage for a partition.
      },
  range_partitioning = {                      # Set it to `null` to omit partitioning configuration for the table.
    field = "integer_column",                 # The column used to create the integer range partitions.
    range = {
      start    = "1"                          # The start of range partitioning, inclusive.
      end      = "100",                       # The end of range partitioning, exclusive.
      interval = "10",                        # The width of each range within the partition.
        },
      },
  clustering = ["fullVisitorId", "visitId"]   # Specifies column names to use for data clustering. Up to four top-level columns are allowed, and should be specified in descending priority order. Partitioning should be configured in order to use clustering.
  expiration_time = 2524604400000             # The time when this table expires, in milliseconds since the epoch. If set to `null`, the table will persist indefinitely.
  deletion_protection = true                  # Optional. Configures deletion_protection for the table. If unset, module-level deletion_protection setting will be used.
  labels = {                                  # A mapping of labels to assign to the table.
      env      = "dev"
      billable = "true"
    }
}
```

## Outputs

| Name | Description |
|------|-------------|
| bigquery\_dataset | Bigquery dataset resource. |
| bigquery\_tables | Map of bigquery table resources being provisioned. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

These sections describe requirements for using this module.

### Software

The following dependencies must be available:

- [Terraform](https://www.terraform.io/downloads.html) >= 0.13.0
- [Terraform Provider for GCP][terraform-provider-gcp] plugin v3

### Service Account

A service account with the following roles must be used to provision
the resources of this module:

- BigQuery Data Owner: `roles/bigquery.dataOwner`

The [Project Factory module][project-factory-module] and the
[IAM module][iam-module] may be used in combination to provision a
service account with the necessary roles applied.

#### Script Helper
A helper script for configuring a Service Account is located at (./helpers/setup-sa.sh).

### APIs

A project with the following APIs enabled must be used to host the
resources of this module:

- BigQuery JSON API: `bigquery-json.googleapis.com`

The [Project Factory module][project-factory-module] can be used to
provision a project with the necessary APIs enabled.

## Contributing

Refer to the [contribution guidelines](./CONTRIBUTING.md) for
information on contributing to this module.

[iam-module]: https://registry.terraform.io/modules/terraform-google-modules/iam/google
[project-factory-module]: https://registry.terraform.io/modules/terraform-google-modules/project-factory/google
[terraform-provider-gcp]: https://www.terraform.io/docs/providers/google/index.html
[terraform]: https://www.terraform.io/downloads.html

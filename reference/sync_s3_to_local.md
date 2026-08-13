# Sync S3 objects to a local directory

Downloads objects from an S3 prefix to a local directory using
`aws s3 sync`. Uses the same credential resolution as
[`connect_to_s3()`](https://ruralinnovation.github.io/cori.data.s3/reference/connect_to_s3.md):
local credentials if available, otherwise short-lived vended credentials
from the CORI credential-vending endpoint.

## Usage

``` r
sync_s3_to_local(
  bucket,
  prefix,
  local_path,
  region = "us-east-1",
  vending_url = default_vending_url(),
  extra_args = character(0)
)
```

## Arguments

- bucket:

  Character. S3 bucket name (without `s3://` prefix).

- prefix:

  Character. S3 key prefix within the bucket (e.g.,
  `"nbm_block-D25/state_abbr=NC/"`). Include trailing slash for
  directories.

- local_path:

  Character. Local directory path to sync to. Created if it does not
  exist.

- region:

  Character. AWS region for the bucket. Default: `"us-east-1"`.

- vending_url:

  Character. URL of the credential-vending endpoint. Only used when no
  local AWS credentials are configured. Defaults to the
  `"cori.data.vending_url"` option, then the `CORI_DATA_VENDING_URL`
  environment variable, then the deployed CORI endpoint.

- extra_args:

  Character vector. Additional arguments to pass to `aws s3 sync` (e.g.,
  `c("--delete", "--quiet")`). Default: `character(0)`.

## Value

Invisibly returns the exit status of the `aws s3 sync` command (0 on
success). Throws an error if the sync fails.

## Details

When vended credentials are used, they are temporarily injected as
environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
`AWS_SESSION_TOKEN`) for the duration of the sync, then restored.

Requires the AWS CLI (`aws`) to be installed and on the PATH.

## Examples

``` r
if (FALSE) { # \dontrun{
  sync_s3_to_local(
    bucket = "cori.data.fcc",
    prefix = "nbm_block-D25/state_abbr=NC/",
    local_path = file.path(tempdir(), "nbm_block-D25", "state_abbr=NC")
  )
} # }
```

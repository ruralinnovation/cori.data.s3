# Install aws credentials in your .Renviron file and load credentials into the current environment. This actions will overwrite any values currently stored in AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.

Install aws credentials in your .Renviron file and load credentials into
the current environment. This actions will overwrite any values
currently stored in AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.

## Usage

``` r
set_aws_credentials(
  keyID,
  secretAccessKey,
  region = "us-east-1",
  install = TRUE
)
```

## Arguments

- keyID:

  A valid Key ID

- secretAccessKey:

  A valid Access key

- region:

  A valid AWS region (default set )

- install:

  If TRUE, save credentials to .Renviron. Otherwise, set per session.

## Value

keyID, secretAccessKey and region, invisibly

## Examples

``` r

if (FALSE) { # \dontrun{
# Initilialize S3 credentials (this only needs to be done once for a given project)
cori.data.s3::set_aws_credentials(keyID = "###", secretAccessKey = "###")

# Open a duckdb connection configured for S3 access using the credentials
# just installed
con <- connect_to_s3("cori.data.bds")
} # }
```

# `cori.data.s3`

CORI functions used by cori.data.\* packages to connect to S3

![lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)

lifecycle

## Connecting to S3 via DuckDB

`connect_to_s3(bucket, region, vending_url)` opens a DuckDB connection
configured for S3 access, using the same local-then-vended credential
resolution as the S3 functions below.
[`has_local_aws_credentials()`](https://ruralinnovation.github.io/cori.data.s3/reference/has_local_aws_credentials.md)
checks whether local credentials are configured.

``` r

con <- cori.data::connect_to_s3("cori.data.bds")
# on.exit(DBI::dbDisconnect(con, shutdown = TRUE)) # ... if called inside a function

DBI::dbGetQuery(con, 
    "SELECT * FROM read_parquet('s3://cori.data.bds/**/*.parquet')")

# DBI::dbDisconnect(con, shutdown = TRUE) # ... if called outside a function
```

## S3 access functions

The other AWS S3 functions provided by this package are:
[`get_s3_object()`](https://ruralinnovation.github.io/cori.data.s3/reference/get_s3_object.md),
[`list_s3_objects()`](https://ruralinnovation.github.io/cori.data.s3/reference/list_s3_objects.md),
[`list_s3_buckets()`](https://ruralinnovation.github.io/cori.data.s3/reference/list_s3_buckets.md),
[`put_s3_object()`](https://ruralinnovation.github.io/cori.data.s3/reference/put_s3_object.md),
[`put_s3_objects_recursive()`](https://ruralinnovation.github.io/cori.data.s3/reference/put_s3_objects_recursive.md),
[`read_s3_object()`](https://ruralinnovation.github.io/cori.data.s3/reference/read_s3_object.md),
[`write_s3_object()`](https://ruralinnovation.github.io/cori.data.s3/reference/write_s3_object.md),
[`set_aws_credentials()`](https://ruralinnovation.github.io/cori.data.s3/reference/set_aws_credentials.md).

Reads
([`get_s3_object()`](https://ruralinnovation.github.io/cori.data.s3/reference/get_s3_object.md),
[`list_s3_objects()`](https://ruralinnovation.github.io/cori.data.s3/reference/list_s3_objects.md),
[`read_s3_object()`](https://ruralinnovation.github.io/cori.data.s3/reference/read_s3_object.md))
use local AWS credentials when available (env vars or
`~/.aws/credentials`), and otherwise fall back to temporary, read-only
credentials from the CORI credential-vending endpoint — no local AWS
setup required. Writes
([`put_s3_object()`](https://ruralinnovation.github.io/cori.data.s3/reference/put_s3_object.md),
[`put_s3_objects_recursive()`](https://ruralinnovation.github.io/cori.data.s3/reference/put_s3_objects_recursive.md),
[`write_s3_object()`](https://ruralinnovation.github.io/cori.data.s3/reference/write_s3_object.md))
and
[`list_s3_buckets()`](https://ruralinnovation.github.io/cori.data.s3/reference/list_s3_buckets.md)
always require local credentials, since vended credentials are
read-only.

Note: These functions were moved here from the `cori.db` package, also
part of the
[coriverse](https://github.com/ruralinnovation/coriverse/wiki).

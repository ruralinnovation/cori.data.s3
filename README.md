`cori.data.s3`
==============

CORI functions used by cori.data.* packages to connect to S3

![lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)

## Connecting to S3 via DuckDB

`connect_to_s3(bucket, region, vending_url)` opens a DuckDB connection configured for S3 access, using the same local-then-vended credential resolution as the S3 functions below. `has_local_aws_credentials()` checks whether local credentials are configured.

```r
con <- cori.data::connect_to_s3("cori.data.bds")
# on.exit(DBI::dbDisconnect(con, shutdown = TRUE)) # ... if called inside a function

DBI::dbGetQuery(con, 
    "SELECT * FROM read_parquet('s3://cori.data.bds/**/*.parquet')")

# DBI::dbDisconnect(con, shutdown = TRUE) # ... if called outside a function
```

## S3 access functions

The other AWS S3 functions provided by this package are: `get_s3_object()`, `list_s3_objects()`, `list_s3_buckets()`, `put_s3_object()`, `put_s3_objects_recursive()`, `read_s3_object()`, `write_s3_object()`, `set_aws_credentials()`.

Reads (`get_s3_object()`, `list_s3_objects()`, `read_s3_object()`) use local AWS credentials when available (env vars or `~/.aws/credentials`), and otherwise fall back to temporary, read-only credentials from the CORI credential-vending endpoint — no local AWS setup required. Writes (`put_s3_object()`, `put_s3_objects_recursive()`, `write_s3_object()`) and `list_s3_buckets()` always require local credentials, since vended credentials are read-only.

Note: These functions were moved here from the `cori.db` package, also part of the [coriverse](https://github.com/ruralinnovation/coriverse/wiki).

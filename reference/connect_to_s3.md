# Open a DuckDB connection configured for S3 access

Creates a DuckDB connection with the `httpfs` and `aws` extensions
loaded and an S3 secret configured. This is the shared connection
utility for `cori.data.*` packages, so S3/DuckDB setup lives in one
place instead of being duplicated in each package's `read_*_from_s3()`
function.

## Usage

``` r
connect_to_s3(
  bucket,
  region = "us-east-1",
  vending_url = default_vending_url(),
  require_local = FALSE,
  dbdir = ":memory:",
  caller = NULL
)
```

## Arguments

- bucket:

  Character. S3 bucket to request vended credentials for. Required when
  falling back to the vending endpoint.

- region:

  Character. AWS region for the S3 secret. Default: `"us-east-1"`.

- vending_url:

  Character. URL of the credential-vending endpoint. Only used when no
  local AWS credentials are configured. Defaults to the
  `"cori.data.vending_url"` option, then the `CORI_DATA_VENDING_URL`
  environment variable, then the deployed CORI endpoint.

- require_local:

  Logical. If `TRUE`, error immediately when no local AWS credentials
  are configured instead of falling back to (read-only) vended
  credentials. Use this for connections that will write to S3. Default:
  `FALSE`.

- dbdir:

  Character. Path to a persistent DuckDB database file. Default
  `":memory:"` opens an in-memory instance, matching prior behavior.
  Pass a file path for callers that need the catalog/temp state to
  persist across a script run.

- caller:

  Character. Identifies this connection in the vending endpoint's
  session name and, downstream, in S3 server access log reports
  (CLOSE_THE_GAP.md).

  Has no default. When omitted, it is resolved from the ambient AWS
  identity (`sts:GetCallerIdentity`, reduced to the bare user or role
  name); if no identity is available, no tag is sent and the endpoint
  applies its own `anon` default.

  Only meaningful on the vending path. On the local-credentials path the
  caller's own IAM identity is already what S3 records in the access
  log's `requester` field, so no tag is needed and no lookup is
  performed. The lookup is cached for the session.

  The endpoint truncates this to 20 characters when building the session
  name, so pass a short explicit value where distinguishing
  similarly-named callers matters.

## Value

An open `duckdb_connection`. The caller owns the connection and must
disconnect it, e.g. `on.exit(DBI::dbDisconnect(con, shutdown = TRUE))`.

## Details

Credentials are resolved in two ways, in order:

1.  If
    [`has_local_aws_credentials()`](https://ruralinnovation.github.io/cori.data.s3/reference/has_local_aws_credentials.md)
    finds credentials in the environment or `~/.aws/credentials`, the
    connection uses the caller's own identity via
    `PROVIDER CREDENTIAL_CHAIN` — no network round-trip.

2.  Otherwise, short-lived read-only credentials for `bucket` are
    fetched from `vending_url` and installed directly as a static
    secret.

`bucket` is only used for the vending path, where the endpoint requires
it; it is ignored when local credentials are present. Vended credentials
are read-only (across the allowlisted `cori.data.*` buckets), so writes
through this connection require local credentials – pass
`require_local = TRUE` to fail fast with a clear message instead of
getting an opaque S3 access-denied error mid-query.

## Examples

``` r
if (FALSE) { # \dontrun{
  con <- connect_to_s3("cori.data.bds")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  DBI::dbGetQuery(con, "SELECT * FROM read_parquet('s3://cori.data.bds/**/*.parquet')")
} # }
```

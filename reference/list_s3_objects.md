# List every "keys" from a bucket

List every "keys" from a bucket

## Usage

``` r
list_s3_objects(bucket_name, prefix = NULL)
```

## Arguments

- bucket_name:

  string, example "test-coridata""

- prefix:

  optional string. When supplied, only keys beginning with this prefix
  are requested, using the `Prefix` parameter of S3's `list_objects_v2`
  so the filtering happens server-side. When `NULL` (the default) every
  key in the bucket is returned, which is the original behaviour.
  Scoping matters on buckets that hold large unrelated prefixes (e.g.
  server access logs): an unscoped call paginates the whole bucket.

## Value

a data frame with a key and last_modified columns. Zero rows, with both
columns still present, when nothing matches.

## Examples

``` r

if (FALSE) { # \dontrun{
 s3_asset <- list_bucket("test-coridata")
 s3_asset <- list_s3_objects("test-coridata", prefix = "dev/content/")
} # }
```

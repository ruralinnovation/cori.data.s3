# List every "keys" from a bucket

List every "keys" from a bucket

## Usage

``` r
list_s3_objects(bucket_name)
```

## Arguments

- bucket_name:

  string, example "test-coridata""

## Value

a data frame with a key and last_modified columns

## Examples

``` r

if (FALSE) { # \dontrun{
 s3_asset <- list_bucket("test-coridata")
} # }
```

# put files from a local directory into an S3 bucket

put files from a local directory into an S3 bucket

## Usage

``` r
put_s3_objects_recursive(bucket_name, s3_key_prefix, dir_path, ...)
```

## Arguments

- bucket_name:

  string, a bucket name

- s3_key_prefix:

  string, name of the prefix (directory path) used within the S3 bucket

- dir_path:

  string, local directory path containing the files that you want to
  upload

- ...:

  other arguments to paws's put_object()

## Value

return invisibly the response from AWS

## Examples

``` r

if (FALSE) { # \dontrun{
 txt <- put_s3_objects_recursive("test-coridata", "test/blabla.txt" ,"test")
} # }
```

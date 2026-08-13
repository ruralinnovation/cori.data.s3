# put a local file into an S3 bucket

put a local file into an S3 bucket

## Usage

``` r
put_s3_object(bucket_name, s3_key_path, file_path, ...)
```

## Arguments

- bucket_name:

  string, S3 bucket name

- s3_key_path:

  string, intended path + name of the file within S3 bucket

- file_path:

  string, local path + name of the file that you want to upload

- ...:

  other arguments to paws's put_object()

## Value

return invisibly the response from AWS

## Examples

``` r

if (FALSE) { # \dontrun{
 txt <- put_s3_object("test-coridata", "blabla.txt" ,"blabla.txt")
} # }
```

# write a data.frame into a csv in a s3 bucket

write a data.frame into a csv in a s3 bucket

## Usage

``` r
write_s3_object(bucket_name, s3_key_path, data_frame, ...)
```

## Arguments

- bucket_name:

  string, a bucket name

- s3_key_path:

  string, intended path + name of the file within S3 bucket

- data_frame:

  an R object of class "data.frame", sf object are excluded

- ...:

  extra argument to pass on write.csv()

## Value

return invisibly the response from AWS

## Details

it is using tempfile() shenanigans

## Examples

``` r

if (FALSE) { # \dontrun{
 write_s3_object("test-coridata", "test-messy-data/cars.csv", cars)
} # }
```

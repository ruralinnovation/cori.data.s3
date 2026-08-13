# read a text file (csv) in a s3 object in memory

read a text file (csv) in a s3 object in memory

## Usage

``` r
read_s3_object(bucket_name, key, ...)
```

## Arguments

- bucket_name:

  string, a bucket name

- key:

  string, object/file that you want to download

- ...:

  extra argument to pass on read.csv()

## Value

return a data frame

## Details

works only for content type

## Examples

``` r

if (FALSE) { # \dontrun{
 my_csv <- read_s3_object("test-coridata", "data-1715776270877.csv")
} # }
```

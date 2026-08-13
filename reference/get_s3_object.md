# Download an object that is hosted on S3

Download an object that is hosted on S3

## Usage

``` r
get_s3_object(
  bucket_name,
  key,
  dir_path,
  key_path = "",
  create_local_directory = FALSE,
  ...
)
```

## Arguments

- bucket_name:

  string, a bucket name

- key:

  string, object/file that you want to download (e.g, county_data.csv)

- dir_path:

  string, a directory path to which you want the file to be downloaded
  ("~/Documents/my_proj/")

- key_path:

  string, path to your key in the s3 bucket (e.g., "raw/" if you want to
  retrieve `s3://[bucket_name]/raw/county_data.csv`)

- create_local_directory:

  logical, TRUE or FALSE to create a directory at dir_path if none
  exists (defaults to FALSE)

- ...:

  other arguments from paws's downloadfile

## Value

return invisibly the path where the file has been downloaded

## Details

If dir_path is not provided, the object will be saved in the current
directory

## Examples

``` r

if (FALSE) { # \dontrun{
 txt <- get_s3_object("test-coridata", "county_data.csv", "proj_data/", key_path = "raw/")
 txt
} # }
```

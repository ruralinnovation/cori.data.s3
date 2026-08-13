# Package index

## Connection

Establish S3 connections with credential handling

- [`connect_to_s3()`](https://ruralinnovation.github.io/cori.data.s3/reference/connect_to_s3.md)
  : Open a DuckDB connection configured for S3 access
- [`has_local_aws_credentials()`](https://ruralinnovation.github.io/cori.data.s3/reference/has_local_aws_credentials.md)
  : Detect locally configured AWS credentials
- [`set_aws_credentials()`](https://ruralinnovation.github.io/cori.data.s3/reference/set_aws_credentials.md)
  : Install aws credentials in your .Renviron file and load credentials
  into the current environment. This actions will overwrite any values
  currently stored in AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.

## Read Operations

- [`get_s3_object()`](https://ruralinnovation.github.io/cori.data.s3/reference/get_s3_object.md)
  : Download an object that is hosted on S3
- [`read_s3_object()`](https://ruralinnovation.github.io/cori.data.s3/reference/read_s3_object.md)
  : read a text file (csv) in a s3 object in memory
- [`list_s3_objects()`](https://ruralinnovation.github.io/cori.data.s3/reference/list_s3_objects.md)
  : List every "keys" from a bucket
- [`list_s3_buckets()`](https://ruralinnovation.github.io/cori.data.s3/reference/list_s3_buckets.md)
  : Listing s3 bucket CORI draft
- [`sync_s3_to_local()`](https://ruralinnovation.github.io/cori.data.s3/reference/sync_s3_to_local.md)
  : Sync S3 objects to a local directory

## Write Operations

- [`write_s3_object()`](https://ruralinnovation.github.io/cori.data.s3/reference/write_s3_object.md)
  : write a data.frame into a csv in a s3 bucket
- [`put_s3_object()`](https://ruralinnovation.github.io/cori.data.s3/reference/put_s3_object.md)
  : put a local file into an S3 bucket
- [`put_s3_objects_recursive()`](https://ruralinnovation.github.io/cori.data.s3/reference/put_s3_objects_recursive.md)
  : put files from a local directory into an S3 bucket

# Exercises the credential fallback logic itself, with no network calls:
# has_local_aws_credentials() and .fetch_vended_credentials() are mocked.

test_that("vended path builds a client from fetched credentials", {
  local_mocked_bindings(
    has_local_aws_credentials = function() FALSE,
    .fetch_vended_credentials = function(vending_url, bucket, caller = NULL) {
      list(
        access_key_id     = "FAKEKEYID",
        secret_access_key = "fakesecret",
        session_token     = "faketoken"
      )
    }
  )

  client <- get_s3_client("some.bucket")

  expect_true(is.list(client))
  expect_true(all(c("get_object", "list_objects_v2") %in% names(client)))
})

test_that("caller falls back to the ambient AWS identity when not supplied", {
  captured_caller <- NULL

  local_mocked_bindings(
    has_local_aws_credentials = function() FALSE,
    .aws_identity_name        = function() "SomeInstanceRole",
    .fetch_vended_credentials = function(vending_url, bucket, caller = NULL) {
      captured_caller <<- caller
      list(
        access_key_id     = "FAKEKEYID",
        secret_access_key = "fakesecret",
        session_token     = "faketoken"
      )
    }
  )

  get_s3_client("some.bucket")

  expect_equal(captured_caller, "SomeInstanceRole")
})

test_that("no caller is sent when there is no ambient identity to resolve", {
  captured_caller <- "sentinel"

  local_mocked_bindings(
    has_local_aws_credentials = function() FALSE,
    .aws_identity_name        = function() NA_character_,
    .fetch_vended_credentials = function(vending_url, bucket, caller = NULL) {
      captured_caller <<- caller
      list(
        access_key_id     = "FAKEKEYID",
        secret_access_key = "fakesecret",
        session_token     = "faketoken"
      )
    }
  )

  get_s3_client("some.bucket")

  # NULL, not "" -- .fetch_vended_credentials() drops the query parameter
  # entirely so the endpoint applies its own "anon" default.
  expect_null(captured_caller)
})

test_that("an explicit caller takes precedence over the ambient identity", {
  captured_caller <- NULL

  local_mocked_bindings(
    has_local_aws_credentials = function() FALSE,
    .aws_identity_name        = function() "SomeInstanceRole",
    .fetch_vended_credentials = function(vending_url, bucket, caller = NULL) {
      captured_caller <<- caller
      list(
        access_key_id     = "FAKEKEYID",
        secret_access_key = "fakesecret",
        session_token     = "faketoken"
      )
    }
  )

  get_s3_client("some.bucket", caller = "quarterly-refresh")

  expect_equal(captured_caller, "quarterly-refresh")
})

test_that(".aws_identity_name reduces each ARN shape to a bare name", {
  shapes <- list(
    "arn:aws:iam::312512371189:user/jhall"                        = "jhall",
    "arn:aws:iam::312512371189:role/SomeRole"                     = "SomeRole",
    "arn:aws:sts::312512371189:assumed-role/SomeRole/i-abc123"    = "SomeRole"
  )

  for (arn in names(shapes)) {
    .clear_identity_cache()
    local_mocked_bindings(
      .sts_caller_arn = function() arn
    )
    expect_equal(.aws_identity_name(), shapes[[arn]], info = arn)
  }

  .clear_identity_cache()
  local_mocked_bindings(.sts_caller_arn = function() NULL)
  expect_true(is.na(.aws_identity_name()))

  .clear_identity_cache()
})

test_that("get_s3_client passes an explicit caller through to the vending endpoint", {
  captured_caller <- NULL

  local_mocked_bindings(
    has_local_aws_credentials = function() FALSE,
    .fetch_vended_credentials = function(vending_url, bucket, caller = NULL) {
      captured_caller <<- caller
      list(
        access_key_id     = "FAKEKEYID",
        secret_access_key = "fakesecret",
        session_token     = "faketoken"
      )
    }
  )

  get_s3_client("some.bucket", caller = "my-pipeline")

  expect_equal(captured_caller, "my-pipeline")
})

test_that("require_local stops with the read-only message when no local creds", {
  local_mocked_bindings(
    has_local_aws_credentials = function() FALSE
  )

  expect_error(get_s3_client(require_local = TRUE), "read-only")
})

test_that("vended path without a bucket stops with the bucket-required message", {
  local_mocked_bindings(
    has_local_aws_credentials = function() FALSE
  )

  expect_error(get_s3_client(), "'bucket' is required")
})

test_that("local path returns a client without touching the vending endpoint", {
  local_mocked_bindings(
    has_local_aws_credentials = function() TRUE,
    .fetch_vended_credentials = function(vending_url, bucket, caller = NULL) {
      stop("vending endpoint should not be called on the local path")
    }
  )

  client <- get_s3_client("some.bucket")

  expect_true(is.list(client))
  expect_true(all(c("get_object", "list_objects_v2") %in% names(client)))
})

test_that("default_vending_url precedence: option, then env var, then deployed default", {
  withr::local_options(cori.data.vending_url = "https://example.test/opt")
  expect_equal(default_vending_url(), "https://example.test/opt")

  withr::local_options(cori.data.vending_url = NULL)
  withr::local_envvar(CORI_DATA_VENDING_URL = "https://example.test/env")
  expect_equal(default_vending_url(), "https://example.test/env")

  withr::local_envvar(CORI_DATA_VENDING_URL = "")
  expect_equal(default_vending_url(), "https://data.ruralinnovation.us/credentials")
})

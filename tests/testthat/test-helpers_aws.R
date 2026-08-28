# Tests for R/helpers_aws.R
#
# These are live-network tests against the `cori-risi-apps` bucket. They are
# read-only: is_key_already_here() only lists keys, it never writes. They skip
# when no local AWS credentials are configured.
#
# The fixtures below pin down the *exact-match* contract of
# is_key_already_here(): it must return TRUE only when `key` is present
# verbatim, never merely because `key` is a prefix of some other key. In
# `cori-risi-apps`:
#
#   aws-amplify-core.js       exists
#   aws-amplify-core.js.map   exists, and has the above as a strict prefix
#   aws-amplify-core.j        does NOT exist, but is a prefix of both
#
# The third case is the one that matters. The current implementation lists the
# whole bucket and then filters with `%in%`, so prefix collisions are
# structurally impossible. Any future implementation that narrows the listing
# server-side (e.g. passing `Prefix =` to list_objects_v2) will start seeing
# neighbouring keys in its result set, and must still match exactly.
#
# If these fixtures are ever removed from the bucket, the first two tests fail
# rather than skip -- the premise is gone and the test needs new fixtures.

test_bucket <- "cori-risi-apps"

key_present   <- "aws-amplify-core.js"        # exists verbatim
key_prefix_of <- "aws-amplify-core.j"         # prefixes two real keys, is not a key
key_absent    <- "zzz-no-such-key-9f3a2b.tmp" # matches nothing

test_that("is_key_already_here() returns TRUE for a key that exists", {
  skip_if_not(has_local_aws_credentials(), "No local AWS credentials")

  expect_true(
    suppressMessages(is_key_already_here(test_bucket, key_present))
  )
})

test_that("is_key_already_here() names the pre-existing key in its message", {
  skip_if_not(has_local_aws_credentials(), "No local AWS credentials")

  expect_message(
    is_key_already_here(test_bucket, key_present),
    key_present,
    fixed = TRUE
  )
})

test_that("is_key_already_here() matches exactly, not by prefix", {
  skip_if_not(has_local_aws_credentials(), "No local AWS credentials")

  # `key_prefix_of` is a prefix of both aws-amplify-core.js and
  # aws-amplify-core.js.map, but is not itself a key. Matching must stay exact.
  expect_false(
    suppressMessages(is_key_already_here(test_bucket, key_prefix_of))
  )
})

test_that("is_key_already_here() returns FALSE, silently, for a key that matches nothing", {
  skip_if_not(has_local_aws_credentials(), "No local AWS credentials")

  # Also exercises the empty-result path: no key in the bucket shares this
  # prefix, so a scoped listing would return zero rows here.
  expect_false(
    suppressMessages(is_key_already_here(test_bucket, key_absent))
  )
  expect_no_message(is_key_already_here(test_bucket, key_absent))
})

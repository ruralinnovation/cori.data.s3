# Internal: resolve the credential-vending endpoint URL. Precedence:
# the "cori.data.vending_url" option, then the CORI_DATA_VENDING_URL
# environment variable, then the deployed default. Callers can override
# per-call via the vending_url argument.
default_vending_url <- function() {
  url <- getOption("cori.data.vending_url")
  if (!is.null(url) && is.character(url) && nzchar(url)) return(url)

  url <- Sys.getenv("CORI_DATA_VENDING_URL")
  if (nzchar(url)) return(url)

  "https://data.ruralinnovation.us/credentials"
}


# Internal: session-scoped cache for the ambient AWS identity lookup, so a
# script that opens many connections pays the STS round-trip once rather
# than per call. A failed lookup is cached as NA too -- on a machine with no
# credentials at all the failure costs ~1.2s, and there is no reason to
# repeat it. Stale if credentials change mid-session; call
# .clear_identity_cache() in that (rare) case.
.identity_cache <- new.env(parent = emptyenv())

.clear_identity_cache <- function() {
  rm(list = ls(.identity_cache), envir = .identity_cache)
  invisible(NULL)
}


# Internal: best-effort read of whatever AWS identity the ambient provider
# chain can see, reduced to a bare user or role name.
#
# This is deliberately *not* the same question has_local_aws_credentials()
# asks. That function checks only env vars and ~/.aws/credentials, so an EC2
# instance profile, ECS task role, or SSO session falls through to the
# vending path -- yet paws can still resolve an identity for those callers.
# That is the case this exists to serve: it recovers a meaningful caller tag
# for automated infrastructure that would otherwise vend as "anon".
#
# Returns NA_character_ when no identity is available (the true
# no-credentials case), which callers treat as "send no caller tag."
#
#   arn:aws:iam::123:user/jhall                     -> "jhall"
#   arn:aws:iam::123:role/SomeRole                  -> "SomeRole"
#   arn:aws:sts::123:assumed-role/SomeRole/session  -> "SomeRole"

# Internal: the network call itself, split out from the parsing below so the
# ARN-shape handling can be tested without mocking paws internals. Returns
# NULL when no credentials are resolvable.
.sts_caller_arn <- function() {
  tryCatch(
    paws.security.identity::sts()$get_caller_identity()$Arn,
    error = function(e) NULL
  )
}


.aws_identity_name <- function() {
  if (!is.null(.identity_cache$name)) return(.identity_cache$name)

  arn <- .sts_caller_arn()

  name <- NA_character_
  if (!is.null(arn) && is.character(arn) && nzchar(arn)) {
    # Strip the arn:partition:service:region:account: prefix, leaving the
    # resource portion (e.g. "assumed-role/SomeRole/session").
    resource <- sub("^arn:[^:]*:[^:]*:[^:]*:[^:]*:", "", arn)
    parts <- strsplit(resource, "/", fixed = TRUE)[[1]]
    if (length(parts) >= 2 && nzchar(parts[2])) name <- parts[2]
  }

  .identity_cache$name <- name
  name
}


# Internal: decide what caller tag to send to the vending endpoint.
#
# Precedence: an explicit caller argument, then the ambient AWS identity,
# then nothing (the endpoint applies its own "anon" default).
#
# Note the vending endpoint sanitizes and truncates this to 20 characters
# when building the RoleSessionName, so long role names are cut short --
# distinct callers whose names share a 20-character prefix will not be
# distinguishable in access-log reports. Pass an explicit, short `caller`
# where that matters.
.resolve_caller <- function(caller = NULL) {
  if (!is.null(caller) && is.character(caller) && nzchar(caller)) return(caller)

  name <- .aws_identity_name()
  if (!is.na(name)) return(name)

  NULL
}


# Internal: build a paws.storage S3 client using the same credential
# resolution as connect_to_s3():
#
# 1. If has_local_aws_credentials() finds credentials in the environment or
#    ~/.aws/credentials, return a client on the caller's own identity via
#    paws's ambient provider chain.
# 2. Otherwise fetch short-lived vended credentials from the vending
#    endpoint and inject them as static credentials. Vended credentials are
#    read-only (across the allowlisted cori.data.* buckets), so operations
#    that write to S3 or make account-wide calls must pass
#    require_local = TRUE to fail here with a clear message instead of an
#    opaque AccessDenied later.
#
# `caller` is forwarded to the vending endpoint's session name, and from
# there into S3 server access log reports (CLOSE_THE_GAP.md) -- see
# connect_to_s3()'s `caller` parameter for the full explanation. It has no
# default: when omitted it is resolved from the ambient AWS identity, and
# only on the vending path (on the local path the caller's own IAM identity
# is already what appears in the access log, so no tag is needed and no STS
# round-trip is spent).
get_s3_client <- function(bucket = NULL, region = "us-east-1",
                          vending_url = default_vending_url(),
                          require_local = FALSE,
                          caller = NULL) {

  if (has_local_aws_credentials()) {
    return(paws.storage::s3(config = list(region = region)))
  }

  if (require_local) {
    stop("No local AWS credentials found. Vended credentials are read-only ",
         "(across the allowlisted cori.data.* buckets), so this operation ",
         "requires local AWS credentials. Run set_aws_credentials() or ",
         "configure the AWS CLI.", call. = FALSE)
  }

  if (is.null(bucket) || !is.character(bucket) || !nzchar(bucket)) {
    stop("No local AWS credentials found; a 'bucket' is required to request ",
         "vended credentials.", call. = FALSE)
  }

  if (is.null(vending_url) || !is.character(vending_url) || !nzchar(vending_url)) {
    stop("No local AWS credentials found and no 'vending_url' supplied. ",
         "Configure AWS credentials, or pass the credential-vending ",
         "endpoint URL.", call. = FALSE)
  }

  creds <- .fetch_vended_credentials(
    vending_url, bucket, caller = .resolve_caller(caller)
  )

  paws.storage::s3(config = list(
    credentials = list(
      creds = list(
        access_key_id     = creds$access_key_id,
        secret_access_key = creds$secret_access_key,
        session_token     = creds$session_token
      )
    ),
    region = region
  ))
}


# from https://adv-r.hadley.nz/conditions.html
fail_with <- function(expr, value = NULL) {
  tryCatch(
    error = function(cnd) value,
    expr
  )
}

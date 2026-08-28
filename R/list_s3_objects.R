#' List every "keys" from a bucket
#'
#' @param bucket_name string, example "test-coridata""
#' @param prefix optional string. When supplied, only keys beginning with this
#'   prefix are requested, using the `Prefix` parameter of S3's
#'   `list_objects_v2` so the filtering happens server-side. When `NULL` (the
#'   default) every key in the bucket is returned, which is the original
#'   behaviour. Scoping matters on buckets that hold large unrelated prefixes
#'   (e.g. server access logs): an unscoped call paginates the whole bucket.
#'
#' @return a data frame with a key and last_modified columns. Zero rows, with
#'   both columns still present, when nothing matches.
#'
#' @export
#'
#' @examples
#'
#' \dontrun{
#'  s3_asset <- list_bucket("test-coridata")
#'  s3_asset <- list_s3_objects("test-coridata", prefix = "dev/content/")
#' }
#'

list_s3_objects <- function(bucket_name, prefix = NULL) {

  # convenience functions
  gimme_me_key <- function(x) x[["Key"]]
  gimme_me_last_modified <- function(x) x[["LastModified"]]

  s3 <- get_s3_client(bucket_name)

  # `Prefix` already defaults to NULL in paws and is dropped from the request
  # when NULL, so this single call covers both the scoped and unscoped cases --
  # no branching needed. paginate() captures this expression unevaluated
  # (substitute()) and re-evaluates it in this frame, so `prefix` resolves here.
  n_page <- paws.storage::paginate(
    s3$list_objects_v2(Bucket = bucket_name, Prefix = prefix)
  )

  flatten_one_level <- unlist(n_page, recursive = FALSE)
  get_content <-  unlist(
    flatten_one_level[names(flatten_one_level) == "Contents"],
    recursive = FALSE, use.names = FALSE)

  # A listing that matches nothing is routine once `prefix` is in play (e.g.
  # checking whether a not-yet-uploaded key exists), where it was near
  # unreachable before. Return a well-formed empty frame: data.frame() drops
  # NULL arguments, so the naive path below would silently yield a 0x1 frame
  # with no `key` column, breaking callers that do `filter(grepl(x, key))`.
  if (length(get_content) == 0) {
    return(data.frame(
      key           = character(0),
      last_modified = as.POSIXct(character(0)),
      stringsAsFactors = FALSE
    ))
  }

  df_temp <- data.frame(
    key = do.call(rbind, lapply(get_content, gimme_me_key)),
    last_modified = as.POSIXlt(do.call(rbind,
                                       lapply(get_content,
                                              gimme_me_last_modified)))
  )
  return(df_temp)
}

# Monitoring S3 access

Every request to a CORI data bucket is written to an S3 server access
log. This vignette turns those logs into charts: who is downloading
what, from which bucket, and how that changes over time.

## Where the logs live

Server access logging is enabled on every allowlisted bucket except
`cori.data.verse`, which is the destination. Log objects land under a
date-partitioned prefix that encodes both the source bucket and the day:

    s3://cori.data.verse/logs/312512371189/us-east-1/<bucket>/YYYY/MM/DD/<file>

That layout matters for performance. Narrowing the glob to the months
you care about is what keeps a query reading megabytes instead of the
full history — there are hundreds of thousands of small log objects.

``` r

library(cori.data.s3)
library(cori.charts)
library(dplyr)
library(purrr)
library(ggplot2)
library(scales)

load_fonts()
```

## Reading the logs

Access logs are space-delimited with a bracketed timestamp and a quoted
request URI, so they are parsed with a single regular expression rather
than a CSV reader. The important discipline is to aggregate inside
DuckDB and return only a small summary to R — never pull raw log lines
into memory.

``` r

buckets <- c(
  "cori.data.bds",
  "cori.data.bfs",
  "cori.data.bps",
  "cori.data.fcc",
  "cori.data.hu",
  "cori.data.pep",
  "cori.data.qcew",
  "ruraldefinitions"
)

log_pattern <- paste0(
  "^(\\S+) (\\S+) \\[([^\\]]+)\\] (\\S+) (\\S+) (\\S+) (\\S+) (\\S+) ",
  "\"[^\"]*\" (\\S+) (\\S+) (\\S+)"
)

query_template <- "
  WITH raw AS (
    SELECT regexp_extract(line, '%s',
      ['owner','bucket','ts','ip','requester','reqid',
       'operation','key','status','err','bytes']) AS f
    FROM read_csv('%s', delim='\\x01', header = false,
                  columns = {'line': 'VARCHAR'})
  )
  SELECT
    f.bucket                                                   AS bucket,
    CAST(strptime(split_part(f.ts, ' ', 1),
                  '%%d/%%b/%%Y:%%H:%%M:%%S') AS DATE)          AS day,
    CASE
      WHEN f.requester = '-' THEN 'anonymous'
      WHEN f.requester LIKE '%%CoriDataS3ReaderRole%%'
        THEN coalesce(nullif(nullif(regexp_extract(
               split_part(f.requester, '/', 3),
               '^coridata-(.*)-[0-9]+$', 1), ''), 'anon'), 'anonymous')
      ELSE 'local credentials'
    END                                                        AS caller,
    COUNT(*)                                                   AS requests,
    SUM(TRY_CAST(f.bytes AS BIGINT))                           AS bytes
  FROM raw
  WHERE f.operation LIKE 'REST.GET.OBJECT%%'
  GROUP BY 1, 2, 3
"

activity <- list()

for (b in buckets) {

  # One glob per day for the past week — each query hits a single
  # bucket/date prefix, which is what keeps a query inside the vended
  # credential's lifetime.
  dates <- seq(Sys.Date() - 7, Sys.Date(), by = "day")
  globs <- sprintf(
    "s3://cori.data.verse/logs/312512371189/us-east-1/%s/%s/*",
    b, format(dates, "%Y/%m/%d")
  )

  bucket_activity <- purrr::map(globs, \(g) {
    con <- connect_to_s3("cori.data.verse")
    # NOTE: on.exit() only defers to the exit of an enclosing *function*
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

    # A quiet bucket/day legitimately has no log objects, and read_csv()
    # raises an IO Error rather than returning zero rows when its glob
    # matches nothing. glob() returns zero rows instead of erroring, so it
    # is the guard -- one LIST request on the connection that is already
    # authenticated, rather than a second client with its own credentials.
    found <- DBI::dbGetQuery(
      con, sprintf("SELECT count(*) AS n FROM glob('%s')", g)
    )$n

    if (found > 0) {
      DBI::dbGetQuery(con, sprintf(query_template, log_pattern, g))
    } else {
      return(NULL)
    }
  })

  # Appends this bucket's per-day data frames as elements, keeping `activity`
  # a flat list for bind_rows() below. This relies on map() returning a plain
  # list: a data frame is itself a list of columns, so c() would splice one
  # column-by-column rather than appending it whole.
  activity <- c(activity, bucket_activity)
}

activity <- activity |>
  dplyr::bind_rows() |>
  dplyr::filter(
    bucket %in% buckets
  )

glimpse(activity)
#> Rows: 72
#> Columns: 5
#> $ bucket   <chr> "cori.data.bds", "cori.data.bds", "cori.data.bds", "cori.data…
#> $ day      <date> 2026-08-24, 2026-08-25, 2026-08-26, 2026-08-27, 2026-08-28, …
#> $ caller   <chr> "local credentials", "local credentials", "local credentials"…
#> $ requests <dbl> 376, 190, 2, 563, 529, 2, 2, 2, 365, 2, 2, 2, 2, 2, 2, 2, 2, …
#> $ bytes    <dbl> 36378558, 18205991, 736, 54567469, 48354171, 26, 736, 736, 34…
```

One row per bucket, day, and caller. Everything below is `dplyr` on that
frame — the expensive work is already done.

## Downloads over time, by bucket

``` r

activity |>
  filter(day >= Sys.Date() - 7) |>
  group_by(bucket, day) |>
  summarise(requests = sum(requests), .groups = "drop") |>
  ggplot(aes(day, requests, color = bucket)) +
  geom_line(linewidth = 0.8) +
  scale_y_continuous(labels = label_comma()) +
  scale_x_date(date_labels = "%b %d", date_breaks = "1 day") +
  scale_color_viridis_d(option = "turbo", begin = 0.1, end = 0.9) +
  labs(
    title    = "S3 object downloads by bucket",
    subtitle = "Daily GET requests over the past week",
    x = NULL, y = "Requests", color = NULL
  ) +
  theme_cori_line()
```

![](monitoring-s3-access_files/figure-html/chart-by-bucket-1.png)

## Who is downloading

The `requester` field carries the full assumed-role session ARN, and the
session name is minted per credential as
`coridata-<caller>-<timestamp>`. That is what the query above unpacks
into `caller`.

`anonymous` deliberately combines two things that are technically
different but mean the same thing for this report: a request with no
credentials at all, and a vended credential nobody tagged with a
`caller`. Both answer “who did this?” with nothing. That’s the question
this report exists to answer, so the two collapse into one number rather
than being split by a technical distinction (had a credential
vs. didn’t) that doesn’t matter here. On the seven public buckets,
`anonymous` is usually the bulk of the traffic. `local credentials` is a
separate, real category: a known AWS identity that simply didn’t go
through the vending endpoint.

``` r

activity |>
  group_by(caller) |>
  summarise(requests = sum(requests), .groups = "drop") |>
  slice_max(requests, n = 12) |>
  ggplot(aes(reorder(caller, requests), requests)) +
  geom_col(fill = cori_colors[["Mid Teal"]]) +
  # Centered at each bar's own midpoint (requests / 2), not inset from the
  # tip -- real traffic here is heavily skewed (anonymous vastly outweighs
  # everything else), and a fixed tip-inset would overflow a short bar.
  # Centering scales with each bar's own length regardless of skew.
  geom_text(
    aes(y = requests / 2, label = scales::comma(requests)),
    color    = "white",
    fontface = "bold",
    size     = 3.5
  ) +
  coord_flip() +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title    = "Downloads by credential type",
    subtitle = "Parsed from the vended credential's session name",
    x = NULL, y = "Requests"
  ) +
  theme_cori_horizontal_bars()
```

![](monitoring-s3-access_files/figure-html/chart-by-caller-1.png)

## Year-to-date summary

``` r

activity |>
  filter(day >= as.Date(format(Sys.Date(), "%Y-01-01"))) |>
  group_by(bucket) |>
  summarise(
    requests = sum(requests),
    gb       = round(sum(bytes, na.rm = TRUE) / 1024^3, 1),
    callers  = n_distinct(caller),
    .groups  = "drop"
  ) |>
  arrange(desc(requests)) |>
  knitr::kable()
```

| bucket           | requests |    gb | callers |
|:-----------------|---------:|------:|--------:|
| cori.data.fcc    |   460846 | 185.8 |       2 |
| cori.data.qcew   |    15406 |   4.3 |       2 |
| cori.data.bds    |     2031 |   0.2 |       2 |
| cori.data.pep    |      686 |   0.0 |       2 |
| ruraldefinitions |       58 |   0.0 |       2 |
| cori.data.bps    |       16 |   0.0 |       1 |

Swap the [`filter()`](https://dplyr.tidyverse.org/reference/filter.html)
for `day >= Sys.Date() - 90` to get the trailing ninety days instead.

## Caveats

Server access logging is best effort. Most requests produce a record and
most records arrive within a few hours, but delivery is neither
guaranteed nor provably complete, and latency means today’s activity is
not visible yet. These numbers are a reliable picture of usage, not an
audit trail — do not present them as a compliance artifact.

In the raw log data, a vended session with no `caller` tag literally
embeds `anon` in its session name (that’s the vending endpoint’s own
fallback) – which is why the query above folds it into `anonymous`
rather than treating “vended but untagged” as its own category. Passing
a tag is what moves a request out of `anonymous` and into an
attributable name:

``` r

con <- connect_to_s3("cori.data.qcew", caller = "quarterly-refresh")
DBI::dbDisconnect(con, shutdown = TRUE)
```

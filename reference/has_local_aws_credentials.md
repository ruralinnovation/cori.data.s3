# Detect locally configured AWS credentials

Checks the two places DuckDB's own `CHAIN 'env;config'` would look for
credentials: the `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
environment variables, and `~/.aws/credentials`. Keeping the detection
aligned with the chain DuckDB actually uses means "already has
credentials" means the same thing to both.

## Usage

``` r
has_local_aws_credentials()
```

## Value

Logical. `TRUE` if credentials are present in either standard location.

## Details

This deliberately does not detect credentials sourced from an EC2
instance profile, an ECS task role, or an SSO session that only
populated a cached token (`~/.aws/sso/`). Callers in those environments
fall through to the vending path even though they could authenticate
another way — the conservative choice, since the vending path is the
tracked, read-only one.

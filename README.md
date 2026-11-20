# dbt Taxi Analytics

[![dbt pipeline](https://github.com/Abdelrahman-0-20/dbt-taxi-analytics/actions/workflows/dbt.yml/badge.svg)](https://github.com/Abdelrahman-0-20/dbt-taxi-analytics/actions/workflows/dbt.yml)

Project #3 of a [data engineering portfolio](https://github.com/Abdelrahman-0-20/analytics-engineering-pipeline)
(companion: [project #1 — hand-built batch ETL](https://github.com/Abdelrahman-0-20/analytics-engineering-pipeline),
[project #2 — live API ingestion](https://github.com/Abdelrahman-0-20/api-ingestion-pipeline)).
The same taxi domain, rebuilt the way modern teams transform data: **dbt-core +
DuckDB** with a staging-to-marts DAG, an incremental fact model, 19 built-in and
package tests, and a lineage graph — one `dbt build` runs models and tests together.

## Architecture

```
data/raw/*.parquet + *.csv        read directly by dbt-duckdb (no loader step)
        │
        ▼
staging       stg_trips (view)     typed columns, mirrors the source
              stg_zones (view)     zone lookup
        │
        ▼
intermediate  int_trips_clean      cleaning rules in SQL, thresholds from dbt vars
              (ephemeral)          inlined as a CTE — no table written
        │
        ▼
marts         fct_trips            INCREMENTAL fact + surrogate key
              dim_zones            dimension (relationships test target)
              mart_revenue_daily   revenue by day
              mart_zone_revenue    revenue by day x zone (fact joined to dim)
        │
        ▼
19 data tests + 1 singular test    not_null, unique, relationships,
                                   accepted_values, accepted_range,
                                   unique_combination_of_columns
dbt docs                           lineage graph (target/index.html)
```

## Run it

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

python scripts/fetch_data.py   # one-time download of the public source files
DBT_PROFILES_DIR=. dbt deps    # install dbt_utils (locked in package-lock.yml)
DBT_PROFILES_DIR=. dbt build   # models + all data tests, one command
DBT_PROFILES_DIR=. dbt docs generate && dbt docs serve   # browse lineage locally
```

Run `dbt build` a second time: `fct_trips` is incremental, so it processes only
rows newer than what it already holds — on this static dataset that is a
0.8s no-op with identical counts and 25/25 tests still green.

## Why dbt when project #1 already transforms data by hand?

| Concern | Project #1 (hand-built) | This project (dbt) |
|---|---|---|
| Transformation logic | Python functions + SQL strings | versioned SQL models in a DAG |
| Dependencies | implicit in code order | explicit `ref()` graph, parallel execution |
| Data tests | pytest (code-level) | declarative tests in YAML, run with `dbt build` |
| Lineage | documented by hand | generated docs graph |
| Incremental logic | hand-written watermark | `is_incremental()` + `unique_key` config |
| Thresholds | config.yaml | dbt vars in `dbt_project.yml` |

## Design decisions (interview talking points)

| Decision | Why |
|---|---|
| `fct_trips` incremental with `is_incremental()` | never reprocess history; first run full-loads, later runs append only newer pickups |
| Surrogate key via `dbt_utils.generate_surrogate_key` | TLC data has no trip id — build one from timestamps, locations, and fare |
| `int_trips_clean` ephemeral | cleaning is a reusable CTE, not another table to manage |
| Staging reads files with `read_parquet` | dbt-duckdb queries files as relations — zero-copy, no loader to maintain |
| Cleaning thresholds as `vars` | tuning data lives in `dbt_project.yml`, not buried in SQL |
| `package-lock.yml` committed | CI installs the exact same dbt_utils version every run |
| Tests expressed as contracts | `accepted_values` caught that TLC payment type 0 exists (140K rows) before it reached a mart |

## Pipeline at a glance

**7 models** (1 incremental, 3 tables, 2 views, 1 ephemeral) · **2.96M raw rows
→ 2.76M in the fact** (208K rejected by declared rules, 7.0%) · **19 data tests +
1 singular test, 25/25 green** · **incremental rerun: 0.8s no-op** ·
docs lineage artifact published by every CI run.

## Resume line

> Built a dbt transformation layer (dbt-core + DuckDB) with a staging-to-marts DAG,
> an incremental fact model with surrogate keys, 19 declarative data tests, and
> dbt docs lineage — `dbt build` runs models and tests in CI on every push.

## Ideas for later

- Publish docs to GitHub Pages (clickable lineage graph)
- `dbt source freshness` once a scheduled loader feeds the raw layer
- `dbt snapshot` (SCD Type 2) on the zone dimension
- Swap the DuckDB adapter for Snowflake/BigQuery — same project, one config change

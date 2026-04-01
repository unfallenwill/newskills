---
name: victoriametrics-api
description: VictoriaMetrics HTTP API reference for querying metrics, exporting/importing data, TSDB stats, and administrative operations. This skill should be used when constructing HTTP requests to VictoriaMetrics, understanding query endpoints (/api/v1/query, /api/v1/query_range, /api/v1/export, /api/v1/import), response formats, checking cardinality, creating snapshots, or integrating with VictoriaMetrics API.
user-invocable: false
---

# VictoriaMetrics HTTP API Reference

VictoriaMetrics provides Prometheus-compatible querying API plus additional endpoints for data export/import, admin operations, and debugging.

## Endpoints Overview

| Endpoint | Purpose |
|----------|---------|
| `/api/v1/query` | Instant query (Prometheus-compatible) |
| `/api/v1/query_range` | Range query (Prometheus-compatible) |
| `/api/v1/series` | List time series matching a label selector |
| `/api/v1/labels` | List label names |
| `/api/v1/label/<labelName>/values` | List values for a label |
| `/api/v1/status/tsdb` | TSDB statistics (cardinality, top series) |
| `/api/v1/status/active_queries` | List currently running queries |
| `/api/v1/status/top_queries` | List top queries by stats |
| `/api/v1/export` | Export data (JSON line format) |
| `/api/v1/export/csv` | Export data (CSV format) |
| `/api/v1/export/native` | Export data (native format) |
| `/api/v1/import` | Import data (JSON line format) |
| `/api/v1/import/prometheus` | Import data (Prometheus exposition format) |
| `/api/v1/import/native` | Import data (native format) |
| `/api/v1/import/csv` | Import data (CSV format) |
| `/api/v1/admin/tsdb/delete_series` | Delete time series |
| `/api/v1/targets` | List scrape targets |
| `/api/v1/metadata` | List metric metadata |
| `/federate` | Federate data across instances |
| `/datadog` | DataDog base URL |
| `/datadog/api/v1/series` | Import data in DataDog v1 format |
| `/datadog/api/v2/series` | Import data in DataDog v2 format |
| `/influx/write` | Write data with InfluxDB line protocol |
| `/graphite/metrics/find` | Search Graphite metrics |
| `/snapshot/create` | Create a backup snapshot |
| `/snapshot/list` | List snapshots |
| `/internal/force_flush` | Flush in-memory data to disk |
| `/internal/force_merge` | Force merge of partition data files |
| `/internal/resetRollupResultCache` | Reset rollup result cache |

### Cluster URLs

| Component | URL Pattern | Port |
|-----------|-------------|------|
| vmselect | `http://<vmselect>:8481/select/<accountID>/prometheus/<endpoint>` | 8481 |
| vminsert | `http://<vminsert>:8480/insert/<accountID>/prometheus/<endpoint>` | 8480 |

Single-node base URL: `http://<victoriametrics>:8428`

## Instant Query

**GET/POST** `/api/v1/query`

```bash
# Instant query at current time
curl "http://localhost:8428/api/v1/query?query=up"

# Query at specific time
curl "http://localhost:8428/api/v1/query?query=up&time=2024-01-01T00:00:00Z"

# Query with relative time
curl "http://localhost:8428/api/v1/query?query=up&time=now-1h"
```

Parameters:
- `query`: PromQL/MetricsQL expression (required)
- `time`: Evaluation timestamp (defaults to current time)
- `step`: Interval for searching raw samples in the past when a sample is missing at the specified time (defaults to `5m`)
- `timeout`: Query execution timeout
- `trace=1`: Enable query tracing

Response:
```json
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [{
      "metric": {"__name__": "up", "job": "node", "instance": "localhost:9100"},
      "value": [1704067200, "1"]
    }]
  },
  "stats": {
    "executionTimeMsec": 0.5,
    "seriesFetched": 3
  }
}
```

## Range Query

**GET/POST** `/api/v1/query_range`

```bash
curl "http://localhost:8428/api/v1/query_range" \
  -d 'query=rate(http_requests_total[5m])' \
  -d 'start=2024-01-01T00:00:00Z' \
  -d 'end=2024-01-01T01:00:00Z' \
  -d 'step=60s'
```

Parameters:
- `query`: PromQL/MetricsQL expression (required)
- `start`: Range start time
- `end`: Range end time (defaults to current time)
- `step`: Resolution step (defaults to `5m`)
- `timeout`: Query execution timeout
- `trace=1`: Enable query tracing

Response returns `resultType: "matrix"` with arrays of `[timestamp, value]` pairs per series.

## Series Matching

**GET/POST** `/api/v1/series`

```bash
curl "http://localhost:8428/api/v1/series" \
  -d 'match[]=http_requests_total' \
  -d 'start=2024-01-01T00:00:00Z' \
  -d 'end=now'
```

Response:
```json
{
  "status": "success",
  "data": [
    {"__name__": "http_requests_total", "method": "GET", "status": "200"},
    {"__name__": "http_requests_total", "method": "POST", "status": "500"}
  ]
}
```

- Default time range: last day starting at 00:00 UTC (unlike Prometheus which defaults to all time)
- Time range is rounded to UTC day granularity for performance
- `limit=N`: Limit returned entries (capped by `-search.maxSeries` flag)

## Labels and Values

### List Label Names

```bash
curl "http://localhost:8428/api/v1/labels" -d 'start=2024-01-01T00:00:00Z' -d 'end=now'
```

### List Label Values

```bash
curl "http://localhost:8428/api/v1/label/job/values" -d 'start=2024-01-01T00:00:00Z' -d 'end=now'
```

Both default to last day starting at 00:00 UTC when `start`/`end` are omitted. Time range is rounded to UTC day granularity.

## TSDB Statistics

**GET** `/api/v1/status/tsdb`

```bash
# Basic stats
curl "http://localhost:8428/api/v1/status/tsdb"

# Top 10 series by cardinality
curl "http://localhost:8428/api/v1/status/tsdb?topN=10"

# Stats for a specific date
curl "http://localhost:8428/api/v1/status/tsdb?date=2024-01-01"

# Focus on a specific label
curl "http://localhost:8428/api/v1/status/tsdb?topN=5&focusLabel=job"

# Filter by selector
curl "http://localhost:8428/api/v1/status/tsdb?topN=10&match[]=http_requests_total"
```

## Active and Top Queries

### Active Queries

```bash
curl "http://localhost:8428/api/v1/status/active_queries"
```

### Top Queries

```bash
curl "http://localhost:8428/api/v1/status/top_queries"
```

## Targets

**GET** `/api/v1/targets`

```bash
curl "http://localhost:8428/api/v1/targets"
```

Returns list of scrape targets and their status. Also available for vmagent at `http://vmagent:8429/targets`.

## Metric Metadata

**GET** `/api/v1/metadata`

```bash
# List all metadata
curl "http://localhost:8428/api/v1/metadata"

# Filter for specific metric
curl "http://localhost:8428/api/v1/metadata?metric=http_requests_total"

# Limit results
curl "http://localhost:8428/api/v1/metadata?limit=10"
```

Parameters:
- `metric`: Filter metadata for specific metrics
- `limit`: Limit number of returned metadata entries

## Export Data

### JSON Line Export

**GET** `/api/v1/export`

```bash
curl "http://localhost:8428/api/v1/export" \
  -d 'match[]=http_requests_total' \
  -d 'start=2024-01-01T00:00:00Z' \
  -d 'end=now'
```

Response (JSON lines stream):
```json
{"metric":{"__name__":"http_requests_total","job":"app"},"values":[1,2,3],"timestamps":[1704067200000,1704067260000,1704067320000]}
```

Use `reduce_memory_usage=1` to lower memory usage on large exports.

### CSV Export

**GET** `/api/v1/export/csv`

```bash
curl "http://localhost:8428/api/v1/export/csv" \
  -d 'match[]=demo' \
  -d 'format=__name__,job,instance,__value__,__timestamp__:unix_s' \
  -d 'start=2024-01-01T00:00:00Z' \
  -d 'end=now'
```

The `format` uses named column specifiers: `__name__` (metric name), label names, `__value__` (metric value), `__timestamp__:unix_s` (timestamp format). Multiple metrics with different labels can be exported in a single CSV.

### Native Export

**GET** `/api/v1/export/native`

```bash
curl "http://localhost:8428/api/v1/export/native" \
  -d 'match[]=http_requests_total'
```

## Import Data

### JSON Line Import

**POST** `/api/v1/import`

```bash
curl -H 'Content-Type: application/json' --data-binary "@filename.json" \
  -X POST http://localhost:8428/api/v1/import
```

Format per line:
```json
{"metric":{"__name__":"foo","job":"bar"},"values":[1,2.5],"timestamps":[1704067200000,1704067260000]}
```

### Prometheus Format Import

**POST** `/api/v1/import/prometheus`

```bash
curl -d 'metric_name{foo="bar"} 123' -X POST http://localhost:8428/api/v1/import/prometheus
```

### CSV Import

**POST** `/api/v1/import/csv`

```bash
curl -X POST "http://localhost:8428/api/v1/import/csv?format=2:label:job,3:label:instance,4:metric:demo,5:time:unix_s" \
  -T demo.csv
```

Format uses numbered positional specifiers: `N:label:<name>`, `N:metric:<name>`, `N:time:<format>`.

A single CSV line can contain multiple metrics:
```bash
curl -d "GOOG,1.23,4.56,NYSE" "http://localhost:8428/api/v1/import/csv?format=2:metric:ask,3:metric:bid,1:label:ticker,4:label:market"
```

### Native Import

**POST** `/api/v1/import/native`

```bash
curl -X POST http://localhost:8428/api/v1/import/native -T filename.bin
```

### DataDog Format Import

**POST** `/datadog/api/v1/series`

```bash
curl -X POST -H 'Content-Type: application/json' --data-binary @- \
  http://localhost:8428/datadog/api/v1/series <<'EOF'
{
  "series": [{
    "host": "test.example.com",
    "interval": 20,
    "metric": "system.load.1",
    "points": [[0, 0.5]],
    "tags": ["environment:test"],
    "type": "rate"
  }]
}
EOF
```

### DataDog v2 Format Import

**POST** `/datadog/api/v2/series`

```bash
curl -X POST -H 'Content-Type: application/json' --data-binary @- \
  http://localhost:8428/datadog/api/v2/series <<'EOF'
{
  "series": [{
    "metric": "system.load.1",
    "type": 0,
    "points": [{"timestamp": 0, "value": 0.7}],
    "resources": [{"name": "dummyhost", "type": "host"}],
    "tags": ["environment:test"]
  }]
}
EOF
```

### InfluxDB Line Protocol Import

**POST** `/influx/write`

```bash
curl -d 'measurement,tag1=value1,tag2=value2 field1=123,field2=1.23' \
  -X POST http://localhost:8428/write
```

### OpenTSDB Import

Enable OpenTSDB with `-opentsdbListenAddr` flag:

```bash
# TCP
echo "put foo.bar.baz $(date +%s) 123 tag1=value1" | nc -N localhost 4242

# HTTP (requires -opentsdbHTTPListenAddr)
curl -H 'Content-Type: application/json' \
  -d '[{"metric":"foo","value":45.34},{"metric":"bar","value":43}]' \
  http://localhost:4242/api/put
```

### Graphite Import

Enable Graphite with `-graphiteListenAddr` flag:

```bash
echo "foo.bar.baz;tag1=value1;tag2=value2 123 $(date +%s)" | nc -N localhost 2003
```

## Delete Series

**ANY HTTP method** `/api/v1/admin/tsdb/delete_series`

**Warning**: This endpoint accepts any HTTP method (GET, POST, etc.) — all will result in deletion.

```bash
curl "http://localhost:8428/api/v1/admin/tsdb/delete_series" \
  -d 'match[]=http_requests_total{status="500"}'
```

Returns HTTP 204 on success.

## Federation

**GET** `/federate`

```bash
curl "http://localhost:8428/federate?match[]=http_requests_total"
```

Optional `max_lookback` parameter limits lookback period for matching series.

## Graphite API

### Search Metrics

**GET** `/graphite/metrics/find`

```bash
curl "http://localhost:8428/graphite/metrics/find" -d 'query=vm_http_request_errors_total'
```

## Snapshots

```bash
# Create snapshot
curl -X POST "http://localhost:8428/snapshot/create"

# List snapshots
curl "http://localhost:8428/snapshot/list"

# Delete specific snapshot
curl -X POST "http://localhost:8428/snapshot/delete?snapshot=<name>"

# Delete all snapshots
curl -X POST "http://localhost:8428/snapshot/delete_all"
```

## Internal Operations

```bash
# Flush in-memory data to disk
curl -X POST "http://localhost:8428/internal/force_flush"

# Force merge partition data files
curl -X POST "http://localhost:8428/internal/force_merge"

# Reset rollup result cache (recommended after backfilling)
curl -X POST "http://localhost:8428/internal/resetRollupResultCache"
```

**Cluster note**: For `resetRollupResultCache`, vmselect propagates this call to other vmselects listed in its `-selectNode` flag. If not set, cache must be purged from each vmselect individually.

## Timestamp Formats

All time parameters (`start`, `end`, `time`) accept multiple formats:

| Format | Examples |
|--------|----------|
| Unix seconds | `1704067200` |
| Unix milliseconds | `1704067200000` |
| Unix microseconds | `1704067200000000` |
| Unix nanoseconds | `1704067200000000000` |
| RFC3339 | `2024-01-01T00:00:00Z` |
| Partial RFC3339 | `2024-01-01` |
| Relative | `5m`, `1h`, `2d` |
| Relative from now | `now-1h5m` |

## Extra Query Parameters

All querying endpoints accept these optional parameters:

| Parameter | Purpose | Example |
|-----------|---------|---------|
| `extra_label` | Unconditionally add label to all queries | `extra_label=tenant=acme` |
| `extra_filters[]` | Unconditionally add selector filters | `extra_filters[]={env="prod"}` |
| `round_digits` | Round response values to N digits | `round_digits=2` |
| `limit` | Limit number of returned series | `limit=100` |
| `timeout` | Query execution timeout | `timeout=30s` |
| `nocache=1` | Disable query result caching | `nocache=1` |
| `trace=1` | Enable query tracing in response | `trace=1` |
| `latency_offset` | Override default 30s query latency offset | `latency_offset=5s` |

### Query Tracing

```bash
curl "http://localhost:8428/api/v1/query?query=up&trace=1"
```

Adds a `trace` field to the JSON response with detailed query execution info.

### Access Control

`extra_label` and `extra_filters[]` are propagated into all subqueries and cannot be bypassed by the user:

```bash
curl "http://localhost:8428/api/v1/query?query=up&extra_label=tenant=acme&extra_filters[]={env=%22prod%22}"
```

### Query Latency

VictoriaMetrics does not immediately return recently written samples. There is a default 30-second latency offset (`-search.latencyOffset`). This can be overridden per-query via the `latency_offset` parameter.

## Common Patterns

```
# 1. Instant query for current state
GET /api/v1/query?query={metric}[range]

# 2. Range query for time series visualization
GET /api/v1/query_range?query={metric}&start={t1}&end={t2}&step={interval}

# 3. Discover series and labels
GET /api/v1/series?match[]={selector}
GET /api/v1/labels
GET /api/v1/label/{name}/values

# 4. Check cardinality
GET /api/v1/status/tsdb?topN=10

# 5. Export data for backup or migration
GET /api/v1/export?match[]={selector}&start={t1}&end={t2}

# 6. Import bulk data
POST /api/v1/import

# 7. Debug query performance
GET /api/v1/query?query={expr}&trace=1
GET /api/v1/status/top_queries
```

## Notes

- Default port: **8428** (cluster: vmselect **8481**, vminsert **8480**)
- Default time range for `/api/v1/series`, `/api/v1/labels`, `/api/v1/label/.../values` is the **last day starting at 00:00 UTC** (unlike Prometheus which defaults to all time)
- Time ranges for these endpoints are **rounded to UTC day granularity** for performance
- Timestamps in query parameters support multiple formats (see Timestamp Formats above)
- Export timestamps are in **milliseconds**; import timestamps accept configurable formats
- `stats` object in responses includes `executionTimeMsec` and `seriesFetched`
- Use `trace=1` to debug slow queries
- Use `nocache=1` to bypass result cache for real-time data
- Admin and internal endpoints may require additional access controls
- VMUI available at `http://victoriametrics:8428/vmui`

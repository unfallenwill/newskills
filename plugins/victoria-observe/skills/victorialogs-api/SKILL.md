---
name: victorialogs-api
description: VictoriaLogs HTTP API reference for querying logs, hits stats, field discovery, live tailing, and log statistics. This skill should be used when constructing HTTP requests to VictoriaLogs, understanding query endpoints (/select/logsql/query, /select/logsql/tail, /select/logsql/hits, /select/logsql/field_names), response formats, or integrating with VictoriaLogs API for log search and analysis.
user-invocable: false
---

# VictoriaLogs HTTP API Reference

VictoriaLogs provides HTTP endpoints for querying logs via LogsQL.

Base URL: `http://localhost:9428`

## Endpoints Overview

| Endpoint | Purpose |
|----------|---------|
| `/select/logsql/query` | Query logs |
| `/select/logsql/tail` | Live tailing |
| `/select/logsql/hits` | Hit counts over time |
| `/select/logsql/facets` | Most frequent field values |
| `/select/logsql/stats_query` | Log stats at a point in time |
| `/select/logsql/stats_query_range` | Log stats over time range |
| `/select/logsql/streams` | List log streams |
| `/select/logsql/stream_ids` | List stream IDs |
| `/select/logsql/stream_field_names` | Stream field names |
| `/select/logsql/stream_field_values` | Stream field values |
| `/select/logsql/field_names` | Log field names |
| `/select/logsql/field_values` | Log field values |
| `/select/tenant_ids` | List tenants |

## Query Logs

**GET/POST** `/select/logsql/query`

The `query` arg can be passed via HTTP GET (in URL) or HTTP POST (in request body with `x-www-form-urlencoded` encoding). POST is useful for long queries that exceed URL length limits.

```bash
# Basic query
curl http://localhost:9428/select/logsql/query -d 'query=error'

# With limit (returns up to N most recent by _time)
curl http://localhost:9428/select/logsql/query -d 'query=error' -d 'limit=10'

# With time range
curl http://localhost:9428/select/logsql/query -d 'query=error' -d 'start=2024-01-01T00:00:00Z' -d 'end=now'

# With pagination (skip top M logs with biggest _time)
curl http://localhost:9428/select/logsql/query -d 'query=error' -d 'limit=10' -d 'offset=100'

# Timeout (overrides -search.maxQueryDuration)
curl http://localhost:9428/select/logsql/query -d 'query=error' -d 'timeout=4.2s'
```

Response: JSON lines stream, each line is `{"field1":"value1",...,"fieldN":"valueN"}`

```json
{"_msg":"error: disconnect from 19.54.37.22","_stream":"{}","_time":"2023-01-01T13:32:13Z"}
```

Key behaviors:
- Results stream as they are found (safe to close connection anytime)
- Results are NOT sorted by default (use `limit=N` for most recent, or `sort` pipe)
- Use `| fields _time, level, _msg` to select specific fields
- `limit=N` query arg returns up to N most recent matching logs by `_time`
- `| limit N` pipe returns up to N random matching logs (different from query arg)

### CSV Output

Add `format=csv` to get CSV output instead of JSON lines. The query must end with a `fields` or `stats` pipe. `sort` and `limit` pipes can be placed after `fields`/`stats` in CSV mode:

```bash
curl http://localhost:9428/select/logsql/query -d 'query=error | fields _time, _msg' -d 'format=csv'
```

## Live Tailing

**GET/POST** `/select/logsql/tail`

```bash
# Basic live tailing (use -N to disable curl buffering)
curl -N http://localhost:9428/select/logsql/tail -d 'query=error'

# With historical offset
curl -N http://localhost:9428/select/logsql/tail -d 'query=*' -d 'start_offset=1h'

# Change delivery delay (default 1s)
curl -N http://localhost:9428/select/logsql/tail -d 'query=*' -d 'offset=30s'

# Change refresh interval (default 1s)
curl -N http://localhost:9428/select/logsql/tail -d 'query=*' -d 'refresh_interval=10s'
```

Parameters:
- `start_offset=<d>`: Return historical logs ingested during the last `<d>` duration before starting live tailing
- `offset=<d>`: Delay for delivering new logs (default `1s`)
- `refresh_interval=<d>`: How often to check for new logs (default `1s`)

Query restrictions:
- Cannot use `stats`, `uniq`, `top`, `sort`, `limit`, `offset` pipes
- Query must select `_time` field
- Recommended to return `_stream_id` field for more accurate tailing across multiple streams

## Hit Counts

**GET/POST** `/select/logsql/hits`

```bash
curl http://localhost:9428/select/logsql/hits \
  -d 'query=error' \
  -d 'start=3h' \
  -d 'end=now' \
  -d 'step=1h'
```

Response:
```json
{
  "hits": [{
    "fields": {},
    "timestamps": ["2024-01-01T00:00:00Z", "2024-01-01T01:00:00Z"],
    "values": [410339, 450311],
    "total": 860650
  }]
}
```

Parameters:
- `query`: LogsQL query (required)
- `start`, `end`: Time range (any supported format; defaults to min/max timestamp across stored logs)
- `step`: Bucket interval (required)
- `offset`: Timezone alignment for bucket timestamps
- `field=<field_name>`: Group by field (can be passed multiple times)
- `fields_limit=N`: Limit number of unique `fields` groups to N (top N by total hits, remainder in `fields:{}`)
- `ignore_pipes=1`: Ignore pipes from the query while obtaining hits
- `timeout`: Max execution time

Returned timestamps are aligned to `step` at the given timezone `offset`, so the first bucket may contain a timestamp smaller than `start`.

## Facets (Most Frequent Values)

**GET/POST** `/select/logsql/facets`

```bash
# Basic facets
curl http://localhost:9428/select/logsql/facets \
  -d 'query=_time:1h error' \
  -d 'limit=3'

# With explicit time range parameters
curl http://localhost:9428/select/logsql/facets \
  -d 'query=error' \
  -d 'start=1h' \
  -d 'end=now' \
  -d 'limit=3'

# Control unique values per field
curl http://localhost:9428/select/logsql/facets \
  -d 'query=_time:1h' \
  -d 'max_values_per_field=100000'

# Control max value length
curl http://localhost:9428/select/logsql/facets \
  -d 'query=_time:1h' \
  -d 'max_value_len=100'

# Include constant-value fields
curl http://localhost:9428/select/logsql/facets \
  -d 'query=_time:1h' \
  -d 'keep_const_fields=1'
```

Response:
```json
{
  "facets": [{
    "field_name": "kubernetes_container_name",
    "values": [
      {"field_value": "victoria-logs", "hits": 442378},
      {"field_value": "victoria-metrics", "hits": 34783}
    ]
  }, {
    "field_name": "kubernetes_pod_name",
    "values": [
      {"field_value": "victoria-logs-0", "hits": 232385},
      {"field_value": "victoria-logs-1", "hits": 123898}
    ]
  }]
}
```

Parameters:
- `query`: LogsQL query (required)
- `start`, `end`: Time range (optional; defaults to min/max stored timestamp)
- `limit=N`: Max values per field to return
- `max_values_per_field=N`: Only process fields with up to N unique values (fields with more are skipped)
- `max_value_len=N`: Only process fields with values no longer than N bytes
- `keep_const_fields=1`: Include fields with the same constant value across all matching logs
- `ignore_pipes=1`: Ignore pipes from the query while obtaining facets

## Log Stats (Prometheus-compatible)

### Instant Stats
**GET/POST** `/select/logsql/stats_query`

```bash
curl http://localhost:9428/select/logsql/stats_query \
  -d 'query=_time:1d | stats by (level) count(*)' \
  -d 'time=2024-01-02Z'
```

Response:
```json
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {"metric": {"__name__": "count(*)", "level": "info"}, "value": [1704153600, "20395342"]},
      {"metric": {"__name__": "count(*)", "level": "error"}, "value": [1704153600, "832"]}
    ]
  }
}
```

- Query must contain `| stats` pipe
- If `time` is missing, defaults to current time
- `row_any`, `row_min`, `row_max` stats functions create labels instead of metrics
- Use `format` pipe for additional labels and `math` pipe for additional metrics
- Used by vmalert for generating Prometheus-compatible alerts

### Range Stats
**GET/POST** `/select/logsql/stats_query_range`

```bash
curl http://localhost:9428/select/logsql/stats_query_range \
  -d 'query=* | stats by (level) count(*)' \
  -d 'start=2024-01-01Z' \
  -d 'end=2024-01-02Z' \
  -d 'step=6h'
```

Returns Prometheus-compatible `matrix` result type. Used by Grafana plugin.

Parameters:
- `start`, `end`: Time range (optional; defaults to min/max stored timestamp)
- `step`: Bucket interval (required)
- `offset`: Timezone alignment for bucket timestamps
- `timeout`: Max execution time

Notes:
- Relies on `_time` for time bucketing — no pipe can change or remove `_time` before `| stats` pipe
- `running_stats` and `total_stats` pipes useful for calculating running/total stats
- `row_any`, `row_min`, `row_max` stats functions create labels instead of metrics
- Use `format` pipe for additional labels and `math` pipe for additional metrics

## Field Discovery

### Field Names
```bash
curl http://localhost:9428/select/logsql/field_names \
  -d 'query=error' -d 'start=5m' -d 'end=now'
```

Response: `{"values":[{"value":"_msg","hits":1033300623},{"value":"_stream","hits":1033300623},{"value":"_time","hits":1033300623}]}`

Supports: `ignore_pipes=1`, `limit=N`, `timeout`

### Field Values
```bash
curl http://localhost:9428/select/logsql/field_values \
  -d 'query=error' -d 'field=host' -d 'start=5m' -d 'end=now'
```

Supports: `ignore_pipes=1`, `limit=N` (arbitrary subset returned if exceeded; `hits` zeroed), `timeout`

### Stream Field Names / Values
```bash
curl http://localhost:9428/select/logsql/stream_field_names -d 'query=error' -d 'start=5m'
curl http://localhost:9428/select/logsql/stream_field_values -d 'query=error' -d 'field=host' -d 'start=5m'
```

`stream_field_values` supports: `limit=N` (arbitrary subset, `hits` zeroed if exceeded)

Both support: `ignore_pipes=1`

## Streams

```bash
curl http://localhost:9428/select/logsql/streams -d 'query=error' -d 'start=5m' -d 'end=now'
```

Response: `{"values":[{"value":"{host=\"host-123\",app=\"foo\"}","hits":34980},...]}`

Supports: `limit=N` (arbitrary subset returned; `hits` zeroed if exceeded), `ignore_pipes=1`

## Stream IDs

```bash
curl http://localhost:9428/select/logsql/stream_ids -d 'query=error' -d 'start=5m' -d 'end=now'
```

Response: `{"values":[{"value":"0000000000000000106955b...","hits":442953},...]}`

Supports: `limit=N` (arbitrary subset returned; `hits` zeroed if exceeded), `ignore_pipes=1`

## Tenants

**GET** `/select/tenant_ids`

```bash
curl http://localhost:9428/select/tenant_ids -d 'start=5m' -d 'end=now'
```

Response:
```json
[{"account_id": 0, "project_id": 0}]
```

**Security note**: This endpoint must be called with empty `AccountID` request header. This prevents unauthorized access from clients who have access to a specific tenant.

## Multi-Tenancy

Default tenant: `(AccountID=0, ProjectID=0)`. Override via headers:

```bash
curl -H 'AccountID: 12' -H 'ProjectID: 34' \
  http://localhost:9428/select/logsql/query -d 'query=error'
```

## Extra Filters

All endpoints accept `extra_filters` and `extra_stream_filters` for access control. These are **global constraints** — unconditionally propagated into all subqueries (including `| join`, `| union`, `:in()`, etc.) and cannot be bypassed.

```bash
# JSON object format
-d 'extra_filters={"namespace":"my-app","env":"prod"}'
-d 'extra_stream_filters={"namespace":"my-app","env":"prod"}'

# Array values are converted to field:in(v1,v2,...vN) for extra_filters
# and {field=~"v1|v2|...|vN"} for extra_stream_filters
-d 'extra_filters={"app":["nginx","redis"]}'

# Arbitrary LogsQL filter
-d 'extra_filters=foo:~bar -baz:x'
```

Multiple `extra_filters` and `extra_stream_filters` args can be passed in a single request.

## Hidden Fields

Hide sensitive fields from query results. Fields become invisible during filtering and all LogsQL pipe execution.

```bash
# Comma-separated format
-d 'hidden_fields_filters=pass*,pin'

# JSON array format (allows field names containing commas)
-d 'hidden_fields_filters=["pass*","pin"]'
```

**Note**: `hidden_fields_filters` is not applied to `_stream` field contents to prevent duplicate `_stream` values for distinct log streams.

## Partial Responses (Cluster)

VictoriaLogs cluster returns `502 Bad Gateway` if some `vlstorage` nodes are unavailable. Pass `allow_partial_response=1` to get partial (potentially inconsistent) responses instead:

```bash
-d 'allow_partial_response=1'
```

This overrides the `-search.allowPartialResponse` command-line flag.

## Response Headers

All endpoints return:
- `VL-Request-Duration-Seconds`: Query duration to first byte
- `AccountID` and `ProjectID`: Requested tenant

## Time Formats

`start` and `end` accept:
- Relative: `5m`, `1h`, `2d` (from now)
- RFC3339: `2024-01-01T00:00:00Z`
- Partial date: `2024-01-01`
- Unix timestamps (seconds)

If `start` is missing, defaults to the minimum timestamp across stored logs. If `end` is missing, defaults to the maximum timestamp.

## Resource Usage Limits

Server-side flags:
- `-search.maxQueryTimeRange`: Disallows queries with too broad time ranges (e.g., `1d`)
- `-search.maxQueryDuration`: Max execution time per query (overridable per-query via `timeout` arg)
- `-search.maxConcurrentRequests`: Max concurrent queries (queue via `-search.maxQueueDuration`)

## Web UI

Available at `http://localhost:9428/select/vmui/` with Group, Table, JSON, and Live display modes.

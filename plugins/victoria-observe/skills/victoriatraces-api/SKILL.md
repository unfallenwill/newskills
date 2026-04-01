---
name: victoriatraces-api
description: VictoriaTraces HTTP API reference for querying distributed traces via Jaeger-compatible API. This skill should be used when searching traces, listing services/operations, getting trace details by ID, querying service dependencies, constructing HTTP requests to VictoriaTraces, or working with Jaeger API endpoints for distributed tracing analysis.
user-invocable: false
---

# VictoriaTraces API Reference

VictoriaTraces provides Jaeger-compatible HTTP API for querying distributed traces. It is built on top of VictoriaLogs and additionally supports LogsQL-based querying for trace spans.

## Endpoints Overview

| Endpoint | Purpose |
|----------|---------|
| `/select/jaeger/api/services` | List all services |
| `/select/jaeger/api/services/<service>/operations` | List operations (span names) for a service |
| `/select/jaeger/api/traces` | Search traces |
| `/select/jaeger/api/traces/<traceID>` | Get trace by ID |
| `/select/jaeger/api/dependencies` | Service dependency graph (experimental) |

VictoriaTraces also provides all VictoriaLogs querying endpoints (e.g., `/select/logsql/query`, `/select/logsql/hits`, `/select/logsql/field_names`) since it is built on VictoriaLogs.

### Cluster URLs

| Component | URL Pattern | Port |
|-----------|-------------|------|
| vtselect | `http://<vtselect>:8481/select/<accountID>/...` | 8481 |
| vtinsert | `http://<vtinsert>:8480/insert/<accountID>/...` | 8480 |

Single-node base URL: `http://<victoria-traces>:10428`

## Multi-Tenancy

Default tenant: `(AccountID=0, ProjectID=0)`. Override via headers:

```bash
curl -H 'AccountID: 12' -H 'ProjectID: 34' \
  http://localhost:10428/select/jaeger/api/traces?service=checkout
```

The `AccountID` and `ProjectID` headers apply to both ingestion and querying. If omitted, both default to `0`.

## List Services

```bash
curl http://localhost:10428/select/jaeger/api/services
```

Response:
```json
{
  "data": ["accounting", "ad", "cart", "checkout", "currency"],
  "errors": null,
  "limit": 0,
  "offset": 0,
  "total": 5
}
```

## List Operations

```bash
curl http://localhost:10428/select/jaeger/api/services/checkout/operations
```

Response:
```json
{
  "data": ["HTTP POST", "orders publish", "oteldemo.CartService/EmptyCart"],
  "errors": null,
  "limit": 0,
  "offset": 0,
  "total": 5
}
```

## Search Traces

**GET** `/select/jaeger/api/traces`

### Parameters

| Parameter | Format | Example |
|-----------|--------|---------|
| `service` | Service name (required) | `service=checkout` |
| `operation` | Operation name | `operation=oteldemo.CheckoutService/PlaceOrder` |
| `tags` | JSON object (URL-encoded) | `tags=%7B%22error%22%3A%22true%22%7D` |
| `minDuration` | Go duration | `minDuration=1ms`, `minDuration=500ms`, `minDuration=1s` |
| `maxDuration` | Go duration | `maxDuration=10s` |
| `limit` | Integer | `limit=5` |
| `start` | Microseconds timestamp | `start=1749969952453000` |
| `end` | Microseconds timestamp | `end=1750056352453000` |

### Duration Format

Go `time.Duration` format: integer + unit suffix.

Supported suffixes: `ns` (nanoseconds), `us` or `µs` (microseconds), `ms` (milliseconds), `s` (seconds), `m` (minutes), `h` (hours).

Examples: `100ms`, `500ms`, `1s`, `2.5s`, `5m`, `1h`

### Tags (Enhanced Filtering)

VictoriaTraces supports filtering by span attributes, resource attributes, and scope attributes using a JSON object passed as the `tags` parameter:

```bash
# Span attributes (default)
tags={"rpc.method":"Convert"}

# Resource attributes (use resource_attr: prefix)
tags={"resource_attr:service.namespace":"opentelemetry-demo"}

# Scope attributes (use scope_attr: prefix)
tags={"scope_attr:otel.scope.name":"checkout"}
```

**Note**: The `tags` parameter must be URL-encoded when passed in the query string. For example, `{"error":"true"}` becomes `%7B%22error%22%3A%22true%22%7D`.

Under the hood, VictoriaTraces stores attributes with prefixes:
- `resource_attr:` — for resource attributes
- `scope_attr:` — for scope (instrumentation) attributes
- `span_attr:` — for span attributes

### Example Queries

```bash
# Search by service
curl "http://localhost:10428/select/jaeger/api/traces?service=checkout&limit=20"

# Search with operation
curl "http://localhost:10428/select/jaeger/api/traces?service=checkout&operation=oteldemo.CheckoutService/PlaceOrder&limit=5"

# Find slow traces
curl "http://localhost:10428/select/jaeger/api/traces?service=checkout&minDuration=1s&limit=10"

# Find error traces
curl "http://localhost:10428/select/jaeger/api/traces?service=checkout&tags=%7B%22error%22%3A%22true%22%7D"

# Combined filters
curl "http://localhost:10428/select/jaeger/api/traces?service=checkout&operation=oteldemo&tags=%7B%22rpc.method%22%3A%22Convert%22%7D&minDuration=1ms&maxDuration=10ms&limit=5"
```

### Response Structure

```json
{
  "data": [{
    "traceID": "9e06226196051d9c3c10dfab343791ad",
    "spans": [{
      "traceID": "...",
      "spanID": "...",
      "operationName": "oteldemo.CheckoutService/PlaceOrder",
      "startTime": 1750044449706551,
      "duration": 69871,
      "tags": [
        {"key": "rpc.method", "type": "string", "value": "PlaceOrder"},
        {"key": "error", "type": "string", "value": "unset"}
      ],
      "logs": [],
      "references": [{"refType": "CHILD_OF", "spanID": "...", "traceID": "..."}],
      "processID": "p3"
    }],
    "processes": {
      "p3": {
        "serviceName": "checkout",
        "tags": [{"key": "service.namespace", "value": "opentelemetry-demo"}]
      }
    },
    "warnings": null
  }],
  "errors": null,
  "limit": 20,
  "offset": 0,
  "total": 1
}
```

Key fields per span:
- `startTime`: Microseconds since epoch
- `duration`: Microseconds
- `tags[]`: Span attributes as `{key, type, value}`
- `references[]`: Parent-child relationships (`CHILD_OF`)
- `processID`: Links to process info (service name + resource attributes)

Top-level response fields:
- `data`: Array of trace objects
- `errors`: Error messages (or `null`)
- `limit`: Maximum number of traces returned
- `offset`: Pagination offset
- `total`: Total number of matching traces

## Get Trace by ID

```bash
curl http://localhost:10428/select/jaeger/api/traces/9e06226196051d9c3c10dfab343791ad
```

Returns full trace with all spans, processes, and service mapping. Response format is the same as search, with `limit`, `offset`, `total`, `errors` top-level fields.

## Service Dependencies (Experimental)

**GET** `/select/jaeger/api/dependencies`

> **Note**: This feature is **experimental**. To enable it, set `-servicegraph.enableTask=true` on VictoriaTraces single-node or `vtstorage` (cluster mode).

```bash
curl "http://localhost:10428/select/jaeger/api/dependencies?endTs=1758213428616&lookback=60000"
```

Parameters:
- `endTs`: End timestamp in milliseconds
- `lookback`: Lookback duration in milliseconds

Response:
```json
{
  "data": [
    {"parent": "checkout", "child": "cart", "callCount": 4},
    {"parent": "checkout", "child": "shipping", "callCount": 4},
    {"parent": "frontend", "child": "checkout", "callCount": 2}
  ]
}
```

## Common Patterns

```
# 1. Discover services
GET /select/jaeger/api/services

# 2. Find operations for a service
GET /select/jaeger/api/services/{service}/operations

# 3. Search traces (service is required)
GET /select/jaeger/api/traces?service={service}&limit=20

# 4. Get trace details
GET /select/jaeger/api/traces/{traceID}

# 5. View service graph (experimental, requires -servicegraph.enableTask=true)
GET /select/jaeger/api/dependencies?endTs={now_ms}&lookback=3600000

# 6. Query trace spans via LogsQL (VictoriaLogs-compatible endpoints)
GET /select/logsql/query?query=_time:5m AND span_attr:error
GET /select/logsql/field_names?query=_time:5m
```

## Notes

- `service` parameter is **required** for trace search
- Time parameters (`start`, `end`) are in **microseconds** (not milliseconds or seconds)
- Dependencies `endTs` is in **milliseconds**
- Duration filters use Go format (`500ms`, `1s`, `5m`, `1h`), not PromQL format
- Tags must be URL-encoded JSON objects
- VictoriaTraces is built on VictoriaLogs and supports all VictoriaLogs querying endpoints (LogsQL)
- Multi-tenancy via `AccountID` and `ProjectID` HTTP headers (default to `0`)
- Web UI available at `http://<victoria-traces>:10428/select/vmui`
- Default port: **10428** (cluster: vtselect **8481**, vtinsert **8480**)

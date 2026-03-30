# Traces Query Reference

## Jaeger API Parameter Format

VictoriaTraces uses Jaeger-compatible API. Queries are parameter-based (not a query language like MetricsQL/LogsQL).

### Required Parameters

- `traces search` **requires** `--service <name>`. Use `traces services` to list available services first.

### Time Range

```
--start 1h              # relative: 5m, 30m, 1h, 6h, 24h, 7d
--start 2024-01-01T00:00:00Z  # RFC3339 absolute
--end now                # default end time
```

### Filter Parameters

| Parameter | Format | Example |
|-----------|--------|---------|
| `--service` | Service name string | `--service checkout` |
| `--operation` | Operation name string | `--operation POST /api/pay` |
| `--tags` | JSON object (single-quoted) | `--tags '{"error":"true"}'` |
| `--minDuration` | Go duration format | `--minDuration 500ms`, `--minDuration 1s`, `--minDuration 5m` |
| `--maxDuration` | Go duration format | `--maxDuration 10s` |
| `--limit` | Integer | `--limit 20` |

### Duration Format

Uses Go `time.Duration` format: integer + unit suffix.

| Suffix | Meaning |
|--------|---------|
| `ms` | milliseconds |
| `s` | seconds |
| `m` | minutes |

Examples: `100ms`, `500ms`, `1s`, `2.5s`, `5m`, `1h`

**Note**: No `h` suffix in Jaeger API — use `3600s` or `60m` for 1 hour.

### Tags JSON Format

```bash
# Single tag
--tags '{"error":"true"}'

# Multiple tags
--tags '{"error":"true","http.status_code":"502"}'

# Numeric tag value
--tags '{"http.status_code":502}'
```

Tags must be single-quoted in shell to prevent JSON quote issues.

---

## Command Reference

### Service Discovery

```bash
# List all services
node $SCRIPT traces services

# List operations for a service
node $SCRIPT traces operations checkout
```

### Trace Search

```bash
# By service (default: last 1 hour)
node $SCRIPT traces search --service checkout --limit 20

# With time range
node $SCRIPT traces search --service checkout --start 1h

# By operation
node $SCRIPT traces search --service checkout --operation "POST /api/pay" --start 1h

# Find slow traces (>500ms)
node $SCRIPT traces search --service checkout --minDuration 500ms --start 1h

# Find error traces
node $SCRIPT traces search --service checkout --tags '{"error":"true"}' --start 1h
```

### Trace Details

```bash
# Compact summary (default): traceID, span count, duration, root operation, services
node $SCRIPT traces get <traceID>

# Full span details: operation, service, duration, parent, tags per span
node $SCRIPT traces get <traceID> --verbose
```

### Dependency Map

```bash
# Service dependency graph (default: last 24 hours)
node $SCRIPT traces dependencies
node $SCRIPT traces dependencies --start 1h
```

---

## Notes

- `--service` is required for `traces search`. Run `traces services` first to discover available services.
- Durations use Go format (`500ms`, `1s`, `5m`), not MetricsQL/PromQL format.
- Tags are JSON objects passed as `--tags '{"key":"value"}'`.
- Time parameters `--start`/`--end` accept relative (`1h`) or RFC3339 absolute.
- The search API converts `--start`/`--end` to microseconds internally (Jaeger format).
- Output is compact by default; use `--verbose` for full span-level details.

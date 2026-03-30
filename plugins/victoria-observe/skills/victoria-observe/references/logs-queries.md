# Logs Query Reference

## LogsQL Syntax Quick Reference

LogsQL is a query language specifically for log data. It is NOT PromQL — it uses pipe-based syntax with field-level filtering.

### Core Structure

A LogsQL query has two parts (both optional):
```
[filters] [| pipe_action | pipe_action ...]
```

- **Filters**: Select which log entries to match
- **Pipes**: Transform, aggregate, or format results

### Special Fields

| Field | Description |
|-------|-------------|
| `_msg` | Log message body (default target for word/phrase searches) |
| `_time` | Timestamp of the log entry |
| `_stream` | Log stream label set, e.g. `{app="nginx",host="srv1"}` |
| `_stream_id` | Internal stream identifier |

All other fields are user-defined (e.g. `host`, `log.level`, `ip`, `otelTraceID`).

### Filter: Stream Selector

```
_stream:{app="api"}
_stream:{app="nginx",instance="host-123"}
{app="api"}                      # _stream: prefix is optional
```

Selector operators: `=` (exact), `!=`, `=~` (regex), `!~`, `in("a","b")`, `not_in("a","b")`

### Filter: Time Range

```
_time:5m                         # last 5 minutes
_time:1h                         # last 1 hour
_time:2.5d15m42s                 # compound duration
_time:>1h                        # older than 1 hour ago
```

Duration units: `s`, `m`, `h`, `d`, `w`, `y`

### Filter: Word Search

```
error                            # matches the word "error" in _msg
log.level:error                  # matches "error" in log.level field
i(error)                         # case-insensitive word search
```

### Filter: Phrase Search

```
"connection refused"             # exact phrase in _msg
"ssh: login fail"                # includes punctuation
event.original:"cannot open file" # phrase in specific field
i("connection refused")          # case-insensitive phrase
```

### Filter: Logical Operators

```
error AND warning                # both must match (AND is optional)
error _time:5m                   # implicit AND (equivalent)
error OR warning                 # either matches
NOT error                        # exclude
-error                           # NOT (shorthand)
(error OR warning) _time:5m      # parentheses for grouping
```

Precedence: `NOT` > `AND` > `OR`

### Filter: Field-Level Filters

```
log.level:error                  # word in field
log.level:="error"               # exact match
log.level:in("error","fatal")    # multi-value exact match
response_size:>10KiB             # numeric comparison
app:~"nginx|apache"              # regex on field
user.ip:ipv4_range("10.0.0.0/8") # IPv4 CIDR
field:*                          # field exists (any value)
field:""                         # field is empty
-field:*                         # field does not exist
```

### Filter: Regex

```
~"err|warn"                      # regex in _msg
~"(?i)(err|warn)"                # case-insensitive regex
event.original:~"err|warn"       # regex on specific field
```

Uses RE2 syntax. Use `(?i)` for case-insensitive.

### Wildcards

```
*                                # match all logs
err*                             # words starting with "err"
*err*                            # contains "err" anywhere
="Processing request"*           # value starts with prefix
```

### Pipe: Stats (Aggregation)

```
| stats count() logs                                           # total count
| stats by (host) count() logs                                 # count per host
| stats by (_time:1h) count() logs                             # count per hour
| stats by (_time:1m) count() logs, count_uniq(ip) unique_ips  # multi-stat
| stats count() if (error) errors, count() total               # conditional stats
```

Stats functions: `count()`, `count_uniq(field)`, `sum(field)`, `avg(field)`, `min(field)`, `max(field)`, `median(field)`, `quantile(0.99, field)`, `rate()`, `uniq_values(field)`

### Pipe: Sort and Limit

```
| sort by (_time) desc          # sort by time descending
| sort by (logs desc)           # sort by field descending
| limit 10                      # keep first 10 results
| offset 100 | limit 50         # pagination
```

### Pipe: Field Manipulation

```
| fields host, log.level        # keep only these fields
| delete password, token         # remove fields
| unpack_json                    # parse JSON fields
| extract "ip=<ip> "            # extract field from _msg
| rename old_name as new_name    # rename field
```

### Pipe: Context

```
| stream_context before 5 after 10    # show surrounding log lines
```

---

## Command Reference

### Basic Log Search

```bash
# Recent errors
node $SCRIPT logs query 'error' --start 30m --limit 100

# Filter by stream + error
node $SCRIPT logs query '{app="api"} error' --start 1h

# Phrase search
node $SCRIPT logs query '"connection refused"' --start 1h

# Combined filters
node $SCRIPT logs query '{app="api"} severity:error "timeout"' --start 2h
```

### Log Exploration

```bash
# Discover stream labels
node $SCRIPT logs streams

# Discover field names
node $SCRIPT logs field-names '{app="api"}'

# Get unique values for a field
node $SCRIPT logs field-values severity '{app="api"}' --start 1h

# Count matching logs
node $SCRIPT logs hits '{app="api"} error' --start 1h
```

### Live Tailing

```bash
node $SCRIPT logs tail '{app="api"}'
node $SCRIPT logs tail --timeout 30       # auto-stop after 30 seconds
```

Press Ctrl+C to stop tailing.

### Stats and Aggregation

```bash
# Count errors per hour
node $SCRIPT logs query '{app="api"} error | stats by (_time:1h) count() logs'

# Top hosts by error count
node $SCRIPT logs query 'error | stats by (host) count() logs | sort by (logs desc) | limit 10'
```

## Notes

- Use `logs streams` first to discover actual stream labels before writing `_stream:{...}` filters
- Use `logs field-names` to discover available fields for filtering
- `_msg` is the default target for word/phrase searches; use `field:word` syntax to target other fields
- Common OTel field names: `severity`, `service.name`, `otelTraceID`, `otelSpanID`

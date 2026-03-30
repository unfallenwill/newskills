# Metrics Query Reference

## MetricsQL Syntax Quick Reference

MetricsQL is a superset of PromQL. All PromQL queries work; additional functions are MetricsQL-specific.

### Instant Vector Selector

```
# Select by metric name
up

# Filter by labels (=, !=, =~, !~)
http_requests_total{job="api", status=~"5.."}
```

### Range Vector Selector

```
# Last 5 minutes of data points
http_requests_total[5m]

# With label filters
http_requests_total{job="api"}[1h]
```

Time units: `s`, `m`, `h`, `d`, `w`, `y`.

### Common Functions

| Function | Example | Purpose |
|----------|---------|---------|
| `rate()` | `rate(metric[5m])` | Per-second average rate over range |
| `irate()` | `irate(metric[5m])` | Instant rate (last 2 points) |
| `increase()` | `increase(metric[1h])` | Absolute increase over range |
| `sum()` | `sum(metric)` | Sum across all series |
| `avg()` | `avg(metric)` | Average across series |
| `count()` | `count(metric)` | Count series |
| `topk()` | `topk(5, metric)` | Top 5 by value |
| `histogram_quantile()` | `histogram_quantile(0.99, rate(bucket[5m]))` | Calculate percentile |
| `absent()` | `absent(metric)` | Returns 1 if no data (alert for missing) |
| `predict_linear()` | `predict_linear(metric[1h], 3600)` | Linear regression prediction |
| `deriv()` | `deriv(metric[1h])` | Derivative per second |

### Aggregation with `by` / `without`

```
sum by (job) (rate(http_requests_total[5m]))
avg by (instance) (node_cpu_seconds_total{mode="idle"})
count by (status) (http_requests_total)
topk(10, sum by (job) (rate(http_requests_total[5m])))
```

### Binary Operators

```
# Arithmetic: + - * / % ^
rate(errors[5m]) / rate(total[5m]) * 100

# Comparison: == != > < >= <= (use `_bool` suffix for 0/1 output)
http_requests_total{status=~"5.."} > bool 0
```

### MetricsQL-Specific Extensions

| Function | Example | Purpose |
|----------|---------|---------|
| `keep_last_value()` | `keep_last_value(metric[1h])` | Fill gaps with last seen value |
| `default_rollup()` | `default_rollup(metric[5m])` | Auto-aggregate across replicas |
| `rollup()` | `rollup(metric, "5m")` | Roll up with explicit step |
| `alias()` | `alias(metric, "name")` | Rename result series |
| `union()` | `union(q1, q2)` | Combine multiple queries |
| `range_normalize()` | `range_normalize(q1, q2)` | Normalize to 0..1 range |
| `label_set()` | `label_set(metric, "team", "backend")` | Add label |
| `label_del()` | `label_del(metric, "env")` | Remove label |

---

## Command Reference

### Instant Query

```bash
node $SCRIPT metrics query 'up{job="api"}'
node $SCRIPT metrics query 'sum(rate(http_requests_total[5m])) by (job)'
node $SCRIPT metrics query 'histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))'
```

### Range Query (time series)

```bash
node $SCRIPT metrics range 'rate(http_requests_total[5m])' --start 2h --step 1m
node $SCRIPT metrics range 'up{job="api"}' --start 24h --step 5m
```

### Metric Discovery

```bash
# List all metric names
node $SCRIPT metrics label-values __name__

# List all label names
node $SCRIPT metrics labels

# Find series matching a pattern
node $SCRIPT metrics series 'http_requests_total{job="api"}'
```

### Export Raw Data

```bash
node $SCRIPT metrics export 'http_requests_total{job="api"}' --start 1h
```

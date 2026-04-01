---
name: Trace Assertion Patterns
description: This skill should be used when writing Postman test script assertions for VictoriaTraces call chain verification, when the user asks to "assert trace path", "verify call chain", "check span relationships", "validate distributed trace", "query VictoriaTraces from Postman", or mentions trace/span verification in API tests.
---

# Trace Assertion Patterns for Postman Test Scripts

Provide templates for querying VictoriaTraces and asserting call chain structure within Postman test scripts.

## VictoriaTraces Connection

- **Endpoint**: `GET /select/jaeger/api/traces` on the `vtUrl` environment variable
- **Required param**: `service` (mandatory)
- **Time format**: `start`/`end` in microseconds
- **Headers**: `AccountID: 0`, `ProjectID: 0` (multi-tenancy)

## Pre-Request: Record Timestamp

```javascript
pm.environment.set('traceStartUs', Date.now() * 1000);
```

## Core Query Pattern

```javascript
var vtUrl = pm.environment.get('vtUrl');
var traceStartUs = pm.environment.get('traceStartUs');
var endUs = Date.now() * 1000;

var traceUrl = vtUrl + '/select/jaeger/api/traces?' +
    'service=' + encodeURIComponent('service-name') +
    '&start=' + traceStartUs +
    '&end=' + endUs +
    '&limit=5';

pm.sendRequest({
    url: traceUrl,
    method: 'GET',
    header: { 'AccountID': '0', 'ProjectID': '0' }
}, function (err, response) {
    var result = response.json();
    var traces = result.data || [];
    // assertions here
});
```

## Assertion Focus Areas

Trace assertions should focus on three key aspects:

1. **Span hierarchy completeness** — Verify all expected services/layers appear in the trace (API → Service → Repository)
2. **Key attribute existence** — Verify critical span attributes are present and have expected values
3. **No error spans** — Verify all spans have `status.statusCode = OK` (no `ERROR` status)

### 1. Verify Span Hierarchy (Completeness)
Assert all expected services/layers appear in the trace:
```javascript
var services = {};
spans.forEach(function (s) { services[s.process.serviceName] = true; });
pm.expect(services).to.include.all.keys(['api-gateway', 'order-service', 'order-repo']);
```

### 2. Verify Key Attributes (Existence)
```javascript
var rootSpan = spans.find(function (s) { return !s.parentSpanID || s.parentSpanID === '0'; });
pm.expect(rootSpan.tags['http.method']).to.eql('POST');
pm.expect(rootSpan.tags['http.status_code']).to.eql('200');
```

### 3. Verify No Error Spans (Health)
```javascript
var errorSpans = spans.filter(function (s) {
    return s.tags && s.tags['status.code'] === 'ERROR';
});
pm.expect(errorSpans).to.have.lengthOf(0, 'Found error spans: ' +
    errorSpans.map(function (s) { return s.operationName; }).join(', '));
```

### Verify Parent-Child Relationship
```javascript
pm.expect(childSpan.parentSpanID).to.eql(parentSpan.spanID);
```

## Standard Trace Test Block

Wrap in IIFE to avoid variable conflicts. Use `[TRACE]` prefix:

```javascript
// --- TRACE LAYER ---
(function () {
    var vtUrl = pm.environment.get('vtUrl');
    var traceStartUs = pm.environment.get('traceStartUs');
    if (!vtUrl || !traceStartUs) return;

    var traceUrl = vtUrl + '/select/jaeger/api/traces?' +
        'service=' + encodeURIComponent('target-service') +
        '&start=' + traceStartUs + '&end=' + (Date.now() * 1000) + '&limit=5';

    pm.sendRequest({
        url: traceUrl,
        method: 'GET',
        header: { 'AccountID': '0', 'ProjectID': '0' }
    }, function (err, response) {
        if (err) {
            pm.test('[TRACE] Query succeeded', function () {
                pm.expect.fail('Trace query failed: ' + err.message);
            });
            return;
        }
        var traces = (response.json().data || []);
        pm.test('[TRACE] Found trace', function () {
            pm.expect(traces.length).to.be.above(0);
        });
        if (!traces.length) return;
        var spans = traces[0].spans || [];
        pm.test('[TRACE] Call chain correct', function () {
            var svcs = {};
            spans.forEach(function (s) { svcs[s.process.serviceName] = true; });
            pm.expect(svcs).to.include.all.keys(['expected-service-a', 'expected-service-b']);
        });
    });
})();
```

## Naming Convention

Prefix all trace assertions with `[TRACE]` to distinguish from `[HTTP]` and `[LOG]` layers.

## Reference Files

For complete query and assertion patterns, consult:
- **`references/trace-query-patterns.md`** — Full patterns including operation filters, tags, duration, depth verification, dependency queries, span count, and complete assertion blocks

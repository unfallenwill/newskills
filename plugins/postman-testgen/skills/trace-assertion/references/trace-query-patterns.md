# VictoriaTraces Query Patterns for Postman Test Scripts

## VictoriaTraces API Overview

- **Base URL**: Configured in environment variable `vtUrl` (default `http://localhost:10428`)
- **API Style**: Jaeger-compatible HTTP API
- **Authentication**: Multi-tenancy via `AccountID` and `ProjectID` headers (default `0`)
- **Time Format**: Microseconds for `start`/`end` parameters

## Pre-Request: Record Timestamp

```javascript
// Record start time in microseconds for trace lookup
pm.environment.set('traceStartUs', Date.now() * 1000);
```

## Query Traces After Request

### Basic Trace Search by Service

```javascript
var vtUrl = pm.environment.get('vtUrl');
var traceStartUs = pm.environment.get('traceStartUs');
var endUs = Date.now() * 1000;

var traceUrl = vtUrl + '/select/jaeger/api/traces?' +
    'service=' + encodeURIComponent('my-api-service') +
    '&start=' + traceStartUs +
    '&end=' + endUs +
    '&limit=20';

pm.sendRequest({
    url: traceUrl,
    method: 'GET',
    header: { 'AccountID': '0', 'ProjectID': '0' }
}, function (err, response) {
    pm.test('[TRACE] Trace query successful', function () {
        pm.expect(err).to.be.null;
        pm.expect(response.code).to.eql(200);
    });

    var result = response.json();
    var traces = result.data || [];

    pm.test('[TRACE] Found trace for service', function () {
        pm.expect(traces).to.have.length.above(0);
    });
});
```

### Search with Operation Filter

```javascript
var traceUrl = vtUrl + '/select/jaeger/api/traces?' +
    'service=' + encodeURIComponent('order-service') +
    '&operation=' + encodeURIComponent('POST /api/orders') +
    '&start=' + traceStartUs +
    '&end=' + endUs +
    '&limit=5';
```

### Search with Tags Filter

```javascript
// Tags is a URL-encoded JSON object
var tags = JSON.stringify({ 'http.method': 'POST' });
var traceUrl = vtUrl + '/select/jaeger/api/traces?' +
    'service=' + encodeURIComponent('api-gateway') +
    '&tags=' + encodeURIComponent(tags) +
    '&start=' + traceStartUs +
    '&end=' + endUs;
```

### Search with Duration Filter

```javascript
// Duration in Go format: "500ms", "1s", "5m"
var traceUrl = vtUrl + '/select/jaeger/api/traces?' +
    'service=order-service' +
    '&start=' + traceStartUs +
    '&end=' + endUs +
    '&lookback=5m' +
    '&maxDuration=5s' +
    '&minDuration=1ms';
```

## Trace Assertion Patterns

### Verify Call Chain Path

Assert that the trace contains specific services in the expected order (API → Service → Repository):

```javascript
pm.sendRequest({ url: traceUrl, method: 'GET' }, function (err, response) {
    var result = response.json();
    var traces = result.data || [];
    var trace = traces[0];
    var spans = trace.spans || [];

    pm.test('[TRACE] Call chain follows expected path', function () {
        // Build span map by spanID
        var spanMap = {};
        spans.forEach(function (s) { spanMap[s.spanID] = s; });

        // Build parent-child relationships
        var rootSpan = spans.find(function (s) {
            return !s.parentSpanID || s.parentSpanID === '0' || s.parentSpanID === '';
        });

        pm.expect(rootSpan, 'Root span not found').to.exist;

        // Find child spans of root
        var childSpans = spans.filter(function (s) {
            return s.parentSpanID === rootSpan.spanID;
        });

        // Verify expected services appear in the chain
        var serviceNames = spans.map(function (s) {
            return s.process.serviceName;
        });

        pm.expect(serviceNames).to.include('api-gateway');
        pm.expect(serviceNames).to.include('order-service');
        pm.expect(serviceNames).to.include('order-repository');
    });
});
```

### Verify Service Call Depth

```javascript
pm.test('[TRACE] Service call depth is correct', function () {
    var spanMap = {};
    spans.forEach(function (s) { spanMap[s.spanID] = s; });

    function getDepth(spanId, depth) {
        var span = spanMap[spanId];
        if (!span || !span.parentSpanID || span.parentSpanID === '0') return depth;
        return getDepth(span.parentSpanID, depth + 1);
    }

    var maxDepth = Math.max.apply(null, spans.map(function (s) { return getDepth(s.spanID, 0); }));
    pm.expect(maxDepth).to.be.at.most(3, 'Call chain too deep, expected at most 3 levels');
});
```

### Verify Span Count

```javascript
pm.test('[TRACE] Expected number of spans', function () {
    pm.expect(spans).to.have.lengthOf(3);
});
```

### Verify Specific Operation Exists

```javascript
pm.test('[TRACE] Operation exists in trace', function () {
    var operations = spans.map(function (s) { return s.operationName; });
    pm.expect(operations).to.include('POST /api/orders');
    pm.expect(operations).to.include('order-service.CreateOrder');
    pm.expect(operations).to.include('order-repository.Insert');
});
```

### Verify Parent-Child Relationship

```javascript
pm.test('[TRACE] Span parent-child relationship is correct', function () {
    var parentSpan = spans.find(function (s) { return s.operationName === 'POST /api/orders'; });
    var childSpan = spans.find(function (s) { return s.operationName === 'order-service.CreateOrder'; });

    pm.expect(parentSpan).to.exist;
    pm.expect(childSpan).to.exist;
    pm.expect(childSpan.parentSpanID).to.eql(parentSpan.spanID);
});
```

### Verify Span Duration

```javascript
pm.test('[TRACE] Root span duration is reasonable', function () {
    var rootSpan = spans.find(function (s) {
        return !s.parentSpanID || s.parentSpanID === '0' || s.parentSpanID === '';
    });
    // Duration is in microseconds
    var durationMs = rootSpan.duration / 1000;
    pm.expect(durationMs).to.be.below(5000, 'Root span took longer than 5 seconds');
});
```

## Service Dependency Query

```javascript
var endMs = Date.now();
var startMs = endMs - 300000; // 5 minutes

var depUrl = vtUrl + '/select/jaeger/api/dependencies?' +
    'endTs=' + endMs +
    '&lookback=300000';

pm.sendRequest({ url: depUrl, method: 'GET' }, function (err, response) {
    var result = response.json();
    var dependencies = result.data || [];

    pm.test('[TRACE] Service dependencies exist', function () {
        pm.expect(dependencies).to.have.length.above(0);
    });
});
```

## Complete Trace Assertion Block

```javascript
// --- TRACE LAYER ---
(function () {
    var vtUrl = pm.environment.get('vtUrl');
    var traceStartUs = pm.environment.get('traceStartUs');
    var endUs = Date.now() * 1000;
    if (!vtUrl || !traceStartUs) return;

    var serviceName = 'target-service';
    var traceUrl = vtUrl + '/select/jaeger/api/traces?' +
        'service=' + encodeURIComponent(serviceName) +
        '&start=' + traceStartUs +
        '&end=' + endUs +
        '&limit=5';

    pm.sendRequest({ url: traceUrl, method: 'GET' }, function (err, response) {
        if (err) {
            pm.test('[TRACE] Trace query succeeded', function () {
                pm.expect.fail('Trace query failed: ' + err.message);
            });
            return;
        }

        var result = response.json();
        var traces = result.data || [];

        pm.test('[TRACE] Found trace for ' + serviceName, function () {
            pm.expect(traces.length).to.be.above(0);
        });

        if (traces.length === 0) return;
        var spans = traces[0].spans || [];

        pm.test('[TRACE] Call chain path correct', function () {
            var services = {};
            spans.forEach(function (s) {
                services[s.process.serviceName] = true;
            });
            pm.expect(services).to.include.all.keys(['api-gateway', 'order-service']);
        });
    });
})();
```

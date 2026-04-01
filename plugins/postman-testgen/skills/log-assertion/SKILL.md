---
name: Log Assertion Patterns
description: This skill should be used when writing Postman test script assertions for VictoriaLogs business log verification, when the user asks to "assert log events", "verify business logs", "check domain.action logs", "query VictoriaLogs from Postman", "validate log entries", or mentions business log verification in API tests.
---

# Log Assertion Patterns for Postman Test Scripts

Provide templates for querying VictoriaLogs and asserting business log events within Postman test scripts.

## VictoriaLogs Connection

- **Endpoint**: `POST /select/logsql/query` on the `vlUrl` environment variable
- **Query language**: LogsQL
- **Content-Type**: `application/x-www-form-urlencoded`
- **Headers**: `AccountID: 0`, `ProjectID: 0` (multi-tenancy)
- **Response**: JSON lines stream (one JSON object per line)

## Pre-Request: Record Timestamp

```javascript
pm.environment.set('logStartTime', new Date().toISOString());
```

## Core Query Pattern

```javascript
var vlUrl = pm.environment.get('vlUrl');
var logStart = pm.environment.get('logStartTime');

pm.sendRequest({
    url: vlUrl + '/select/logsql/query',
    method: 'POST',
    header: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'AccountID': '0', 'ProjectID': '0'
    },
    body: {
        mode: 'urlencoded',
        urlencoded: [
            { key: 'query', value: 'service:service-name' },
            { key: 'start', value: logStart },
            { key: 'limit', value: '100' }
        ]
    }
}, function (err, response) {
    var logs = response.text().trim().split('\n')
        .filter(function (l) { return l; })
        .map(function (l) { return JSON.parse(l); });
    // assertions here
});
```

## Assertion Focus Areas

Log assertions should focus on three key aspects:

1. **Event name existence** — Required business events must appear (e.g., `order.created` must exist)
2. **Extra field completeness** — Key fields must have values (e.g., `order_id`, `status` must be present and non-empty)
3. **Severity correctness** — Log level matches business context (normal flow = `INFO`, not_found = `WARNING`, errors = `ERROR`)

### 1. Assert Event Name Exists
```javascript
var eventLogs = logs.filter(function (l) { return l._msg && l._msg.includes('order.created'); });
pm.expect(eventLogs.length).to.be.above(0, 'order.created event not found in logs');
```

### 2. Assert Extra Field Completeness
Verify key business fields exist and have non-empty values:
```javascript
var event = logs.find(function (l) { return l._msg && l._msg.includes('order.created'); });
pm.expect(event, 'Event not found').to.exist;
pm.expect(event.order_id, 'order_id is missing or empty').to.exist.and.to.not.be.empty;
pm.expect(event.status, 'status is missing or empty').to.exist.and.to.not.be.empty;
```

### 3. Assert Severity Correctness
```javascript
// Normal flow should be INFO
pm.expect(event.level).to.eql('INFO');
// not_found scenarios should be WARNING
pm.expect(notFoundEvent.level).to.eql('WARNING');
// No unexpected ERROR logs during normal flow
var errors = logs.filter(function (l) { return l.level === 'ERROR'; });
pm.expect(errors).to.have.lengthOf(0);
```

### Assert domain.action Fields
```javascript
var match = logs.filter(function (l) {
    return l.domain === 'order' && l.action === 'created';
});
pm.expect(match.length).to.be.above(0, 'domain=order action=created not found');
```

## Standard Log Test Block

Wrap in IIFE. Use `[LOG]` prefix:

```javascript
// --- LOG LAYER ---
(function () {
    var vlUrl = pm.environment.get('vlUrl');
    var logStart = pm.environment.get('logStartTime');
    if (!vlUrl || !logStart) return;

    var logQuery = 'service:target-service';

    pm.sendRequest({
        url: vlUrl + '/select/logsql/query',
        method: 'POST',
        header: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'AccountID': '0', 'ProjectID': '0'
        },
        body: {
            mode: 'urlencoded',
            urlencoded: [
                { key: 'query', value: logQuery },
                { key: 'start', value: logStart },
                { key: 'limit', value: '100' }
            ]
        }
    }, function (err, response) {
        if (err) {
            pm.test('[LOG] Query succeeded', function () {
                pm.expect.fail('Log query failed: ' + err.message);
            });
            return;
        }
        var text = response.text().trim();
        if (!text) {
            pm.test('[LOG] Found logs', function () {
                pm.expect.fail('No logs returned');
            });
            return;
        }
        var logs = text.split('\n')
            .filter(function (l) { return l; })
            .map(function (l) { try { return JSON.parse(l); } catch(e) { return null; } })
            .filter(function (l) { return l; });

        pm.test('[LOG] Found logs for service', function () {
            pm.expect(logs.length).to.be.above(0);
        });

        pm.test('[LOG] No error-level logs', function () {
            var errors = logs.filter(function (l) { return l.level === 'error'; });
            pm.expect(errors).to.have.lengthOf(0);
        });
    });
})();
```

## Naming Convention

Prefix all log assertions with `[LOG]` to distinguish from `[HTTP]` and `[TRACE]` layers.

## Reference Files

For complete query and assertion patterns, consult:
- **`references/log-query-patterns.md`** — Full patterns including domain.action filtering, trace ID correlation, log order verification, structured field checks, hit stats, and complete assertion blocks

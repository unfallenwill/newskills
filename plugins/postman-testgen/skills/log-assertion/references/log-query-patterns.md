# VictoriaLogs Query Patterns for Postman Test Scripts

## VictoriaLogs API Overview

- **Base URL**: Configured in environment variable `vlUrl` (default `http://localhost:9428`)
- **Query Endpoint**: `POST /select/logsql/query`
- **Query Language**: LogsQL
- **Authentication**: Multi-tenancy via `AccountID` and `ProjectID` headers (default `0`)
- **Response**: JSON lines stream (one JSON object per line)
- **Time params**: `start`/`end` accept relative (`5m`, `1h`), RFC3339, or unix timestamp

## Pre-Request: Record Timestamp

```javascript
pm.environment.set('logStartTime', new Date().toISOString());
```

## Query Logs After Request

### Basic Log Query

```javascript
var vlUrl = pm.environment.get('vlUrl');
var logStart = pm.environment.get('logStartTime');

pm.sendRequest({
    url: vlUrl + '/select/logsql/query',
    method: 'POST',
    header: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'AccountID': '0',
        'ProjectID': '0'
    },
    body: {
        mode: 'urlencoded',
        urlencoded: [
            { key: 'query', value: 'service:order-service' },
            { key: 'start', value: logStart },
            { key: 'limit', value: '50' }
        ]
    }
}, function (err, response) {
    pm.test('[LOG] Log query successful', function () {
        pm.expect(err).to.be.null;
        pm.expect(response.code).to.eql(200);
    });

    var logs = response.text().trim().split('\n')
        .filter(function (line) { return line; })
        .map(function (line) { return JSON.parse(line); });

    pm.test('[LOG] Found logs for service', function () {
        pm.expect(logs.length).to.be.above(0);
    });
});
```

### Query by domain.action Pattern

```javascript
var logQuery = 'service:order-service AND _msg:"order.created"';
// Or using structured fields:
var logQuery = 'service:order-service AND domain:"order" AND action:"created"';
```

### Query with Time Range

```javascript
var logStart = pm.environment.get('logStartTime');
var logEnd = new Date().toISOString();

body.urlencoded: [
    { key: 'query', value: logQuery },
    { key: 'start', value: logStart },
    { key: 'end', value: logEnd },
    { key: 'limit', value: '100' }
]
```

### Query by Log Level

```javascript
var logQuery = 'service:order-service AND level:error';
var logQuery = 'service:order-service AND level:info OR level:warn';
```

### Query with Trace ID Correlation

```javascript
var traceId = pm.environment.get('currentTraceId');
var logQuery = 'trace_id:' + traceId;
```

### Query with Field Filtering

```javascript
// LogsQL supports field:value syntax
var logQuery = 'service:payment-service AND event:"payment.completed" AND amount:>100';
```

## Log Assertion Patterns

### Assert Business Event Exists

```javascript
pm.test('[LOG] Business event logged', function () {
    var eventLogs = logs.filter(function (log) {
        return log._msg && log._msg.includes('order.created');
    });
    pm.expect(eventLogs.length).to.be.above(0, 'Expected order.created event in logs');
});
```

### Assert Domain Action

```javascript
pm.test('[LOG] domain.action event present', function () {
    var matchLogs = logs.filter(function (log) {
        return log.domain === 'order' && log.action === 'created';
    });
    pm.expect(matchLogs.length).to.be.above(0, 'Expected domain=order action=created');
});
```

### Assert Extra Fields

```javascript
pm.test('[LOG] Log contains expected extra fields', function () {
    var eventLogs = logs.filter(function (l) {
        return l._msg && l._msg.includes('order.created');
    });
    pm.expect(eventLogs.length).to.be.above(0);

    var log = eventLogs[0];
    pm.expect(log).to.have.property('orderId');
    pm.expect(log).to.have.property('userId');
    pm.expect(log.status).to.eql('success');
});
```

### Assert No Error Logs

```javascript
pm.test('[LOG] No error logs during request', function () {
    var errorLogs = logs.filter(function (l) {
        return l.level === 'error' || l.severity === 'ERROR';
    });
    pm.expect(errorLogs).to.have.lengthOf(0, 'Found unexpected error logs: ' +
        errorLogs.map(function (l) { return l._msg; }).join(', '));
});
```

### Assert Log Order

```javascript
pm.test('[LOG] Events in correct sequence', function () {
    var events = logs
        .filter(function (l) { return l.event; })
        .map(function (l) { return l.event; });

    var createIdx = events.indexOf('order.created');
    var confirmIdx = events.indexOf('order.confirmed');
    pm.expect(createIdx).to.be.above(-1, 'order.created event missing');
    pm.expect(confirmIdx).to.be.above(-1, 'order.confirmed event missing');
    pm.expect(confirmIdx).to.be.above(createIdx, 'order.confirmed should come after order.created');
});
```

### Assert Log Count

```javascript
pm.test('[LOG] Expected number of log entries', function () {
    pm.expect(logs).to.have.lengthOf(3);
});
```

### Assert Structured Log Fields

```javascript
pm.test('[LOG] Log entry has required structured fields', function () {
    var entry = logs.find(function (l) {
        return l._msg && l._msg.includes('order.created');
    });
    pm.expect(entry, 'Log entry not found').to.exist;

    // Verify all expected fields
    var requiredFields = ['timestamp', 'service', 'trace_id', 'span_id', 'level'];
    requiredFields.forEach(function (field) {
        pm.expect(entry).to.have.property(field, 'Missing required field: ' + field);
    });
});
```

## Complete Log Assertion Block

```javascript
// --- LOG LAYER ---
(function () {
    var vlUrl = pm.environment.get('vlUrl');
    var logStart = pm.environment.get('logStartTime');
    if (!vlUrl || !logStart) return;

    var serviceName = 'target-service';
    var logQuery = 'service:' + serviceName;

    pm.sendRequest({
        url: vlUrl + '/select/logsql/query',
        method: 'POST',
        header: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'AccountID': '0',
            'ProjectID': '0'
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
            pm.test('[LOG] Log query succeeded', function () {
                pm.expect.fail('Log query failed: ' + err.message);
            });
            return;
        }

        var text = response.text().trim();
        if (!text) {
            pm.test('[LOG] Found logs for ' + serviceName, function () {
                pm.expect.fail('No logs returned for query: ' + logQuery);
            });
            return;
        }

        var logs = text.split('\n')
            .filter(function (l) { return l; })
            .map(function (l) { try { return JSON.parse(l); } catch(e) { return null; } })
            .filter(function (l) { return l; });

        pm.test('[LOG] Found logs for ' + serviceName, function () {
            pm.expect(logs.length).to.be.above(0);
        });

        pm.test('[LOG] No error-level logs', function () {
            var errors = logs.filter(function (l) {
                return l.level === 'error' || l.severity === 'ERROR';
            });
            pm.expect(errors).to.have.lengthOf(0);
        });
    });
})();
```

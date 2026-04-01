---
name: HTTP Assertion Patterns
description: This skill should be used when writing Postman test script assertions for HTTP responses, when the user asks to "assert status code", "validate response body", "check response headers", "extract variables from response", "write pm.test assertions", or mentions HTTP response verification in Postman test scripts.
---

# HTTP Assertion Patterns for Postman Test Scripts

Provide assertion templates for verifying HTTP responses in Postman test scripts.

## Pre-Request: Record Timestamp

Always record request start time for downstream trace/log queries:

```javascript
pm.environment.set('requestStartTime', new Date().toISOString());
pm.environment.set('traceStartUs', Date.now() * 1000);
```

## Core Assertion Patterns

### Status Code
```javascript
pm.test('[HTTP] Status is 200', function () {
    pm.response.to.have.status(200);
});
```

### Response Body
```javascript
var json = pm.response.json();
pm.test('[HTTP] Has required fields', function () {
    pm.expect(json).to.have.property('id');
    pm.expect(json.name).to.eql('expected value');
});
```

### Array Response
```javascript
pm.test('[HTTP] Response is non-empty array', function () {
    var json = pm.response.json();
    pm.expect(json).to.be.an('array').that.is.not.empty;
});
```

### Response Headers
```javascript
pm.test('[HTTP] Content-Type is JSON', function () {
    pm.expect(pm.response.headers.get('Content-Type')).to.include('application/json');
});
```

## Variable Extraction

Extract values for downstream requests after assertions pass:

```javascript
var json = pm.response.json();
pm.environment.set('createdId', json.id);
pm.environment.set('token', json.accessToken);
```

## Standard HTTP Test Block

Use `[HTTP]` prefix in test names for consistent identification across three-layer output:

```javascript
// 1. Status
pm.test('[HTTP] Status is 200', function () {
    pm.response.to.have.status(200);
});

// 2. Body structure
var json = pm.response.json();
pm.test('[HTTP] Has required fields', function () {
    pm.expect(json).to.have.property('id');
    pm.expect(json).to.have.property('name');
});

// 3. Extract for downstream
pm.environment.set('resourceId', json.id);
```

## Naming Convention

Prefix all HTTP assertions with `[HTTP]` to distinguish from `[TRACE]` and `[LOG]` layers in test output.

## Reference Files

For comprehensive assertion templates, consult:
- **`references/assertion-patterns.md`** — Complete patterns including schema validation, array checks, header assertions, pre-request scripts, and composite test blocks

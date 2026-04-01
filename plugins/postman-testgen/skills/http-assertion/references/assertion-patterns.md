# HTTP Assertion Patterns for Postman Test Scripts

## Status Code Assertions

### Exact Status Code
```javascript
pm.test('Status code is 200', function () {
    pm.response.to.have.status(200);
});
```

### Status Code Range
```javascript
pm.test('Status code is 2xx', function () {
    pm.expect(pm.response.code).to.be.within(200, 299);
});
```

### Common Status Checks
```javascript
pm.test('Response is OK', function () { pm.response.to.be.ok; });
pm.test('Response is created', function () { pm.response.to.have.status(201); });
pm.test('Response is no content', function () { pm.response.to.have.status(204); });
pm.test('Response is bad request', function () { pm.response.to.have.status(400); });
pm.test('Response is not found', function () { pm.response.to.have.status(404); });
```

## Response Body Assertions

### JSON Body Field
```javascript
pm.test('Response contains expected field', function () {
    var json = pm.response.json();
    pm.expect(json).to.have.property('id');
    pm.expect(json.name).to.eql('expected name');
});
```

### Nested JSON
```javascript
pm.test('Nested field matches', function () {
    var json = pm.response.json();
    pm.expect(json.data.user.email).to.eql('test@example.com');
});
```

### Array Response
```javascript
pm.test('Response is non-empty array', function () {
    var json = pm.response.json();
    pm.expect(json).to.be.an('array').that.is.not.empty;
});

pm.test('Array has expected length', function () {
    var json = pm.response.json();
    pm.expect(json).to.have.lengthOf(3);
});

pm.test('Array item contains fields', function () {
    var json = pm.response.json();
    json.forEach(function (item) {
        pm.expect(item).to.include.all.keys('id', 'name');
    });
});
```

### JSON Schema Validation
```javascript
pm.test('Response matches schema', function () {
    var json = pm.response.json();
    var schema = {
        type: 'object',
        required: ['id', 'name', 'status'],
        properties: {
            id: { type: 'integer' },
            name: { type: 'string' },
            status: { type: 'string', enum: ['active', 'inactive'] }
        }
    };
    pm.expect(tv4.validate(json, schema)).to.be.true;
});
```

### String Body
```javascript
pm.test('Body contains text', function () {
    pm.expect(pm.response.text()).to.include('expected substring');
});
```

## Response Header Assertions

```javascript
pm.test('Content-Type is JSON', function () {
    pm.response.to.have.header('Content-Type');
    pm.expect(pm.response.headers.get('Content-Type')).to.include('application/json');
});

pm.test('Has correlation header', function () {
    pm.expect(pm.response.headers.get('X-Request-Id')).to.exist;
});
```

## Variable Extraction

### Extract and Set Environment Variable
```javascript
var json = pm.response.json();
pm.environment.set('userId', json.id);
pm.environment.set('userToken', json.token);
pm.environment.set('resourceUrl', json._links.self.href);
```

### Extract from Array
```javascript
var json = pm.response.json();
pm.environment.set('firstItemId', json.data[0].id);
```

### Extract from Header
```javascript
pm.environment.set('locationHeader', pm.response.headers.get('Location'));
```

### Set Collection Variable
```javascript
pm.collectionVariables.set('sharedValue', json.value);
```

## Pre-Request Script Patterns

### Record Timestamp
```javascript
pm.environment.set('requestStartTime', new Date().toISOString());
```

### Record Microsecond Timestamp (for VictoriaTraces)
```javascript
pm.environment.set('requestStartUs', Date.now() * 1000);
```

### Conditional Request
```javascript
if (!pm.environment.get('authToken')) {
    // Skip request or set default
    pm.environment.set('authToken', 'default-token');
}
```

## Composite Test Pattern (HTTP Layer)

Complete HTTP assertion block for a typical API test:

```javascript
// 1. Status code
pm.test('[HTTP] Status is 200', function () {
    pm.response.to.have.status(200);
});

// 2. Content type
pm.test('[HTTP] Response is JSON', function () {
    pm.expect(pm.response.headers.get('Content-Type')).to.include('application/json');
});

// 3. Body structure
pm.test('[HTTP] Response has required fields', function () {
    var json = pm.response.json();
    pm.expect(json).to.have.property('id');
    pm.expect(json).to.have.property('name');
    pm.expect(json).to.have.property('createdAt');
});

// 4. Value assertions
pm.test('[HTTP] Field values match expectations', function () {
    var json = pm.response.json();
    pm.expect(json.status).to.eql('active');
    pm.expect(json.name).to.be.a('string');
});

// 5. Extract variables for downstream
var json = pm.response.json();
pm.environment.set('createdId', json.id);
```

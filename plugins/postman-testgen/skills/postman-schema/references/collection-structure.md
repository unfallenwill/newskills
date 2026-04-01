# Postman Collection v2.1.0 Structure Reference

## Minimal Valid Collection

```json
{
  "info": {
    "name": "Collection Name",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": []
}
```

## Complete Collection Structure

### Top-Level Fields

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `info` | Yes | object | Collection metadata |
| `item` | Yes | array | Array of items (requests) or item-groups (folders) |
| `variable` | No | array | Collection-level variables |
| `event` | No | array | Collection-level scripts (pre-request, test) |
| `auth` | No | object | Default authentication for all requests |
| `protocolProfileBehavior` | No | object | Request behavior overrides |

### Info Object

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `name` | Yes | string | Collection display name |
| `schema` | Yes | string | Must be `https://schema.getpostman.com/json/collection/v2.1.0/collection.json` |
| `_postman_id` | No | string | UUID identifier |
| `description` | No | string/object | Description text or `{content, type}` |
| `version` | No | object | `{major, minor, patch, identifier}` |

### Item (Request) Object

```json
{
  "id": "uuid-string",
  "name": "Request Name",
  "request": {
    "method": "GET",
    "url": { ... },
    "header": [ ... ],
    "body": { ... },
    "auth": { ... },
    "description": "..."
  },
  "response": [],
  "event": [ ... ],
  "variable": [ ... ]
}
```

### Item-Group (Folder) Object

Folders nest recursively — `item` array can contain both items and sub-folders.

```json
{
  "name": "Folder Name",
  "description": "...",
  "item": [ ... ],
  "event": [ ... ],
  "variable": [ ... ],
  "auth": { ... }
}
```

### Request Object Detail

**Method**: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS`, `COPY`, `LOCK`, `UNLOCK`, `MKCOL`, `MOVE`, `PROPFIND`, `PROPPATCH`, `PURGE`, `REPORT`, `SEARCH`, `UNLINK`, `LINK`, `TRACE`

**URL** — string shorthand or object:
```json
{
  "raw": "https://api.example.com/users/:id?page=1",
  "protocol": "https",
  "host": ["api", "example", "com"],
  "port": "443",
  "path": ["users", ":id"],
  "query": [{ "key": "page", "value": "1", "disabled": false }],
  "variable": [{ "key": "id", "value": "123" }],
  "hash": ""
}
```

**Header**: Array of `{key, value, disabled, description}` objects.

**Body** — modes: `raw`, `urlencoded`, `formdata`, `file`, `graphql`:
```json
{
  "mode": "raw",
  "raw": "{\"key\": \"value\"}",
  "options": { "raw": { "language": "json" } }
}
```

```json
{
  "mode": "urlencoded",
  "urlencoded": [{ "key": "field", "value": "val", "type": "text" }]
}
```

```json
{
  "mode": "formdata",
  "formdata": [{ "key": "file", "type": "file", "src": "/path/to/file" }]
}
```

### Event Object (Scripts)

```json
{
  "listen": "prerequest",
  "script": {
    "type": "text/javascript",
    "exec": ["// script lines", "var x = 1;"]
  }
}
```

```json
{
  "listen": "test",
  "script": {
    "type": "text/javascript",
    "exec": ["pm.test('Name', function() {", "    pm.response.to.have.status(200);", "});"]
  }
}
```

- `exec`: Array of strings (one per line) OR single string
- Events can be at collection, folder, or item level
- `prerequest` runs before request, `test` runs after

### Variable Object

```json
{ "key": "baseUrl", "value": "https://api.example.com", "type": "string" }
{ "key": "token", "value": "", "type": "string" }
```

Types: `string`, `boolean`, `any`, `number`

Scope hierarchy: Collection > Folder > Item

Referenced via `{{variableName}}` anywhere in the collection.

### Auth Object

```json
{
  "type": "bearer",
  "bearer": [{ "key": "token", "value": "{{accessToken}}", "type": "string" }]
}
```

Supported types: `apikey`, `awsv4`, `basic`, `bearer`, `digest`, `edgegrid`, `hawk`, `noauth`, `oauth1`, `oauth2`, `ntlm`

Each type has a matching property with array of `{key, value, type}` objects.

## Environment File Structure

Environment files are separate JSON files used with newman's `-e` flag:

```json
{
  "id": "uuid",
  "name": "dev",
  "values": [
    { "key": "baseUrl", "value": "http://localhost:8080", "type": "default", "enabled": true },
    { "key": "vtUrl", "value": "http://localhost:10428", "type": "default", "enabled": true },
    { "key": "vlUrl", "value": "http://localhost:9428", "type": "default", "enabled": true },
    { "key": "requestStartTime", "value": "", "type": "any", "enabled": true }
  ],
  "_postman_variable_scope": "environment",
  "_postman_exported_at": "2024-01-01T00:00:00.000Z",
  "_postman_exported_using": "Postman/10.0.0"
}
```

## Newman Execution

```bash
npx -y newman run collection.json -e environment.json
```

Common flags:
- `-n <count>` — iteration count
- `-d <file>` — iteration data (JSON/CSV)
- `--folder <name>` — run specific folder
- `--bail` — stop on first failure
- `--timeout-request <ms>` — request timeout
- `-r cli,json` — reporters
- `--reporter-json-export results.json` — JSON report output
- `--suppress-exit-code` — don't fail on test errors

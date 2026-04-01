---
name: Postman Collection Schema
description: This skill should be used when generating, validating, or editing Postman Collection v2.1.0 JSON files, when writing Postman test scripts (pre-request or test events), when structuring collection items, folders, variables, or auth configuration, or when the user asks to "create a postman collection", "generate postman tests", "validate collection format", or mentions "postman schema" or "v2.1.0".
---

# Postman Collection v2.1.0 Schema

Provide authoritative structure knowledge for generating valid Postman Collection v2.1.0 JSON.

## Collection Structure Essentials

A valid collection requires two top-level fields: `info` and `item`.

```json
{
  "info": {
    "name": "Collection Name",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [],
  "variable": [],
  "event": []
}
```

### Key Rules

- `info.schema` must be exactly `https://schema.getpostman.com/json/collection/v2.1.0/collection.json`
- `item` is a recursive array — elements are either items (requests) or item-groups (folders)
- Folders nest via their own `item` array, supporting unlimited depth
- `event`, `variable`, and `auth` attach at collection, folder, or item level — inner levels override outer
- Variables referenced via `{{variableName}}` syntax

## Item (Request) Structure

Each item must have a `name` and `request`:

```json
{
  "name": "Request Name",
  "request": {
    "method": "GET",
    "url": { "raw": "{{baseUrl}}/path", "host": ["{{baseUrl}}"], "path": ["path"] },
    "header": [{ "key": "Content-Type", "value": "application/json" }],
    "body": { "mode": "raw", "raw": "{}", "options": { "raw": { "language": "json" } } }
  },
  "event": [
    { "listen": "prerequest", "script": { "type": "text/javascript", "exec": ["// code"] } },
    { "listen": "test", "script": { "type": "text/javascript", "exec": ["// code"] } }
  ]
}
```

Body modes: `raw`, `urlencoded`, `formdata`, `file`, `graphql`.

## Event System

Events carry scripts executed at specific lifecycle points:
- `prerequest` — runs before the HTTP request is sent
- `test` — runs after the response is received

`exec` is an array of strings (one per line) or a single string. Scripts use Postman's `pm` object.

## Variable System

Three scopes with inheritance: Collection > Folder > Item.

```json
{ "key": "baseUrl", "value": "http://localhost:8080", "type": "string" }
{ "key": "vtUrl", "value": "http://localhost:10428", "type": "string" }
{ "key": "vlUrl", "value": "http://localhost:9428", "type": "string" }
```

Types: `string`, `boolean`, `any`, `number`.

## Environment File Structure

Separate JSON file passed to newman via `-e` flag:

```json
{
  "id": "uuid",
  "name": "dev",
  "values": [
    { "key": "baseUrl", "value": "http://localhost:8080", "type": "default", "enabled": true },
    { "key": "vtUrl", "value": "http://localhost:10428", "type": "default", "enabled": true },
    { "key": "vlUrl", "value": "http://localhost:9428", "type": "default", "enabled": true }
  ],
  "_postman_variable_scope": "environment"
}
```

## Newman Execution

```bash
npx -y newman run collection.json -e environment.json --bail
```

Common flags: `-n` iterations, `-d` data file, `--folder` run specific folder, `-r` reporters, `--suppress-exit-code`.

## Schema Validation

After generating a collection, validate structure by checking:
1. `info.name` exists and is non-empty
2. `info.schema` matches the v2.1.0 URL exactly
3. Every item has `name` and `request`
4. Every request has `method` and `url`
5. All `event` objects have `listen` and `script.exec`
6. No trailing commas or invalid JSON

## Reference Files

For complete field reference and examples, consult:
- **`references/collection-structure.md`** — Full schema with all fields, body modes, auth types, environment format, and newman flags

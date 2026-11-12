# Services Adapter Layer

This directory contains adapter implementations for different service health check methods.

## Purpose

Each adapter checks a service's health and reports in the **unified schema**:

```json
{
  "service_name": "...",
  "check_method": "<port|http|docker>",
  "status": "ok|failed|timeout",
  "port": <number|null>,
  "latency_ms": <number>,
  "error_message": "...",
  "timestamp": "ISO8601"
}
```

## Supported Check Methods (to be implemented)

- **port-check** - TCP port connectivity test (netcat/ss)
- **http-health** - HTTP GET to health endpoint
- **docker-inspect** - Docker container status via API

## Adapter Pattern

Each adapter should:
1. Attempt the appropriate health check method
2. Measure response time if possible
3. Classify result as ok/failed/timeout
4. Output structured JSON or log entry

## Implementation Status

- [x] port-check (basic TCP connect)
- [x] http-health (curl/Wget based)
- [x] docker-inspect (Docker API only if available)

See `README.md` in parent directory for overall architecture.

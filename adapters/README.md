# Adapters Directory

This directory contains **adapter implementations** for different scheduler and service types.

## Architecture Overview

```
                    ┌─────────────┐
                    │  AJD Core   │
                    │   (app.py)  │
                    └──────┬──────┘
                           │
           ┌──────────────┼──────────────┐
           ↓              ↓              ↓
    ┌──────────┐  ┌──────────┐  ┌──────────┐
    │ Scheduler│  │ Adapter  │  │ Service  │
    │   API    │  │ Layer    │  │ Checker  │
    └────┬─────┘  └────┬─────┘  └────┬─────┘
         │             │              │
    ┌────┴─────────────┴──────────────┴─────────┐
    │              Unified Adapter Layer         │
    │                                           │
    │   crontab  → crontab_adapter.py            │
    │   launchd  → launchd_adapter.py            │
    │   systemd  → systemd_adapter.py            │
    │   hermes   → hermes_adapter.py             │
    │                                           │
    │   port-check  → port_check.sh              │
    │   http-health → http_health.sh             │
    │   docker     → docker_check.sh             │
    └───────────────────────────────────────────┘
                           ↓
                    Unified JSON Schema Output
```

## Adapter Contract

All adapters must produce output conforming to this schema:

### Scheduler Adapter Output
```json
{
  "source": "crontab",
  "job_name": "daily-news-report",
  "cron_expression": "0 9 * * *",
  "status": "ok",
  "note": "Job completed successfully",
  "timestamp": "2026-11-12T02:30:00Z"
}
```

### Service Check Adapter Output  
```json
{
  "service_name": "my-api",
  "check_method": "http-health",
  "status": "ok",
  "port": 5080,
  "latency_ms": 42,
  "error_message": null,
  "timestamp": "2026-11-12T02:30:00Z"
}
```

## Implementation Guidelines

1. **Pure shell scripts preferred** - Avoid dependencies beyond coreutils
2. **Exit codes**: 0 = ok, 1 = failed, 2 = timeout  
3. **Output format**: JSON to stdout or append to log file
4. **No external network calls** except health checks themselves
5. **Document assumptions** in docstring/header comments

## Directory Structure

- `schedulers/` - Scheduler parsing adapters (all 4 implemented)
- `services/` - Service health check adapters (all 3 implemented)
- `utils/` - Shared helper functions (to be created)

## Testing

Each adapter should:
1. Have a `.test.sh` or `_test.py` companion file
2. Include integration test cases in Phase 8 validation suite
3. Be tested against real cron/scheduler outputs

## Next Steps

1. ~~Implement `crontab_adapter.py` (parse crontab logs)~~ ✅ Done
2. ~~Implement `launchd_adapter.py` (read launchctl output)~~ ✅ Done
3. ~~Implement `port_check.sh` (TCP connect test)~~ ✅ Done
4. ~~Add to Phase 8 validation suite~~ (Phase 11)
5. Create adapter registry and load mechanism (Phase 13)
6. Integration tests for all adapters

# Schedulers Adapter Layer

This directory contains adapter implementations for different scheduling sources.

## Purpose

Each adapter converts scheduler-specific output into the **unified schema** that AJD core expects:

```json
{
  "source": "<scheduler_type>",
  "job_name": "...",
  "cron_expression": "...",
  "status": "ok|failed|timeout",
  "note": "...",
  "timestamp": "ISO8601"
}
```

## Supported Schedulers (to be implemented)

- **crontab** - Linux/macOS crontab parsing
- **launchd** - macOS launchd jobs
- **systemd-timer** - systemd timer units
- **hermes-cron** - Hermes cron job tracker

## Adapter Pattern

Each adapter should:
1. Parse scheduler-specific logs/outputs
2. Extract job name, cron expression, status
3. Normalize to unified schema
4. Output as JSON or structured log

## Implementation Status

- [x] crontab
- [x] launchd
- [x] systemd-timer
- [x] hermes-cron

See `README.md` in parent directory for overall architecture.

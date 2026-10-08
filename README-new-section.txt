## Why Do I Care About Heartbeats? 🎯

**This is AJD's soul.** Use `phase6_test.sh` to simulate failures and see the alerts in action.

### The Problem: Cron Lies by Omission

```bash
# A job runs at 00:02, finishes with errors but exits code=0
crontab -l | grep ... && "Job scheduled ✅"
```

Without heartbeats, you only see the silence after failure. You won't notice a broken report for days.

### The Solution: Heartbeat API

```bash
curl -X POST http://localhost:5080/api/heartbeat \
     -H 'Content-Type: application/json' \
     -d '{"job":"daily-report","status":"ok","note":"3.2MB"}'
```

### What You Get

| Condition | Without Heartbeats | With Heartbeats |
|-----------|-------------------|------------------|
| Job succeeds | ✓ Visible in dashboard | ✓ + stored result |
| Crashes with error code 0 | ❌ Silent failure until manual check | ⚠️ Immediately flagged |
| Hangs / dies partway | ❌ Never detected | ⚠️ Dead silent = anomaly |

### The Key Insight

> **"Ran but no heartbeat" is the most valuable alert.**
>
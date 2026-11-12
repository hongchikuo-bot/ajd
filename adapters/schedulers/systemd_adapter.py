#!/usr/bin/env python3
"""
Systemd Timer Adapter - Parse and validate systemd timer units.

Output format (unified):
{
    "source": "systemd-timer",
    "job_name": "daily-report.timer",
    "cron_expression": "0 9 * * *",
    "status": "ok",
    "note": "Timer active, next run: 2026-11-13 09:00:00",
    "timestamp": "2026-11-12T02:30:00Z"
}

Supported timer types:
- OnCalendar (calendar events, systemd time format)
- OnBootSec, OnStartupSec, OnUnitActiveSec, OnUnitInactiveSec (monotonic timers)
- AccuracySec, RandomizedDelaySec

Usage: python3 systemd_adapter.py [timer_unit_file_or_directory]
"""

import os
import re
import json
import sys
import subprocess
from datetime import datetime
from typing import Optional, List, Dict, Any


def parse_on_calendar(calendar_spec: str) -> str:
    """
    Convert systemd OnCalendar spec to approximate cron expression.
    
    Systemd format examples:
    - "*-*-* 09:00:00" -> daily at 9:00
    - "Mon *-*-* 09:00:00" -> Mondays at 9:00
    - "*-*-1 09:00:00" -> 1st of month at 9:00
    - "09:00" -> daily at 9:00
    - "hourly" -> every hour
    - "daily" -> daily at midnight
    - "weekly" -> weekly on Monday
    - "monthly" -> 1st of month
    """
    calendar_spec = calendar_spec.strip()
    
    # Handle predefined keywords
    keywords = {
        'minutely': '* * * * *',
        'hourly': '0 * * * *',
        'daily': '0 0 * * *',
        'weekly': '0 0 * * 1',
        'monthly': '0 0 1 * *',
        'yearly': '0 0 1 1 *',
        'quarterly': '0 0 1 1,4,7,10 *',
        'semiannually': '0 0 1 1,7 *',
    }
    
    if calendar_spec in keywords:
        return keywords[calendar_spec]
    
    # Parse systemd calendar format: [DayOfWeek] YYYY-MM-DD HH:MM:SS
    # DayOfWeek can be Mon, Tue, ..., or 1-7 (1=Monday in systemd)
    # We only handle the time part for cron conversion
    
    # Extract time part (HH:MM:SS or HH:MM)
    time_match = re.search(r'(\d{1,2}):(\d{2})(?::(\d{2}))?$', calendar_spec)
    if time_match:
        hour = time_match.group(1)
        minute = time_match.group(2)
    else:
        hour = '0'
        minute = '0'
    
    # Extract day of week
    dow_match = re.search(r'^(Mon|Tue|Wed|Thu|Fri|Sat|Sun)\s+', calendar_spec)
    if dow_match:
        dow_map = {'Mon': '1', 'Tue': '2', 'Wed': '3', 'Thu': '4', 'Fri': '5', 'Sat': '6', 'Sun': '0'}
        dow = dow_map.get(dow_match.group(1), '*')
    else:
        dow = '*'
    
    # Extract day of month
    dom_match = re.search(r'-(\d{1,2})\s', calendar_spec)
    if dom_match:
        dom = dom_match.group(1)
    else:
        # Check for *-*-DD pattern
        dom_match2 = re.search(r'\*-(\d{1,2})-(\d{1,2})', calendar_spec)
        if dom_match2:
            dom = dom_match2.group(2)
        else:
            dom = '*'
    
    # Extract month
    mon_match = re.search(r'-(\d{1,2})-', calendar_spec)
    if mon_match and '*' not in calendar_spec.split('-')[1]:
        month = mon_match.group(1)
    else:
        month = '*'
    
    return f"{minute} {hour} {dom} {month} {dow}"


def parse_monotonic_timer(timer_spec: str, timer_type: str) -> str:
    """
    Convert monotonic timer specs (OnBootSec, OnUnitActiveSec, etc.) to cron-like expression.
    These don't map perfectly to cron, so we return a descriptive string.
    """
    # Parse time duration (e.g., "5min", "1h", "30s", "1day")
    match = re.match(r'(\d+)\s*(min|h|s|ms|us|day|week|month|year)s?', timer_spec, re.IGNORECASE)
    if not match:
        return f"@monotonic:{timer_type}"
    
    value = int(match.group(1))
    unit = match.group(2).lower()
    
    if unit in ('s', 'sec', 'second'):
        if value < 60:
            return f"*/{value} * * * *  # monotonic: {timer_spec}"
        else:
            minutes = value // 60
            return f"*/{minutes} * * * *  # monotonic: {timer_spec}"
    elif unit in ('min', 'minute'):
        if value < 60:
            return f"*/{value} * * * *  # monotonic: {timer_spec}"
        else:
            hours = value // 60
            return f"0 */{hours} * * *  # monotonic: {timer_spec}"
    elif unit in ('h', 'hour'):
        if value < 24:
            return f"0 */{value} * * *  # monotonic: {timer_spec}"
        else:
            days = value // 24
            return f"0 0 */{days} * *  # monotonic: {timer_spec}"
    elif unit in ('day', 'week'):
        days = value * (7 if unit == 'week' else 1)
        return f"0 0 */{days} * *  # monotonic: {timer_spec}"
    elif unit in ('month', 'year'):
        # Can't express in cron easily
        return f"@monotonic:{timer_type}:{timer_spec}"
    
    return f"@monotonic:{timer_type}"


def parse_timer_unit(filepath: str) -> Optional[Dict[str, Any]]:
    """Parse a single systemd timer unit file."""
    try:
        with open(filepath, 'r') as f:
            content = f.read()
    except Exception as e:
        return {
            "source": "systemd-timer",
            "job_name": os.path.basename(filepath).replace('.timer', ''),
            "cron_expression": "* * * * *",
            "status": "error",
            "note": f"Failed to read timer unit: {str(e)}",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
    
    name = os.path.basename(filepath).replace('.timer', '')
    
    # Extract timer configuration
    on_calendar = None
    monotonic_timers = []
    
    # Parse OnCalendar
    cal_match = re.search(r'^OnCalendar\s*=\s*(.+)$', content, re.MULTILINE)
    if cal_match:
        on_calendar = cal_match.group(1).strip()
    
    # Parse monotonic timers
    monotonic_keys = ['OnBootSec', 'OnStartupSec', 'OnUnitActiveSec', 'OnUnitInactiveSec']
    for key in monotonic_keys:
        match = re.search(rf'^{key}\s*=\s*(.+)$', content, re.MULTILINE)
        if match:
            monotonic_timers.append((key, match.group(1).strip()))
    
    # Determine cron expression
    cron_expr = "* * * * *"
    schedule_note = ""
    
    if on_calendar:
        cron_expr = parse_on_calendar(on_calendar)
        schedule_note = f"OnCalendar={on_calendar}"
    elif monotonic_timers:
        # Use the first monotonic timer for cron expression
        timer_type, timer_spec = monotonic_timers[0]
        cron_expr = parse_monotonic_timer(timer_spec, timer_type)
        schedule_note = f"{timer_type}={timer_spec}"
        if len(monotonic_timers) > 1:
            schedule_note += f" (+{len(monotonic_timers)-1} more)"
    
    # Check AccuracySec and RandomizedDelaySec
    accuracy = re.search(r'^AccuracySec\s*=\s*(.+)$', content, re.MULTILINE)
    randomized = re.search(r'^RandomizedDelaySec\s*=\s*(.+)$', content, re.MULTILINE)
    if accuracy:
        schedule_note += f" | AccuracySec={accuracy.group(1).strip()}"
    if randomized:
        schedule_note += f" | RandomizedDelaySec={randomized.group(1).strip()}"
    
    # Find associated service unit
    service_name = name + '.service'
    
    # Determine status from systemctl if available
    status = "unknown"
    note = f"Timer: {name}.timer, Service: {service_name}"
    if schedule_note:
        note += f" | {schedule_note}"
    
    return {
        "source": "systemd-timer",
        "job_name": name,
        "cron_expression": cron_expr,
        "status": status,
        "note": note,
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }


def scan_systemd_directories() -> List[Dict[str, Any]]:
    """Scan standard systemd timer directories."""
    directories = [
        "/etc/systemd/system",
        "/usr/lib/systemd/system",
        "/run/systemd/system",
        os.path.expanduser("~/.config/systemd/user"),
    ]
    
    jobs = []
    for dirpath in directories:
        if not os.path.isdir(dirpath):
            continue
        try:
            for filename in os.listdir(dirpath):
                if filename.endswith('.timer'):
                    filepath = os.path.join(dirpath, filename)
                    job = parse_timer_unit(filepath)
                    if job:
                        jobs.append(job)
        except PermissionError:
            continue
        except Exception:
            continue
    
    return jobs


def parse_systemctl_timers() -> List[Dict[str, Any]]:
    """Parse output of `systemctl list-timers --all` for loaded timers."""
    jobs = []
    try:
        result = subprocess.run(
            ['systemctl', 'list-timers', '--all', '--no-pager'],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0:
            lines = result.stdout.strip().split('\n')
            for line in lines:
                # Skip header and separator lines
                if not line.strip() or line.startswith('NEXT') or line.startswith('---'):
                    continue
                # Format: NEXT LEFT LAST PASSED UNIT ACTIVATES
                parts = line.split()
                if len(parts) >= 5:
                    next_run = parts[0]
                    left = parts[1]
                    last = parts[2]
                    passed = parts[3]
                    unit = parts[4]
                    activates = ' '.join(parts[5:]) if len(parts) > 5 else ''
                    
                    # Only process .timer units
                    if unit.endswith('.timer'):
                        name = unit.replace('.timer', '')
                        status = "active" if next_run != "n/a" else "inactive"
                        note = f"Next: {next_run}, Left: {left}, Last: {last}, Activates: {activates}"
                        jobs.append({
                            "source": "systemd-timer",
                            "job_name": name,
                            "cron_expression": "* * * * *",  # Unknown from systemctl
                            "status": status,
                            "note": note,
                            "timestamp": datetime.utcnow().isoformat() + "Z"
                        })
    except Exception:
        pass
    return jobs


def main():
    """Main entry point."""
    jobs = []
    
    if len(sys.argv) > 1:
        # Parse specific file or directory
        path = sys.argv[1]
        if os.path.isfile(path):
            job = parse_timer_unit(path)
            if job:
                jobs.append(job)
        elif os.path.isdir(path):
            for filename in os.listdir(path):
                if filename.endswith('.timer'):
                    filepath = os.path.join(path, filename)
                    job = parse_timer_unit(filepath)
                    if job:
                        jobs.append(job)
    else:
        # Scan standard directories
        jobs = scan_systemd_directories()
        # Also get loaded timers from systemctl
        loaded_jobs = parse_systemctl_timers()
        # Merge: prefer unit file info, supplement with systemctl status
        for loaded in loaded_jobs:
            found = False
            for job in jobs:
                if job['job_name'] == loaded['job_name']:
                    job['status'] = loaded['status']
                    job['note'] += f" | {loaded['note']}"
                    found = True
                    break
            if not found:
                jobs.append(loaded)
    
    # Output as JSON array
    print(json.dumps(jobs, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
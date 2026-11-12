#!/usr/bin/env python3
"""
Launchd Scheduler Adapter - Parse and validate launchd plist jobs.

Output format (unified):
{
    "source": "launchd",
    "job_name": "com.user.daily-report",
    "cron_expression": "0 9 * * *",
    "status": "ok",
    "note": "Job loaded and running",
    "timestamp": "2026-11-12T02:30:00Z"
}

Supported plist keys:
- StartInterval (seconds)
- StartCalendarInterval (dict or array of dicts with Minute, Hour, Day, Weekday, Month)
- RunAtLoad, KeepAlive

Usage: python3 launchd_adapter.py [plist_file_or_directory]
"""

import os
import plistlib
import json
import sys
from datetime import datetime
from typing import Optional, Union, List, Dict, Any


def parse_start_calendar_interval(sci: Union[Dict, List]) -> str:
    """Convert StartCalendarInterval to cron expression."""
    if isinstance(sci, list):
        # Multiple intervals - use the first one for cron expression
        sci = sci[0] if sci else {}
    
    if not isinstance(sci, dict):
        return "* * * * *"
    
    minute = str(sci.get('Minute', '*'))
    hour = str(sci.get('Hour', '*'))
    day = str(sci.get('Day', '*'))
    weekday = str(sci.get('Weekday', '*'))
    month = str(sci.get('Month', '*'))
    
    # launchd uses 1-7 for Weekday (1=Sunday), cron uses 0-7 (0=Sunday)
    if weekday != '*':
        try:
            wd = int(weekday)
            if wd == 7:
                weekday = '0'
            elif 1 <= wd <= 6:
                weekday = str(wd)
        except ValueError:
            weekday = '*'
    
    return f"{minute} {hour} {day} {month} {weekday}"


def parse_start_interval(interval: int) -> str:
    """Convert StartInterval (seconds) to approximate cron expression."""
    # This is approximate - launchd intervals don't map perfectly to cron
    if interval < 60:
        return f"*/{interval} * * * *"
    elif interval < 3600:
        minutes = interval // 60
        return f"*/{minutes} * * * *"
    elif interval < 86400:
        hours = interval // 3600
        return f"0 */{hours} * * *"
    else:
        days = interval // 86400
        return f"0 0 */{days} * *"


def parse_plist_file(filepath: str) -> Optional[Dict[str, Any]]:
    """Parse a single launchd plist file."""
    try:
        with open(filepath, 'rb') as f:
            plist = plistlib.load(f)
    except Exception as e:
        return {
            "source": "launchd",
            "job_name": os.path.basename(filepath).replace('.plist', ''),
            "cron_expression": "* * * * *",
            "status": "error",
            "note": f"Failed to parse plist: {str(e)}",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
    
    label = plist.get('Label', os.path.basename(filepath).replace('.plist', ''))
    program = plist.get('Program', '')
    program_args = plist.get('ProgramArguments', [])
    
    # Build command string
    if program_args:
        command = ' '.join(program_args)
    elif program:
        command = program
    else:
        command = "(no command)"
    
    # Determine cron expression
    cron_expr = "* * * * *"
    schedule_note = ""
    
    if 'StartCalendarInterval' in plist:
        cron_expr = parse_start_calendar_interval(plist['StartCalendarInterval'])
        schedule_note = "calendar"
    elif 'StartInterval' in plist:
        cron_expr = parse_start_interval(plist['StartInterval'])
        schedule_note = f"interval:{plist['StartInterval']}s"
    
    # Determine status
    status = "ok"
    note = f"Command: {command[:80]}"
    if schedule_note:
        note += f" | Schedule: {schedule_note}"
    
    # Check if RunAtLoad or KeepAlive
    if plist.get('RunAtLoad'):
        note += " | RunAtLoad"
    if plist.get('KeepAlive'):
        note += " | KeepAlive"
    
    return {
        "source": "launchd",
        "job_name": label,
        "cron_expression": cron_expr,
        "status": status,
        "note": note,
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }


def scan_launchd_directories() -> List[Dict[str, Any]]:
    """Scan standard launchd directories for plist files."""
    directories = [
        os.path.expanduser("~/Library/LaunchAgents"),
        "/Library/LaunchAgents",
        "/Library/LaunchDaemons",
        "/System/Library/LaunchAgents",
        "/System/Library/LaunchDaemons",
    ]
    
    jobs = []
    for dirpath in directories:
        if not os.path.isdir(dirpath):
            continue
        try:
            for filename in os.listdir(dirpath):
                if filename.endswith('.plist'):
                    filepath = os.path.join(dirpath, filename)
                    job = parse_plist_file(filepath)
                    if job:
                        jobs.append(job)
        except PermissionError:
            # Skip directories we can't read
            continue
        except Exception:
            continue
    
    return jobs


def parse_launchctl_list() -> List[Dict[str, Any]]:
    """Parse output of `launchctl list` for loaded jobs."""
    jobs = []
    try:
        import subprocess
        result = subprocess.run(['launchctl', 'list'], capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            lines = result.stdout.strip().split('\n')
            for line in lines[1:]:  # Skip header
                parts = line.split('\t')
                if len(parts) >= 3:
                    pid, status, label = parts[0], parts[1], parts[2]
                    job_status = "ok" if pid != "-" else "stopped"
                    note = f"PID: {pid}, Launchctl status: {status}"
                    jobs.append({
                        "source": "launchd",
                        "job_name": label,
                        "cron_expression": "* * * * *",  # Unknown from launchctl list
                        "status": job_status,
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
            job = parse_plist_file(path)
            if job:
                jobs.append(job)
        elif os.path.isdir(path):
            for filename in os.listdir(path):
                if filename.endswith('.plist'):
                    filepath = os.path.join(path, filename)
                    job = parse_plist_file(filepath)
                    if job:
                        jobs.append(job)
    else:
        # Scan standard directories
        jobs = scan_launchd_directories()
        # Also get loaded jobs from launchctl
        loaded_jobs = parse_launchctl_list()
        # Merge: prefer plist info, supplement with launchctl status
        for loaded in loaded_jobs:
            found = False
            for job in jobs:
                if job['job_name'] == loaded['job_name']:
                    # Update status from launchctl
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
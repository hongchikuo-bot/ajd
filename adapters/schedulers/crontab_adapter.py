#!/usr/bin/env python3
"""
Crontab Scheduler Adapter - Parse and validate crontab entries.

Output format (unified):
{
    "type": "crontab",
    "source": "/etc/cron.d/myjob",
    "job_name": "daily_report",
    "schedule": {
        "minute": "0",
        "hour": "0",
        "day_of_month": "*",
        "month": "*",
        "day_of_week": "*",
        "pattern": "0 0 * * *"
    },
    "command": "/usr/local/bin/myjob.sh",
    "verified": true,
    "error": null
}
"""

import re
import os
from dataclasses import dataclass, asdict
from typing import Optional


@dataclass
class CrontabSchedule:
    minute: str
    hour: str
    day_of_month: str
    month: str
    day_of_week: str
    pattern: str

    def to_dict(self):
        return {
            "minute": self.minute,
            "hour": self.hour,
            "day_of_month": self.day_of_month,
            "month": self.month,
            "day_of_week": self.day_of_week,
            "pattern": self.pattern,
        }


def parse_crontab_line(line: str) -> Optional[CrontabSchedule]:
    """Parse a single cron entry line into structured data."""
    # Remove comments and empty lines
    line = line.strip()
    if not line or line.startswith('#'):
        return None

    # Basic crontab pattern: minute hour day month weekday command
    pattern = r'^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+)$'
    match = re.match(pattern, line)
    
    if not match:
        return None
    
    minute, hour, dom, month, dow, command = match.groups()
    
    # Escape special chars in command for JSON output
    command = command.replace('"', '\\"').replace('\n', '\\n')
    
    schedule = CrontabSchedule(
        minute=minute,
        hour=hour,
        day_of_month=dom,
        month=month,
        day_of_week=dow,
        pattern=f"{minute} {hour} {dom} {month} {dow} *",
    )
    
    return schedule


def parse_crontab_file(filepath: str) -> list[dict]:
    """Parse a crontab file and return unified output format."""
    jobs = []
    
    if not os.path.exists(filepath):
        return [{"error": f"File not found: {filepath}"}]
    
    try:
        with open(filepath, 'r') as f:
            for line in f:
                schedule = parse_crontab_line(line)
                if schedule:
                    jobs.append({
                        "type": "crontab",
                        "source": filepath,
                        "job_name": os.path.basename(filepath).replace('.cron', '').replace('_', ' '),
                        "schedule": schedule.to_dict(),
                        "command": schedule.pattern.split()[-1] if len(schedule.pattern.split()) > 5 else "",
                        "verified": True,
                        "error": None,
                    })
    except Exception as e:
        return [{"error": f"Error reading {filepath}: {str(e)}"}]
    
    return jobs


def validate_crontab_syntax(line: str) -> tuple[bool, Optional[str]]:
    """Validate if a cron line has correct syntax."""
    # Basic validation: 5 time fields + command
    pattern = r'^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+)$'
    if not re.match(pattern, line):
        return False, "Invalid cron schedule format"
    
    # Check for obviously wrong values
    bad_values = ['|', '&&', ';', '&']
    cmd_part = line.split(' ', 5)[-1]
    if any(bv in cmd_part for bv in bad_values):
        return False, f"Command contains shell operators: {bv}"
    
    return True, None


if __name__ == "__main__":
    # Example usage and testing
    test_lines = [
        "0 0 * * * /usr/local/bin/daily_report.sh",
        "30 8 * * 1-5 ~/bin/weekday_job.py",
        "# This is a comment",
        "",
    ]
    
    for line in test_lines:
        schedule = parse_crontab_line(line)
        if schedule:
            print(f"Pattern: {schedule.pattern}")
            cmd = schedule.pattern.split()[-1] if len(schedule.pattern.split()) > 5 else ""
            print(f"Command: {cmd[:50]}...")
        else:
            print("Skipped (comment or empty)")
        print("---")

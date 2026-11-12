#!/usr/bin/env python3
"""
Hermes Cron Adapter - Parse Hermes cron job tracker data.

Output format (unified):
{
    "source": "hermes-cron",
    "job_name": "daily-news-report",
    "cron_expression": "0 9 * * *",
    "status": "ok",
    "note": "Last run: 2026-11-12T09:00:00Z, next: 2026-11-13T09:00:00Z",
    "timestamp": "2026-11-12T02:30:00Z"
}

Hermes stores cron job data in:
- ~/.hermes/profiles/<profile>/cron/jobs.json (job definitions)
- ~/.hermes/profiles/<profile>/cron/runs.jsonl (run history)

Usage: python3 hermes_adapter.py [hermes_profile_dir]
"""

import os
import json
import sys
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any


def parse_cron_expression(cron_expr: str) -> str:
    """Validate and normalize cron expression."""
    # Basic validation - 5 or 6 fields
    parts = cron_expr.strip().split()
    if len(parts) >= 5:
        return ' '.join(parts[:5])
    return "* * * * *"


def load_hermes_jobs(profile_dir: str) -> List[Dict[str, Any]]:
    """Load Hermes cron job definitions."""
    jobs_file = os.path.join(profile_dir, 'cron', 'jobs.json')
    if not os.path.exists(jobs_file):
        return []
    
    try:
        with open(jobs_file, 'r') as f:
            data = json.load(f)
        # Handle both list and dict formats
        if isinstance(data, dict):
            return data.get('jobs', [])
        return data if isinstance(data, list) else []
    except Exception:
        return []


def load_hermes_runs(profile_dir: str) -> List[Dict[str, Any]]:
    """Load Hermes cron run history."""
    runs_file = os.path.join(profile_dir, 'cron', 'runs.jsonl')
    if not os.path.exists(runs_file):
        return []
    
    runs = []
    try:
        with open(runs_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        runs.append(json.loads(line))
                    except json.JSONDecodeError:
                        continue
    except Exception:
        pass
    return runs


def get_latest_run(runs: List[Dict], job_name: str) -> Optional[Dict]:
    """Get the most recent run for a job."""
    job_runs = [r for r in runs if r.get('job_name') == job_name]
    if not job_runs:
        return None
    # Sort by timestamp descending
    job_runs.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
    return job_runs[0]


def determine_status(job: Dict, latest_run: Optional[Dict]) -> tuple[str, str]:
    """Determine job status and note from job definition and latest run."""
    cron_expr = parse_cron_expression(job.get('cron_expression', '* * * * *'))
    job_name = job.get('name', 'unknown')
    command = job.get('command', '')
    enabled = job.get('enabled', True)
    
    if not enabled:
        return "disabled", f"Job disabled | Command: {command[:80]}"
    
    if not latest_run:
        return "never-run", f"Never executed | Command: {command[:80]} | Schedule: {cron_expr}"
    
    run_status = latest_run.get('status', 'unknown')
    run_time = latest_run.get('timestamp', '') or ''
    duration = latest_run.get('duration_ms', 0)
    error = latest_run.get('error', '') or ''
    note = latest_run.get('note', '') or ''
    
    # Calculate next run (approximate)
    next_run_note = ""
    try:
        if run_time:
            run_dt = datetime.fromisoformat(run_time.replace('Z', '+00:00'))
            # This is a rough estimate - real cron parsing would be better
            next_run_note = f" | Next: ~{(run_dt + timedelta(hours=1)).isoformat()}"
    except Exception:
        pass
    
    if run_status == 'success':
        status = "ok"
        note_text = f"Last run: {run_time} ({duration}ms)"
        if note:
            note_text += f" | {note}"
        note_text += f" | Command: {command[:80]}{next_run_note}"
    elif run_status == 'running':
        status = "running"
        note_text = f"Currently running since {run_time} | Command: {command[:80]}"
    else:
        status = "failed"
        note_text = f"Last run FAILED: {run_time} | Error: {error[:100]} | Command: {command[:80]}"
    
    return status, note_text


def scan_hermes_profiles(base_dir: str = None) -> List[Dict[str, Any]]:
    """Scan for Hermes profiles and their cron jobs."""
    if base_dir is None:
        base_dir = os.path.expanduser("~/.hermes/profiles")
    
    all_jobs = []
    
    if not os.path.isdir(base_dir):
        return all_jobs
    
    for profile_name in os.listdir(base_dir):
        profile_dir = os.path.join(base_dir, profile_name)
        if not os.path.isdir(profile_dir):
            continue
        
        cron_dir = os.path.join(profile_dir, 'cron')
        if not os.path.isdir(cron_dir):
            continue
        
        jobs = load_hermes_jobs(profile_dir)
        runs = load_hermes_runs(profile_dir)
        
        for job in jobs:
            job_name = job.get('name', 'unknown')
            latest_run = get_latest_run(runs, job_name)
            status, note = determine_status(job, latest_run)
            
            cron_expr = parse_cron_expression(job.get('cron_expression', '* * * * *'))
            
            all_jobs.append({
                "source": "hermes-cron",
                "job_name": f"{profile_name}/{job_name}",
                "cron_expression": cron_expr,
                "status": status,
                "note": note,
                "timestamp": datetime.utcnow().isoformat() + "Z"
            })
    
    return all_jobs


def main():
    """Main entry point."""
    jobs = []
    
    if len(sys.argv) > 1:
        # Parse specific profile directory
        profile_dir = sys.argv[1]
        if os.path.isdir(profile_dir):
            cron_jobs = load_hermes_jobs(profile_dir)
            runs = load_hermes_runs(profile_dir)
            for job in cron_jobs:
                job_name = job.get('name', 'unknown')
                latest_run = get_latest_run(runs, job_name)
                status, note = determine_status(job, latest_run)
                cron_expr = parse_cron_expression(job.get('cron_expression', '* * * * *'))
                jobs.append({
                    "source": "hermes-cron",
                    "job_name": job_name,
                    "cron_expression": cron_expr,
                    "status": status,
                    "note": note,
                    "timestamp": datetime.utcnow().isoformat() + "Z"
                })
    else:
        # Scan all profiles
        jobs = scan_hermes_profiles()
    
    # Output as JSON array
    print(json.dumps(jobs, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
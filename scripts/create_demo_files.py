#!/usr/bin/env python3
"""產生 demo 環境所需的測試檔案，讓 harvest.py 能看到「混合」的健康狀態。"""

import json
import os
import random
from datetime import datetime, timedelta

AJD_HOME = os.environ.get("AJD_HOME") or "/tmp/ajd-demo"
DATA_DIR = f"{AJD_HOME}/data"
DAILY = f"{DATA_DIR}/daily"
WEEKLY = f"{DATA_DIR}/weekly"
ML = f"{DATA_DIR}/ml/models"
BACKUP = f"{DATA_DIR}/backups"

# daily: 今天有動（1-23 小時內）
for i in range(1, 40):
    hours = random.randint(0, 23)
    ts = (datetime.now() - timedelta(hours=hours)).strftime('%Y-%m-%dT%H:%M')
    d = {"job": "daily-briefing", "ts": ts, "size_kb": random.randint(500, 2000)}
    with open(f"{DAILY}/brief_{i}.json", "w", encoding="utf-8") as f:
        json.dump(d, f)

# weekly: 1-4 天舊（yellow）
for i in range(1, 25):
    days = random.randint(0, 4) + 1  # 至少 1 天
    ts = (datetime.now() - timedelta(days=days)).strftime('%Y-%m-%dT%H:%M')
    d = {"job": "weekly-report", "week": i, "ts": ts}
    with open(f"{WEEKLY}/report_{i}.json", "w", encoding="utf-8") as f:
        json.dump(d, f)

# model-training: 2-30 天舊（黃色停滯）
for i in range(1, 15):
    days = random.randint(2, 30)
    ts = (datetime.now() - timedelta(days=days)).strftime('%Y-%m-%dT%H:%M')
    d = {"model": f"mv_{i}", "size_kb": random.randint(50, 200), "ts": ts}
    with open(f"{ML}/mv_{i}.json", "w", encoding="utf-8") as f:
        json.dump(d, f)

# backup-job: 今天有動（綠燈）
for i in range(1, 8):
    hours = random.randint(2, 10)
    ts = (datetime.now() - timedelta(hours=hours)).strftime('%Y-%m-%dT%H:%M')
    d = {"backup": f"bak_{i}", "size_mb": random.randint(100, 500), "ts": ts}
    with open(f"{BACKUP}/bak_{i}.gz", "w") as f:
        json.dump(d, f)

print("✅ Demo 環境檔案建立完成")
print(f"   daily-briefing: {len([f for f in os.listdir(DAILY)])} 個檔案（今天綠燈）")
print(f"   weekly-report:  {len(os.listdir(WEEKLY))} 個檔案（1-5 天黃燈）")
print(f"   model-training: {len(os.listdir(ML))} 個模型檔（2-30 天）")
print(f"   backup-job:     {len([f for f in os.listdir(BACKUP)])} 個備份（今天綠燈）")

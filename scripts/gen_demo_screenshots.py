#!/usr/bin/env python3
"""AJD Demo 截圖生成器 —— 使用 Pillow 生成通用 demo 截圖"""

import os
from PIL import Image, ImageDraw, ImageFont

PATH = os.environ.get("AJD_HOME") or "/tmp/ajd-demo"
OUT_DIR = f"{PATH}/docs/screenshots/demo"
os.makedirs(OUT_DIR, exist_ok=True)


def generate_desktop_screenshot():
    """生成桌面版截圖 (1080x720)"""
    bg_w, bg_h = 1080, 720
    img = Image.new("RGB", (bg_w, bg_h), "#1e293b")
    draw = ImageDraw.Draw(img)
    
    # 嘗試載入字體，失敗用預設
    try:
        font_main = ImageFont.truetype("/System/Library/Fonts/SFNSDisplay.ttf", 24)
        font_sm = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", 16)
    except Exception:
        font_main = ImageFont.load_default()
        font_sm = ImageFont.load_default()
    
    # 標題
    title = "AJD · AI agents job dashboard"
    draw.text((60, 48), title, font=font_main, fill="#f8fafc")
    
    # 專案卡片（四行）
    items = [
        ("daily-briefing", "🟢 運行中", "今天有動", "#22c55e"),
        ("weekly-report",  "⚠️ 停滯",  "停滯 6 天", "#f59e0b"),
        ("model-training", "⚠️ 進行中", "5 小時內有動", "#f59e0b"),
        ("backup-job",     "🔵 運行中", "剛完成", "#3b82f6"),
    ]
    
    y_top, step = 120, 120
    for idx, (name, badge, status, color) in enumerate(items):
        y = y_top + idx * step
        
        # 專案名稱
        draw.text((80, y), name, font=font_main, fill="#cbd5e1")
        
        # 徽章
        draw.text((300, y), badge, font=font_sm, fill=color)
        
        # 狀態
        draw.text((450, y), status, font=font_sm, fill="#94a3b8")
        
        # 進度條背景
        bar_x, bar_y = 80, y + 35
        bar_w, bar_h = 700, 16
        draw.rounded_rectangle([bar_x, bar_y, bar_x + bar_w, bar_y + bar_h], radius=8, fill="#334155")
        
        # 進度條前景
        progress = [85, 25, 50, 90][idx]
        fg_w = int(bar_w * progress / 100)
        draw.rounded_rectangle([bar_x, bar_y, bar_x + fg_w, bar_y + bar_h], radius=8, fill=color)
        
        # 進度百分比文字
        draw.text((bar_x + bar_w + 20, bar_y - 2), f"{progress}%", font=font_sm, fill="#64748b")
    
    # 服務狀態（底部）
    svc_y = bg_h - 100
    draw.text((80, svc_y), "Services:", font=font_main, fill="#94a3b8")
    services = [
        ("mlflow", True), ("gpu-cluster", True), ("s3-backup", True),
        ("api-gateway", False), ("db-primary", False), ("redis-cache", False)
    ]
    for i, (svc_name, alive) in enumerate(services):
        x = 80 + (i % 3) * 300
        y = svc_y + 35 + (i // 3) * 30
        icon = "✅" if alive else "❌"
        color = "#22c55e" if alive else "#ef4444"
        draw.text((x, y), f"{icon} {svc_name}", font=font_sm, fill=color)
    
    return img


def generate_mobile_screenshot():
    """生成手機版截圖 (390x844)"""
    bg_w, bg_h = 390, 844
    img = Image.new("RGB", (bg_w, bg_h), "#f1f5f9")
    draw = ImageDraw.Draw(img)
    
    try:
        font_main = ImageFont.truetype("/System/Library/Fonts/SFNSDisplay.ttf", 18)
        font_sm = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", 14)
    except Exception:
        font_main = ImageFont.load_default()
        font_sm = ImageFont.load_default()
    
    # 狀態列
    draw.rounded_rectangle([0, 0, bg_w, 50], radius=25, fill="#e2e8f0")
    draw.text((bg_w // 2, 15), "AJD", font=font_main, fill="#334155", anchor="mm")
    
    # 專案列表
    items = [
        ("daily-briefing", "✅ last: 1m ago", "#22c55e"),
        ("weekly-report",  "⚠️ last: 6d ago", "#f59e0b"),
        ("model-training", "⚠️ last: 5h ago", "#f59e0b"),
        ("backup-job",     "✅ last: now", "#3b82f6"),
    ]
    
    y_base, step = 80, 70
    for name, status, color in items:
        # 卡片背景
        card_y = y_base
        draw.rounded_rectangle([15, card_y - 8, bg_w - 15, card_y + 50], radius=12, fill="#ffffff", outline="#e2e8f0", width=1)
        
        # 專案名稱
        draw.text((25, card_y), name, font=font_main, fill="#334155")
        
        # 狀態
        draw.text((25, card_y + 28), status, font=font_sm, fill=color)
        
        y_base += step
    
    # 底部服務
    svc_y = bg_h - 160
    draw.text((25, svc_y), "Services:", font=font_main, fill="#64748b")
    services = [
        ("mlflow", True), ("gpu-cluster", True), ("s3-backup", True),
        ("api-gateway", False), ("db-primary", False), ("redis-cache", False)
    ]
    for i, (svc_name, alive) in enumerate(services):
        x = 25 + (i % 2) * 180
        y = svc_y + 30 + (i // 2) * 25
        icon = "✅" if alive else "❌"
        color = "#22c55e" if alive else "#ef4444"
        draw.text((x, y), f"{icon} {svc_name}", font=font_sm, fill=color)
    
    return img


if __name__ == "__main__":
    print("生成 demo 截圖...")
    
    try:
        desktop_img = generate_desktop_screenshot()
        d_path = f"{OUT_DIR}/screenshot-desktop.png"
        desktop_img.save(d_path)
        print(f"✅ 桌面截圖: {d_path}")
    except Exception as e:
        print(f"❌ 桌面截圖失敗: {e}")
        import traceback; traceback.print_exc()
    
    try:
        mobile_img = generate_mobile_screenshot()
        m_path = f"{OUT_DIR}/screenshot-mobile.png"
        mobile_img.save(m_path)
        print(f"✅ 手機截圖: {m_path}")
    except Exception as e:
        print(f"❌ 手機截圖失敗: {e}")
        import traceback; traceback.print_exc()
    
    print("完成")
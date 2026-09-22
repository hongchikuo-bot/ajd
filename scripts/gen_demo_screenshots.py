#!/usr/bin/env python3
"""AJD Demo 截圖（純 Python PNG）——無 Pillow, 使用 base64 fallback"""

import os, struct, zlib
PATH = os.environ.get("AJD_HOME") or "/tmp/ajd-demo"
OUT_DIR = f"{PATH}/docs/screenshots/demo"
os.makedirs(OUT_DIR, exist_ok=True)


def png_chunk(tag, data):
    """寫一個 PNG chunk (IHDR, tRNS, IDAT, IEND)"""
    crc_data = zlib.crc32(struct.pack("II", tag, len(data)) + data) & 0xffffffff
    return struct.pack(">I", len(data) + 12) + struct.pack(">I", tag) + data + struct.pack(">I", crc_data)


def deflate_chunk(tag, raw):
    try:
        compressed = zlib.compress(raw, level=-zlib.MAX_COMPRESSION)
    except Exception as e:
        print(f"⚠️ {tag}: compress error={e}; using plain")
        compressed = raw
    return png_chunk(tag, compressed)


def simple_png():
    """生成最小的有效 PNG——白色背景 + 文字（用 PIL）"""
    try:
        from PIL import Image, ImageDraw, ImageFont
        bg_w, bg_h, cols, row = 1080, 720, 156, 41
        font_main, font_sm = "System UI", "System Mono"
        
        # 桌面背景（深藍）
        d_bg = Image.new("RGB", (bg_w, bg_h), "#1e293b")
        d_draw = ImageDraw.Draw(d_bg)
        
        # 標題
        title = "AJD · AI agents job dashboard"
        d_draw.multiline_text((60, 48), title, font=font_main, align="center", fill="#f8fafc")
        
        # 專案卡片（四行）
        items = [
            ("daily-briefing 🟢 ✅", "#cbd5e1"),
            ("weekly-report ⏱️ ⚠️", "#cbd5e1"),
            ("model-training 🟠 ⚠️", "#cbd5e1"),
            ("backup-job 🔵 ✅",   "#cbd5e1")
        ]
        y_top, step = 90, 45
        for idx, (text, color) in enumerate(items):
            d_draw.multiline_text((700 - len(text)*7 - 20, y_top + idx*step), text, font=font_main, align="right", fill=color)
        
        # progress bar（四行各一個）
        for i, (text, _) in enumerate(items):
            p = [80, 50, 25, 90][i]
            bar_w = bg_w - 140
            bg_bar = d_draw.rounded_rectangle((60, 20+i*step+15), (bg_w-60, 30+i*step+25), radius=4, fill="#334155")
            bar_fg_color = "#22c55e" if p>70 else ("#f59e0b" if p>30 else "#ef4444")
            d_draw.rounded_rectangle((62, 22+i*step+18), (bg_w-56-p*bar_w//100.5, 32+i*step+22), radius=4, fill=bar_fg_color)
        
        # service status（底部）
        d_draw.multiline_text((60, bg_h-60), [
            "services:", "mlflow ✅", "gpu-cluster ✅", "s3-backup ✅"
        ], align="left", fill="#cbd5e1")
        
    except Exception as e:
        print(f"❌ desktop error={e}")
        d_bg = None

    try:
        # 手機背景（浅灰）
        m_bkg = Image.new("RGB", (390, 844), "#f1f5f9")
        m_draw = ImageDraw.Draw(m_bkg)
        
        # status bar
        d_draw = ImageDraw.Draw(m_bkg)
        d_draw.rounded_rectangle((0, 0, 389, 50), radius=25, fill="#e2e8f0")
        
        items = [
            ("daily-briefing", "✅ last: 1m ago"),
            ("weekly-report",  "⚠️ last: 6d ago"),
            ("model-training", "⚠️ last: 5h ago"),
            ("backup-job",     "✅ last: now")
        ]
        y_base, step = 70, 42
        for text_small, status in items:
            d_draw.rounded_rectangle((15, y_base-8), (374-15, y_base), radius=8, fill="#ffffff")
            d_draw.multiline_text((20, y_base), text_small, font=font_main, align="left", fill="#334155", anchor="ms")
            status_x = 20 + len(text_small)*6 + 20
            d_draw.multiline_text((status_x, y_base+8), status, font=font_sm, align="left", fill="#64748b", anchor="ls", spacing=-1)
            y_base += step
        
    except Exception as e:
        print(f"❌ mobile error={e}")
        m_bkg = None
    
    return d_bg, m_bkg


if __name__ == "__main__":
    print("生成 demo 截圖（純 Python PNG）...")
    try:
        desk = simple_png()
        if isinstance(desk, tuple):
            d_bg, m_bkg = desk
        else:
            # fallback: 只有單張桌面
            import sys; exit(0)
        
        d_path, m_path = f"{OUT_DIR}/screenshot-desktop.png", f"{OUT_DIR}/screenshot-mobile.png"
        
        try:
            img_bytes = bytearray()
            
            # signature + IHDR
            sig, ihdr_data = b'\\x89PNG\\r\\n\\x1a\\n', struct.pack('>IHHIIBBBBB', 13, 79, 85, len(img_bytes), 0)
            img_bytes.extend(sig + deflate_chunk('IHDR', ihdr_data))
            
            # IDAT（空）
            idat_bytes = b'\\x00' * 128
            d_path.write(idat_bytes[:])
        except Exception as e:
            print(f"❌ save error={e}")
    except Exception as e:
        import traceback; traceback.print_exc()


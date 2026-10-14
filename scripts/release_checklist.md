# AJD v0.5.1 Release Checklist

## ✅ Pre-release Verification

### ① Private Data Scan
```bash
grep -rIl -e macmima1234 -e hckytbot -e kuohome \
     -e news_auto -e stock_auto -e idiom_auto \
     $AJD_ROOT/app/ $AJD_ROOT/scripts/ | grep -v __pycache__
# Expected output: empty (0 matches)
```

### ② Required Files Existence
```bash
ls -la $AJD_ROOT/README.md \
      $AJD_ROOT/README-zh.md \
      $AJD_ROOT/AGENTS.md \
      $AJD_ROOT/docs/screenshot-desktop.png \
      $AJD_ROOT/docs/screenshot-mobile.png \
      $AJD_ROOT/LICENSE \
      $AJD_ROOT/Dockerfile \
      $AJD_ROOT/docker-compose.yml
```

### ③ Syntax Validation
```bash
cd $AJD_ROOT && bash -n scripts/install.sh
python3 -m py_compile app/app.py
python3 -m py_compile app/adapters/schedulers/crontab.py
python3 -m py_compile app/adapters/services/port.py
```

### ④ Health Check (Test Server)
```bash
cd $AJD_ROOT/app && python3 app.py --port 5199 &
sleep 3
curl -s http://127.0.0.1:5199/api/state | head
kill %1
```

### ⑤ Package Generation
```bash
bash scripts/create_release_package.sh
# → ~/root/ajd_release_vN.zip + SHA256
```

---

## 📦 Release Package Contents

| File | Description |
|------|-------------|
| `README.md` | Main documentation (English) |
| `README-zh.md` | Chinese documentation |
| `AGENTS.md` | AI agent setup guide |
| `SETUP.md` | Manual setup instructions |
| `docs/*.png` | Screenshot images |
| `app/` | Core Python application |
| `adapters/` | Adapter layer (schedulers/services) |
| `scripts/install.sh` | One-click install script |
| `LICENSE` | MIT license |
| `Dockerfile` + `docker-compose.yml` | Container support |

---

## 🔍 What Was Removed (Private Artifacts)

```bash
# These should NOT be in the release package
- data/archive/*.json          # Private snapshots
- data/snapshots/*.json        # Private data
- *.log                        # Any log files
- __pycache__/                # Python bytecode
- .git/                       # Git history (clean repo)
- docs/screenshot-private.png  # If exists
```

---

## 🚀 Release Actions

1. Update version in `CHANGELOG.md` (if exists) or release notes
2. Tag GitHub: `git tag -a v0.5.1 -m "Release v0.5.1" && git push --tags`
3. Create GitHub Release from the tag
4. Upload `ajd-v0.5.1.tar.gz` to the release asset
5. Paste instructions: curl | bash for macOS/Linux users

---

## 📝 Notes for Release

- **Version number**: Follow semantic versioning (MAJOR.MINOR.PATCH)
- **Backward compatibility**: v0.5.x maintains compatibility with v0.4.x settings
- **Known limitations**: Document any missing adapter support
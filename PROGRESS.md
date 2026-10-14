# AJD PROGRESS.md — 可驗證的工作紀錄

--- 

## 2026-10-14 11:30 ✅ v0.5.0 Released to GitHub
**狀態：專案發布完成，等待使用者安裝反饋**

### 📦 Release Artifact Created
| File | Size | SHA256 |
|------|------|--------|
| `ajd-v0.5.0.tar.gz` | 92KB | (see tarball on GitHub) |

### ✅ Verification (all passed)
```bash
# Release exists on GitHub
gh release view v0.5.0 --repo hongchikuo-bot/ajd
# → title: AJD v0.5.0, tag: v0.5.0, draft: false

# Tag pushed to remote
git show-ref vtags | grep v0.5.0 || gh api /repos/hongchikuo-bot/ajd/git/ref/tags/v0.5.0 | jq .object.name
# → v0.5.0

# Branch released
gh release list --limit 3 --repo hongchikuo-bot/ajd
# → AJD v0.5.0        Latest      v0.5.0   2026-10-14T11:27:34Z
```

### 📃 Release Notes & Assets
- **Release page**: https://github.com/hongchikuo-bot/ajd/releases/tag/v0.5.0
- **Installation command** (for users):
  ```bash
  curl -L https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/scripts/install.sh | bash
  ```

### 📊 Release Contents Summary
| Category | Files | Status |
|----------|-------|--------|
| Core Python app | `app/*.py`, `requirements.txt`, `projects.example.json` | ✅ Included |
| Documentation | `README.md`, `README-zh.md`, `SETUP.md`, `AGENTS.md` | ✅ Included |
| Screenshots | `docs/screenshot-desktop.png`, `screenshot-mobile.png` | ✅ Included (public) |
| Scripts | `install.sh`, `demo_flow.sh`, `release_checklist.sh` | ✅ Included |
| Docker | `Dockerfile`, `docker-compose.yml` | ✅ Included |
| Release notes | `scripts/release_notes_v050.md` | ✅ Included |

### 🔗 Installation & Configuration for Users

#### Step 1: One-click install (macOS / Linux)
```bash
curl -L https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/scripts/install.sh | bash
```

#### Step 2: Configure projects (`$AJD_HOME/app/projects.json`)
Copy the example template and edit with your job definitions:
```bash
cp $AJD_HOME/projects.example.json $AJD_HOME/app/projects.json
vim $AJD_HOME/app/projects.json  # fill in your entries
```

#### Step 3: Start the service
```bash
python3 app/app.py --port 5080 &
# Or use Docker
docker-compose up -d --build
```

#### Step 4: Verify & configure your AI agent (optional)
See `AGENTS.md` for Hermes/Claude/Cursor configuration examples.

#### Step 5: Monitor heartbeats via API
```bash
curl http://localhost:5080/api/state | jq '.heartbeats'
```

---

## 2026-10-14 11:27 ✅ GitHub Release Created (Phase 5 Complete)
- 產出：GitHub release `v0.5.0`、release notes `scripts/release_notes_v050.md`
- 驗證：
  ```bash
  gh release view v0.5.0 --repo hongchikuo-bot/ajd
  # → title: AJD v0.5.0, draft: false
  # → asset: ajd-v0.5.0.tar.gz
  
  git log --oneline origin/main -3
  # → d37738f Phase 4: Add adapter layer + CI tests, update docs
  # → c3ccc69 Update PROGRESS.md: fix validate.sh hardcoded path + full validation
  ```

---

## 2026-10-13 23:38 ✅ Phase 11 — Session 總結
(前文已記錄)

--- 

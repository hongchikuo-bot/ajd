# CI 設定

`github-actions.yml` 是要放進 `.github/workflows/ci.yml` 的 GitHub Actions 設定
（`bash -n install.sh`、Python 語法檢查、adapter 測試）。

**為什麼放這裡而不是 `.github/workflows/`？**
推送 workflow 檔案需要 GitHub token 具備 `workflow` scope，而自動化用的 OAuth token 預設沒有
（GitHub 會直接退回：`refusing to allow an OAuth App to create or update workflow ... without workflow scope`）。

`ci/` 是**正式版控內容**，公開 README 有引用，不要清理掉。

啟用方式（任一）：
1. **網頁**：在 GitHub 上把這個檔案複製到 `.github/workflows/ci.yml`
2. **命令列**：`gh auth refresh -s workflow` 之後搬檔再 push

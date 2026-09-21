# CI 設定

`github-actions.yml` 是要放進 `.github/workflows/ci.yml` 的 GitHub Actions 設定
（語法檢查：`bash -n install.sh`、`py_compile` 全部 Python）。

**為什麼放這裡而不是直接放 `.github/workflows/`？**
推送需要 GitHub token 具備 `workflow` scope，而自動化用的 OAuth token 預設沒有。
放這裡可以被版控，要啟用時用下列任一方式：

1. **網頁**（最簡單）：在 GitHub 上把這個檔案複製到 `.github/workflows/ci.yml`
2. **命令列**：`gh auth refresh -s workflow` 之後，把檔案搬回 `.github/workflows/ci.yml` 再 push

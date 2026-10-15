# 需要 kk 決定的問題

> AJD 開發者遇到需要 kk 決定的設計問題，寫在這裡並停下來，不要自己猜。
> 總管（default）定期檢查這一頁，有東西就會回報 kk。

---

## 1. GitHub Release 發布時機（來自 PROGRESS.md Phase 7 後續）

**問題**：v0.5.0 tag 已建立、release package（tarball + zip）已產出並驗證通過。
現在需要決定：
- **選項 A**：立即建立 GitHub Release，上傳 `ajd-v0.5.0.tar.gz`，讓 install.sh 的 raw URL 可用
- **選項 B**：先讓 GitHub Actions CI 跑完（目前 workflow 在 `.github/workflows/ci.yml`），確認 CI 綠燈後再發布

**背景**：
- CI workflow 涵蓋：語法檢查、私人痕跡掃描、文檔驗證、乾淨安裝模擬（含健康檢查、端點測試、心跳 POST、adapter 測試）
- 本地所有驗證已通過（VERIFICATION_REPORT.md、CI_VALIDATION.md 為證）
- install.sh 指向 `https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh`，需 main branch 有該檔案

**建議**：選項 A（先發布，CI 失敗再修）或 選項 B（保守等 CI）？
請 kk 決定。

# 初始專案驗證

日期：2026-11-23。範圍為 Expo SDK 58 共用程式與本地 Web 預覽，並非原生安裝包或真機驗收。

| 檢查 | 結果 |
|---|---|
| TypeScript 型別檢查 | 通過 |
| Expo ESLint | 通過，無錯誤／警告 |
| Node domain 測試 | 4／4 通過 |
| Expo SDK 依賴相容性 | Dependencies are up to date |
| npm audit | 已知弱點 0 |
| Expo Android export | 成功產生 Hermes bundle |
| Expo iOS export | 成功產生 Hermes bundle |
| Expo Web export | 成功產生 14 個靜態路由 |
| 實際 Web 操作 | 示範登入 → 首頁 → 提問 → 模擬任務 → 回答 → 引用來源 → 收藏 → 儲存個人筆記成功 |
| 瀏覽器警告與錯誤 | 首頁檢查未回報警告／錯誤 |

依賴安全修訂：針對 `@expo/fingerprint` 的間接 `minimatch` 套件使用 `^11.0.1` override，避免 [GHSA-g3hv-75wg-m249](https://github.com/advisories/GHSA-g3hv-75wg-m249)。修訂後重跑相容性、型別、lint、測試及三平台 export。沒有使用會降級 Expo 的強制 audit fix。

domain 測試涵蓋驗證失敗不展示原文、未知狀態與空 final_answer 保守處理、正常答案僅使用受控 final_answer，以及空白／NUL／過長問題拒絕。

## 限制與待驗證

- Expo export 是程式／資產打包，不等於 APK／IPA 建置、簽署、安裝或商店提交。
- 尚未執行 Android／iPhone 真機、原生返回、軟鍵盤、弱網路及背景恢復驗證。
- 沒有正式登入、API、使用者隔離、持久化、通知或真實問題回報。
- 本次沒有讀取正式服務憑證、呼叫模型、搬移知識庫或修改研究原始生成紀錄。
- Node 測試目前有模組型別推斷的工具提示，Expo export 有色彩環境變數提示；均不影響上述通過結果。

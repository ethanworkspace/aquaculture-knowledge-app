# Flutter 0.3.0 線上問答驗證紀錄

日期：2026-11-23。本版已將預設 Flutter 服務切換為真實 HTTPS 工作區登入、v6 知識庫及固定 M2，保留網站背景與圖示。

## 已完成

- Flutter 3.50.1 stable／Dart 3.14.0；format、analyze 無問題。
- Flutter 一般測試：14 項通過，1 項真實推論測試預設跳過。涵蓋回答守門、模型／版本核對、HTTPS 位址限制、相同請求重送、斷線／忙碌、320px 線上登入錯誤與回答來源、示範收藏筆記流程。
- 額外啟用真實 Flutter 客戶端測試：1 項通過，沒有 mock；完成 GitHub 連線探索 → HTTPS 登入 → M2 任務 → 實際引用 → 登出。
- 真實測試問題為「虱目魚常見的養殖方式有哪些？」；狀態為部分資訊（ANSWERED_PARTIAL），有 1 筆實際引用，answer_origin 為 MODEL_GENERATED。這確認了串接與來源回傳，不代表所有問題或答案正確性已驗收。
- 模型為 M2，digest 為 dae161e27b0e90dd1856c8bb3209201fd6736d8eb66298e75ed87571486f4364；知識庫 marine-unified-v6-20261121_160441。
- 後端入口單元測試 7 項通過：token 雜湊與撤銷、失敗限流、固定 M2、無原始模型輸出、任務隔離、UUID 冪等與衝突、忙碌接續及重啟保存。
- 真實 HTTPS 路由回歸通過：原有管理金鑰授權仍有效；未授權請求被拒、手機登入／撤銷正常、帶 Origin 被拒。部署中的 adapter 與本 repo 一致。
- 不含憑證或回答全文的摘要見 [live-verification.json](live-verification.json)。

## APK 檢查

- 檔名：aquaculture-knowledge-app-0.3.0-live.apk，56,324,735 bytes。
- Package：com.ethanworkspace.aquacultureknowledge；versionName 0.3.0／versionCode 3。
- 最低 Android API 24（Android 7.0），target／compile SDK 36。
- arm64-v8a、armeabi-v7a、x86_64 均含 Flutter engine 與 AOT 程式。
- APK v2 簽章驗證通過；採 Release 編譯、開發用 debug 憑證，未設 debuggable；憑證與前次本機 APK 一致。
- 網路權限已加入，明文 HTTP 已停用；五張網站原始 PNG 均在 APK 中，內容逐檔一致。
- 已對公開 repo 檔案及 APK 解壓內容核對，未包含實際管理金鑰或工作區存取碼。
- SHA-256：cfc27fae73f1f7fc0460bcdf3078d6a5bd72e9ebca0b02796502c5968b0927a1。
- 機器可讀資訊見 [apk-verification.json](apk-verification.json)。

## 實際限制

- 未連接 Android 手機，尚未驗證真機安裝、行動網路、背景切換或不同裝置字型；上述畫面檢查屬自動化 widget 測試。
- 需要服務電腦、Ollama、API 與 HTTPS tunnel 在線；不是離線知識庫 App。底層單一推論槽，忙碌沒有排隊承諾。
- 登入是共用研究工作區存取碼，沒有個人帳號。Token 僅在本次程序記憶體，最長 24 小時；關閉／登出後需重新登入。
- 收藏、筆記與手機紀錄只存在本次使用期間。手機清除不會刪除研究後端的問答紀錄。
- 回報、雲端保存、媒體與個人資料刪除服務尚未提供。
- 尚未設定正式商店簽署；iOS 工程未在 macOS 建置或在 iPhone 驗收。APK 僅供 Android。

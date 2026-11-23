# Flutter 0.3.1 驗證紀錄

日期：2026-11-23。**開發測試版主要功能通過，正式發佈驗收尚未完成。** 詳見 [完整驗收報告](ACCEPTANCE.md) 與 [機器可讀結果](acceptance/results.json)。

- 已修正最後一次輪詢完成仍誤顯示等待，以及來源頁顯示內部定位 JSON 的問題。
- Flutter 3.50.1／Dart 3.14.0；format、analyze 無問題。
- 15 項一般 Flutter 測試通過；2 項真實測試預設跳過，另行啟用的正向 M2 問答與範圍外問題檢查皆通過。
- 後端入口 8 項單元測試與真實 HTTPS 授權／撤銷／原有網站 API 回歸通過。
- 已在 Android 15／API 35 模擬器安裝 Release APK，完成登入、兩筆真實 M2 問答、來源、收藏、筆記、背景切換、飛航模式後接續、紀錄、清除與登出。
- 接續沒有新增重複推論；來源逐字查核 2 筆通過；沒有獨立專家語義評分。
- 橫向與 1.3 倍字體已檢查，模擬器當機記錄為空。未測實體 Android 或 iPhone。
- 安裝版 APK SHA-256 與待發布檔完全一致。簽章、版本、網路權限、停用明文 HTTP、原始素材及憑證未內嵌檢查通過。

APK：aquaculture-knowledge-app-0.3.1-live.apk，56,324,735 bytes；package com.ethanworkspace.aquacultureknowledge；versionCode 4；最低 Android 7.0，target SDK 36；arm64-v8a／armeabi-v7a／x86_64。

SHA-256：4cb230316e8da04a79afcd43066345586b646f4d3a46b72bb12cac09ec41ca86。詳見 [apk-verification.json](apk-verification.json)。

一般原生問答約 81 秒；另一次含後端重啟與斷線接續約 5 分鐘，速度仍需優化。本版需要服務電腦與連線服務在線，採開發用簽章。工作區使用共用存取碼，收藏筆記僅在本次程序記憶體；個人帳號、雲端保存、正式簽署及實體裝置驗收未完成。

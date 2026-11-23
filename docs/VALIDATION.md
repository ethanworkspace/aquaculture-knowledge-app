# Flutter 0.3.2 驗證紀錄

日期：2026-11-23。本版改善問答等待，並以安裝後 App 畫面替換 README 原型圖。速度比較見 [PERFORMANCE.md](PERFORMANCE.md)，前版完整功能驗收見 [ACCEPTANCE.md](ACCEPTANCE.md)。

- Flutter format、analyze 通過；15 項一般測試通過，2 項真實服務測試預設跳過，另行啟用的正向與範圍外問題測試皆通過。
- 後端入口與執行優化共 14 項單元測試通過，涵蓋來源／權限、快取隔離與獨立副本、逐題生成、容量淘汰、持續工作執行緒、分批後分數還原及錯誤不快取。
- 真實 HTTPS 比較共 6 次，M2 身分、檢索內容摘要與引文查核通過；每筆有新的生成嘗試，沒有回答快取。
- 同兩題原版平均 26.521 秒，優化首次查詢 19.681 秒，命中檢索快取後重問 5.346 秒。小樣本，不代表所有問題或硬體；重啟預載入此次約 68.47 秒。
- 新 Release APK 已在 Android 15／API 35 模擬器安裝並完成登入、真實 M2 問答、來源與登出；當機紀錄為空。安裝檔 SHA-256 與待發布檔一致，詳見 [native-0.3.2.json](native-0.3.2.json)。
- README 使用本版原始 Android 模擬器截圖；沒有宣稱是實體手機。
- APK 簽章、版本、網路權限、停用明文 HTTP、五張網站原始 PNG 與憑證未內嵌檢查通過。

APK：aquaculture-knowledge-app-0.3.2-live.apk，56,324,735 bytes；版本 0.3.2／versionCode 5；package com.ethanworkspace.aquacultureknowledge；最低 Android 7.0，target SDK 36，支援 arm64-v8a／armeabi-v7a／x86_64。

SHA-256：3aac196ec112f9a5cfef4441f1ee7b70c97f3fa51dc87b64741c15bca66032e4。詳見 [apk-verification.json](apk-verification.json)。

本版仍需服務電腦與 HTTPS 連線在線，採開發用簽章；收藏筆記僅保留於本次執行。實體 Android 手機、不同裝置／網路、多人負載及 iPhone 建置與簽署尚未完成驗證。

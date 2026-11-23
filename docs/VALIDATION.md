# Flutter 0.2.0 驗證紀錄

日期：2026-11-23。主程式已依使用者要求由 Expo 改為 Flutter，保留原型與網站素材。歷史 Expo 驗證見 archive/expo/docs/VALIDATION.md。

## 已完成

- Flutter 3.50.1 stable／Dart 3.14.0。
- Dart format 與 Flutter analyze 通過，無問題。
- Flutter test：8 項通過。
- 6 項 domain 測試：未知／驗證失敗輸出不回補原文、受控 final_answer、輸入限制、七種問答情境、單一任務與清除／釋放後不回寫，以及收藏冪等與獨立筆記。
- 2 項畫面測試：390px 下完整登入→提問→來源→收藏→筆記流程；320px 下登入畫面無溢出。
- Android／iOS 桌面圖示由網站原始魚圖標產生；原始五張 PNG 維持原樣。
- Gradle 使用官方精簡 binary distribution，SHA-256 固定在 wrapper 設定。

## APK 檢查

Debug 與 Release 模式 APK 均已成功產生。下載版採較小的 Release 編譯模式，仍使用開發用 debug 簽章，供功能試用，不是正式商店發佈版。

- 下載檔：aquaculture-knowledge-app-0.2.0-demo.apk，55,095,271 bytes（約 55 MB）。
- Package：com.ethanworkspace.aquacultureknowledge；版本 0.2.0／versionCode 2。
- 最低 Android API 24（Android 7.0），target／compile SDK 36。
- 支援 arm64-v8a、armeabi-v7a 與 x86_64；已核對三種架構的 Flutter engine 與 AOT libapp.so。
- APK v2 簽章驗證通過，下載版未設為 debuggable。
- 網站原有的五張圖像（含背景）均確認存在 APK 資產內。
- SHA-256：c4ed5316b75b7d7689aa74fc13d82d45ca54ab4f3d5c076e0976ff03633687e0。
- 詳細機器可讀結果見 apk-verification.json。

## 使用限制

- 目前採示範登入與模擬問答，不連接正式 RAG、模型或真實帳號。
- 收藏、筆記與紀錄只保留在本次程序執行期間；關閉程式或登出即清除。
- 本次未連接 Android 手機，沒有完成真機安裝及操作驗收。
- iOS 工程已產生，但 Windows 無法完成 Xcode 建置與 iPhone 簽署；APK 只供 Android。
- 下載版為開發用 debug 簽章的 Release 模式測試 APK，不是正式商店發佈版本。簽署私鑰與本機 SDK 路徑不納入 repo。

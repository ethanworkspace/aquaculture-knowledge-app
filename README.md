# 養殖漁業知識平台 Flutter App

可使用 Android Studio 開啟的 Flutter／Dart 專案，Android 與 iPhone 共用主要程式。保留既有網站的海洋水彩背景、圖示、名稱及 API 規格。

## 下載 Android 測試 APK

[下載 0.2.0 Android 測試 APK](https://github.com/ethanworkspace/aquaculture-knowledge-app/releases/download/v0.2.0-demo/aquaculture-knowledge-app-0.2.0-demo.apk)（約 55 MB，Android 7.0 以上）。[版本說明與校驗碼](https://github.com/ethanworkspace/aquaculture-knowledge-app/releases/tag/v0.2.0-demo)。下載 `.apk` 後可在 Android 手機安裝，不需要 Expo Go。APK 不能安裝到 iPhone。

目前為 **0.2.0 開發示範**：主要畫面與操作已轉為 Flutter，問答仍使用模擬服務，未接正式帳號、v6 知識庫或 M2。示範資料只保留在本次執行期間，不提供實際養殖建議。

## 開發與打包

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

輸出：`build/app/outputs/flutter-apk/app-release.apk`。目前使用 Release 編譯模式與開發用 debug 簽章；正式發佈簽署與商店上架尚未設定。除錯時可改用 `flutter build apk --debug`。

在 Android Studio 開啟本專案根目錄，設定 Flutter SDK，即可選擇 Android 手機／模擬器執行。Windows 的輔助腳本為 `scripts/build-apk.ps1`，詳細說明見 [開發指南](docs/DEVELOPMENT.md)。

iOS 工程已包含在 `ios/`，正式 iPhone 版本需在 macOS／Xcode 另行建置與簽署；本次不宣稱 iOS 打包或真機驗證通過。

## 功能與目錄

| 位置 | 內容 |
|---|---|
| `lib/` | Flutter 首頁、問答、回答來源、收藏筆記、紀錄與我的 |
| `android/` | Android Studio／Gradle 工程 |
| `ios/` | iPhone 的 Xcode 工程 |
| `assets/website/` | 網站原始水彩背景與圖示，包含來源與 SHA-256 |
| `test/` | 業務與手機畫面測試 |
| `prototype/v1/` | 原有可點選 HTML 畫面原型與素材 |
| `docs/api/` | 現有 API 盤點與待實作的 App 服務入口契約 |
| `archive/expo/` | 先前 Expo 起點的歷史原始碼，不是目前 APK 打包目標 |

可操作流程：示範登入 → 選魚種／提問 → 模擬回答 → 引用來源 → 收藏 → 編輯獨立筆記。從「我的」可查看紀錄、切換七種問答情境、清除資料及登出。

## 沿用既有引擎

`Flutter App → 使用者登入與 App 服務入口 → 現有私有問答 API → v6 知識庫／M2`。

現有 [Hybrid-RAG 專案](https://github.com/ethanworkspace/hybrid-rag-aquaculture-knowledge-platform) 保留知識庫、模型與研究紀錄。本 repo 不包含共用 API 金鑰、原始資料庫、第三方來源全文、模型或使用者資料。QuestionService 目前為模擬實作，正式入口仍待開發。

## 驗證與授權

實際檢查與 APK 限制見 [驗證紀錄](docs/VALIDATION.md)。原型預覽如下（示意稿，不是 Android 實機截圖）：

![網站風格的 App 原型](prototype/v1/preview-website-theme.jpg)

程式沿用 MIT 授權。網站素材來源與雜湊見 assets/website/README.md 與 manifest.json；不擴及未包含的第三方知識來源或模型。

參考：[Flutter Android 打包](https://docs.flutter.dev/deployment/android)、[Android 開發環境](https://docs.flutter.dev/platform-integration/android/setup)。

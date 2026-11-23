# Flutter／Android Studio 開發

主專案為 repository 根目錄的 Flutter 專案。先前 Expo 程式保存在 `archive/expo/` 作為歷史參考；不再作為主開發路徑。

## 開啟專案

1. 安裝 Flutter 穩定版 SDK 與 Android Studio 的 Flutter／Dart 外掛。
2. 在 Android Studio 開啟本專案根目錄（有 pubspec.yaml 的資料夾），設定本機 Flutter SDK。
3. 使用 Android SDK Manager 準備對應的 Android 平台與 Build Tools，並使用相容 JDK。
4. 執行 `flutter pub get`；選擇手機或模擬器後執行 `flutter run`。

## 檢查與產生 APK

```sh
dart format lib test
flutter analyze
flutter test
flutter build apk --release
```

輸出：`build/app/outputs/flutter-apk/app-release.apk`。這是 Release 模式的可安裝測試版，目前採本機 debug 簽章，沒有正式發佈金鑰。Windows 也可執行 `scripts/build-apk.ps1`，以參數指定 Flutter／Android SDK 與 JDK；需要除錯版時加上 `-Mode debug`，輸出為 app-debug.apk。

同一套 Dart 程式已包含 `ios/` 工程，但 iPhone 不能安裝 APK。iOS 安裝版本需在 macOS／Xcode 另行建置與簽署；本次沒有驗證 iOS 原生建置。

## 程式與素材

- `lib/main.dart`：App 主題、登入狀態與應用入口。
- `lib/screens.dart`：首頁、問答、回答來源、收藏筆記、我的與紀錄；使用 Flutter 畫面元件。
- `lib/domain.dart`：任務、答案、來源、模擬服務與個人狀態；預留 QuestionService 介面。
- `assets/website/`：網站原始背景與圖示；由 flutter_launcher_icons 產生 Android／iOS 需要的桌面圖示尺寸。
- `test/`：回答守門、輸入限制、任務清除與登入到收藏筆記的畫面測試。

## 後續工作

1. 建立使用者登入與 App 專用服務入口，再接現有 v6／M2。
2. 實作任務權限、真正 request_id、斷線恢復、個人收藏、刪除及雲端保存。
3. Android／iPhone 真機測試、弱網路、字體放大與背景切換。
4. 設定正式簽署與封閉測試；不在 GitHub 提交簽署私鑰或服務金鑰。

現有畫面中的登入、回答、引用、回報與筆記仍是明示的本次執行期間示範，並非正式帳號或真實 RAG 結果。

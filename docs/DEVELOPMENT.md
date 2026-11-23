# Flutter／Android Studio 開發

主專案為根目錄的 Flutter 工程。用 Android Studio 開啟有 pubspec.yaml 的資料夾，設定 Flutter SDK 與 Android SDK／JDK，執行 flutter pub get 後選擇手機或模擬器。

## 檢查與打包

```sh
dart format lib test
flutter analyze
flutter test
python -m unittest discover -s server -v
flutter build apk --release
```

Release 輸出為 `build/app/outputs/flutter-apk/app-release.apk`。Windows 可用 scripts/build-apk.ps1 指定 SDK／JDK。APK 目前採開發用 debug 簽章，私鑰不可提交 repo。Android 已開啟網路權限並停用明文 HTTP。

預設 GatewayService 連接真實服務。離線畫面開發可用 `flutter run --dart-define=DEMO_MODE=true`；畫面會標示示範。原始網站素材在 assets/website/。

## 真實問答測試

test/live_gateway_test.dart 預設跳過，避免一般測試觸發推論。自行在測試程序環境設 MARINE_LIVE_TEST=1、MARINE_TEST_ACCESS_CODE（既有存取碼），再執行：

```sh
flutter test test/live_gateway_test.dart --reporter expanded
```

存取碼只能透過私密程序環境傳入，不要寫入 shell 歷史、repo、建置參數或 --dart-define。MARINE_TEST_RESULT_PATH 可輸出不含憑證／答案全文的摘要。本測試呼叫真實 M2 並確認來源存在，需服務電腦、Ollama、API 與 HTTPS tunnel 在線，推論槽空閒。

## 程式與後續

- lib/main.dart：主題、登入與預設真實服務。
- lib/gateway_service.dart：HTTPS 連線清單、token、固定識別碼、輪詢與版本核對。
- lib/domain.dart：回答守門、接續、收藏與本次狀態；保留明示示範服務。
- lib/screens.dart：網站背景、實際引用與可恢復錯誤。
- server/：同現有 API 程序執行的 App 入口與整合差異。

後續為 Android／iPhone 真機、弱網路／背景切換、正式簽署、固定網域與部署、個人帳號及雲端收藏。iOS 工程已包含，需在 macOS／Xcode 建置簽署，Windows 本次未測 iOS 建置。

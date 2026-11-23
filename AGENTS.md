# Flutter application

The active application is Flutter/Dart at the repository root. Android Studio can open this root or the android/ subproject. The user explicitly chose Flutter and installable APK delivery.

- Preserve the website watercolor assets and name 養殖漁業知識平台.
- Keep prototype/v1/ and docs/api/. archive/expo/ is historical reference, not the active app.
- Never embed the private RAG API key or publish databases, models, user data, signing keys, or local.properties.
- Keep demo data visibly marked. Do not present mock answers as actual RAG output.
- Run dart format, flutter analyze, flutter test, and flutter build apk when the SDK is available.
- Record build/test limits. APK is for Android; iOS requires a separately signed macOS build.

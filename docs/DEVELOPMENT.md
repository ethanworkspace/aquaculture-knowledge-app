# App 開發與下一階段

## 選型

本機已有 Node.js 與 Android SDK，採用 React Native／Expo／TypeScript，可共用 Android 與 iOS 主要程式。以 Expo Router 管理導覽，Safe Area 與鍵盤避讓處理手機基本佈局。平台目錄依官方 Continuous Native Generation 流程產生。

## 已建立

- 主畫面與網站同名，沿用網站五張原創水彩 PNG，背景裁切為直向配置。
- 四個底部入口：首頁、問答、收藏、我的；詳情頁另有回答、來源、個人筆記與紀錄。
- QuestionService 目前只有 mock 實作。UI 不直接連接共用 RAG 服務，也不提供輸入伺服器管理金鑰的欄位。
- 任務可在使用者離開回答頁後於記憶體中完成；清除資料或登出會使舊任務結果失效。這不是手機背景推論／程序重啟恢復。
- 個人筆記與回答快照分開，避免把編輯後文字冒充來源證據。

## 待完成順序

1. 確認正式 App 的帳號服務、使用者資料保存及刪除規則。
2. 建立 App 專用服務入口。實作任務擁有者、個人紀錄、收藏、刪除與回報；完整定義錯誤碼、限流與任務狀態。
3. 加入 gateway QuestionService、登入 Token 安全儲存、真正 UUID、任務 ID 保存與斷線後查詢。不把共用 API Key 放入 EXPO_PUBLIC 變數或 App bundle。
4. 驗證 M2 真實問答、引用原文、圖片授權與 v6 版本定位；不能把 mock 通過當作真實引擎通過。
5. Android 與 iPhone 實機驗證：小螢幕、放大字體、鍵盤、返回手勢、螢幕閱讀器、弱網路、前背景切換與多帳號隔離。
6. 設定 Expo／Apple／Google 開發者專案與簽署，產生封閉測試版本。這些帳號與簽署步驟尚未執行。

## 檢查

```sh
npm run typecheck
npm run lint
npm test
npm run export:web
```

Web export 只驗證共用程式能打包，不代表 Android／iOS 原生建置或真機測試完成。`docs/VALIDATION.md` 記錄實際結果。

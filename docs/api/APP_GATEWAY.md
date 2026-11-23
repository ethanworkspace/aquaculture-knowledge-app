# App 服務入口 v1（0.3.0 已部署部分）

日期：2026-11-23。原有研究 API 見 [EXISTING_API.md](EXISTING_API.md)。原有 `/v1/` 授權與路由保留；手機使用新增的 `/app/v1/`，共用管理金鑰不傳給手機。

## 工作區連線

本版為**共用研究工作區**，沒有個人帳號。使用網站存取碼取得 24 小時隨機 bearer token。Token 只存在 App 記憶體；伺服器只存 SHA-256。登出撤銷 token 與請求映射。每個 token 的任務隔離，不能讀取其他連線或既有研究歷史。

App 經 GitHub HTTPS 讀取 `hybrid-rag-aquaculture-knowledge-platform/main/streamlit_cloud/backend_endpoint.json`，核對服務名稱，只接受無帳密、無特殊路徑的 HTTPS `*.trycloudflare.com` 位址。手機沒有共用 HMAC 金鑰；連線清單依賴 GitHub 帳號與 TLS 完整性。API 不自動重新導向，不放寬憑證驗證。

## 已實作路由

| 方法與路徑 | 輸入／回傳 |
|---|---|
| POST `/app/v1/session` | `{access_code}`；回傳 session_token、expires_at、M2 digest、corpus_version、workspace_mode |
| DELETE `/app/v1/session` | Bearer token；撤銷目前連線 |
| GET `/app/v1/status` | Bearer token；安全的服務、模型與知識庫資訊 |
| POST `/app/v1/jobs` | Bearer token；request_id UUID、question、selected_species；回傳 RUNNING／DONE／FAILED |
| GET `/app/v1/jobs/{request_id}` | Bearer token；只讀目前連線擁有的請求 |

POST 必須為 JSON，最多 16 KiB；自由問題最多 2,000 字，魚種沿用既有驗證。App 不能指定模型或檢索上下文，服務端固定 M2。底層維持單一推論槽，忙碌回傳 429，沒有新增排隊。登入失敗每分鐘最多 8 次（目前全服務共用），每連線每分鐘最多建立 10 筆請求映射。

App 保留 UUID 與完整輸入，接續時重送相同 POST，由既有服務冪等地取回同一任務，再輪詢 GET。伺服器另配內部 UUID，避免與其他連線／研究任務撞號。同 UUID 改內容回傳 409；FAILED 新嘗試需新 UUID。手機超時不代表後端取消。關閉程式後 token 與手機紀錄不保存，不能跨次執行續接。

## 回答與錯誤

DONE.record 包含 model_id、model_digest、corpus_version、answer_status、answer_origin、final_answer、missing_information、evidence。入口與手機皆核對 M2 身分；手機亦核對登入時的知識庫版本。

狀態為 ANSWERED_GROUNDED、ANSWERED_PARTIAL、INSUFFICIENT_EVIDENCE、VALIDATION_FAILED。未知／驗證失敗以受控訊息取代，不顯示原始模型輸出或來源。來源只來自 supporting_chunk_ids 對應的本次 top5，優先採驗證過的引文，否則為原始檢索摘錄。缺頁碼時不自行補造；本機路徑不公開。

錯誤格式：`{"error":{"code":"SERVICE_BUSY","message":"…","retryable":true}}`。涵蓋存取碼錯誤、連線到期、無此任務、輸入錯誤、衝突、忙碌、限制、模型身分錯誤及服務離線。網路中斷、忙碌與可恢復錯誤顯示「接續原請求」。

## 待實作

個人帳號、歷史分頁 API、雲端收藏／筆記、回報、媒體路由與研究資料刪除政策仍待實作。本版收藏、筆記與紀錄僅在手機記憶體，沒有雲端保存或個人資料刪除服務。

0.3.1 將結構化來源定位轉為原資料實際提供的頁碼或章節，例如「文件第 3 頁」；內部 document_id、element_id 及 bbox 不呈現在手機來源畫面。沒有可讀定位時明示缺漏。

部署來源見 [server/README.md](../../server/README.md)，本次實際驗收見 [ACCEPTANCE.md](../ACCEPTANCE.md)。

0.3.2 沿用相同 API 契約，服務新增精確檢索快取與啟動預載入；新請求仍執行 M2。手機每秒輪詢一次，等待預算維持 10 分鐘。重啟後的第一個問題可能等待準備完成；沒有新增多人任務排隊承諾。速度與測量範圍見 [PERFORMANCE.md](../PERFORMANCE.md)。

# App 服務入口契約草案（未實作）

現行 API 的實作與限制見 [EXISTING_API.md](EXISTING_API.md)。本文件是新的服務入口邊界，不代表既有後端已支援。

## 授權與資料

App 使用「使用者登入 Token」，不是現有服務共用 Key。入口核對每個任務、回答、收藏、紀錄及媒體的所有權；伺服器自行保管共用 RAG 金鑰。公開 App 內不包含 Token 範例值或服務管理金鑰。

歷史研究紀錄不自動歸屬新帳號；個人資料另存，不改寫 Frozen Corpus 與研究原始生成。

## 首次串接所需

| 方法與路徑 | 契約 |
|---|---|
| GET `/app/v1/bootstrap` | questions、sources、corpus_version、default_model_id；移除內部執行環境資訊 |
| POST `/app/v1/jobs` | question 或 question_id、selected_species、request_id UUID；入口固定 M2，回傳狀態與識別碼 |
| GET `/app/v1/jobs/{id}` | RUNNING／DONE／FAILED；只可讀本人任務；完成時包含 guarded record、實際 corpus_version |
| GET `/app/v1/history?cursor=...` | 本人分頁紀錄；cursor 不暴露內部路徑 |
| GET／POST `/app/v1/saved-answers` | 不可變回答快照、獨立 personal_note；同一回答收藏具冪等性 |
| PATCH／DELETE `/app/v1/saved-answers/{id}` | 只編輯個人筆記／刪除本人收藏 |
| POST `/app/v1/feedback` | attempt_id、reason、comment；只接受本人可讀的回答 |
| GET `/app/v1/media/{id}` | 本人回答引用且可展示的媒體，不只檢查全域曾公開登錄 |
| DELETE `/app/v1/history/{id}`、DELETE `/app/v1/me/data` | 刪除範圍、再次驗證與備份政策須先定義 |

請求 body 上限沿用現有約束：自由問題最多 2,000 字；request_id 與完整欄位集合維持不變，避免重試 digest 改變。

目前底層只有單一推論槽，忙碌返回 429；不可承諾 QUEUED、順位或等待時間，除非入口實際新增排程。

## 任務與回答

網路恢復先查詢原 request_id。DONE 可取回原結果；FAILED 重送同 ID 不會重新執行，新的明確嘗試要使用新 UUID。手機顯示超時不等於伺服器停止，不能盲目建立重複推論。

回應只提供可顯示的 final_answer，不包含 raw_model_answer。answer_status 必須明確區分 ANSWERED_GROUNDED、ANSWERED_PARTIAL、INSUFFICIENT_EVIDENCE、VALIDATION_FAILED；未知狀態保守處理。來源僅顯示實際 supporting_chunk_ids 可對應的片段，缺漏頁碼不能自行補造。

錯誤格式建議統一：`{ "error": { "code": "SERVICE_BUSY", "message": "目前服務忙碌，請稍後再試。", "retryable": true } }`。至少區分未登入、權限不足、無此任務、輸入無效、忙碌、引擎離線及任務失敗。

模擬服務的 demo-* 識別碼與文案只供本機畫面，不可直接傳往正式 API。

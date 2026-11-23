# App v1：現有 API 盤點與串接缺口

盤點日期：2026-11-23。依程式碼靜態核對，未呼叫正式服務、讀取憑證、重新生成答案或改寫知識庫。

## 核對來源

- `research_staging/deployment/streamlit_cloud_20261122_143650/backend/rag_api.py`：現有 HTTP Handler、任務及公開回答轉換。
- 同目錄 `website_answer_guard.py`：網站回答守門。
- `research_staging/app_sessions/launch_20261118_154253/knowledge_notes.py`：筆記限制與儲存。
- `streamlit_cloud/cloud_client.py`：前端呼叫、連線探索及錯誤處理。
- `research_staging/unified_rag_active.json`：指向 `marine-unified-v6-20261121_160441`。

以下「現有」表示上述版本的實作，非已驗證的即時線上可用性。

## 架構與授權

現行服務為 Python HTTP Server，預設綁定 `127.0.0.1:8765`，經 HTTPS 連線提供給 Streamlit 伺服器。除 `/health` 外均以共用 `Authorization: Bearer <server-only-key>` 驗證。它不是使用者登入 Token。

帶 `Origin` 的請求會被拒絕（403）；未實作瀏覽器跨來源預檢。手機 App／原型不可直接內建共用金鑰。正式方案應由「App → 帳號服務入口 → 既有私有 RAG」串接，服務入口負責登入、權限、任務歸屬、限流及可展示資料的轉換。

## 現有端點

| 方法／路徑 | 請求 | 成功回應 | 限制／App 用途 |
|---|---|---|---|
| GET `/health` | 無 | `{status:"ok",service:"marine-knowledge-api"}` | 不需授權；僅代表 HTTP 程序存活，不代表模型、索引或 GPU 已就緒 |
| GET `/v1/bootstrap` | Bearer | `questions`, `sources`, `corpus_version`, `model_ids`, `default_model_id`, `models`, `security_runtime` | questions、sources 為 ID 對應物件；包含 180 題與來源目錄。App 入口需移除不必要執行環境資訊 |
| POST `/v1/jobs` | 問題 JSON | 新任務或既有未完成任務為 202；已完成任務為 200；包含 `status`, `request_id`，完成時含 `record` | App 首選；單一問答槽，忙碌為 429，沒有 QUEUED 或順位 |
| GET `/v1/jobs/{request_id}` | UUID | `{status,request_id,record? ,error?}` | RUNNING／DONE／FAILED；未知或無效 ID 為 404。沒有使用者歸屬檢查 |
| POST `/v1/ask` | 同問題 JSON | `{record}` | 同步、阻塞直到完成；不建議手機作主要路徑 |
| GET `/v1/history` | 無篩選參數 | `{records:[...]}` | 最近 50 筆取出後反轉為時間由舊到新；全工作區共用，沒有分頁與個人隔離 |
| GET `/v1/notes` | query、species、topic | `{notes:[...]}` | query 僅取前 200 字；依更新時間倒序，搜尋標題與內容；沒有分頁 |
| POST `/v1/notes` | 筆記 JSON | `{note_id}` | 新增或更新；共用資料，沒有刪除介面 |
| GET `/v1/media/{asset_id}` | 圖像資產 ID | PNG／JPEG／WebP 二進位內容 | 限已公開回答登錄過的資產、核准根路徑內檔案、≤8 MiB；無圖為 404。此登錄不是第三方公開散布授權 |

未實作：登入、註冊、重設密碼、Token 更新、登出撤銷、個人收藏刪除、紀錄刪除、帳號刪除、問題回報、任務取消、完整來源文件下載及獨立來源詳情端點。

## 問答請求契約

自由問答：

```json
{
  "request_id": "448670d7-27cd-4406-9980-fc3eca76365b",
  "question": "虱目魚養殖遇到寒流時，應先確認哪些資料？",
  "selected_species": "虱目魚",
  "model_id": "M2"
}
```

題庫問答：`{"request_id":"<UUID>","question_id":"<bootstrap 中實際 ID>","model_id":"M2"}`。不可同時傳 question 與非空 question_id。

- 僅接受 `question`, `question_id`, `selected_species`, `model_id`, `request_id`；不能外部注入 Context／Prompt／來源。
- request_id 必填 UUID；自由問答去除空白後不可空、最多 2,000 字，不可含 NUL。
- selected_species：全部魚種、虱目魚、吳郭魚、石斑魚、鱸魚、烏魚、鰻魚。預設全部魚種。
- model_id：M1／M2／M3／M4；預設 M2。逐次核對模型 digest。
- JSON 必須為物件；POST 必須單一 Content-Length、不得 Transfer-Encoding、Content-Type 為 application/json，body 長度 2–131072 bytes。

### 任務恢復與重試

1. 本機保存 request_id、原始請求與登入者歸屬，提交 `/v1/jobs`。
2. RUNNING 時輪詢同一 ID；目前 Streamlit 每秒輪詢，600 秒後停止等待。這是客戶端策略，非服務端承諾。
3. 相同 ID 必須保留**完全相同 JSON 欄位與值**。digest 對完整 body 計算；省略 M2 與明傳 M2 也可能不同。內容不一致為 400。
4. DONE 重送可取回結果。FAILED 重送同一 ID 仍是 FAILED，需新 ID 才是新嘗試。
5. 斷線時先查原任務，避免直接新建。服務重啟會把保存的 RUNNING 改成 FAILED；這不等於能接續模型生成。
6. 忙碌 429 沒有保存成排隊任務；前端不可顯示順位或保證稍後自動執行。
7. 目前未見任務取消、跨程序鎖或容量排程；多人 App 需要由服務入口補上策略。

## 回答與來源欄位

record 包含 `attempt_id`, `question_id`, `question`, `model_id`, `model_digest`, `context_digest`, `prompt_version`, `at`, `api_completed`, `api_error`, `question_payload`, `result`。

- `question_payload`：question_id、question、species、category、free_question、top5。
- `top5` 已過濾成實際被引用的 Context，**不是保證五筆**；每筆含 chunk_id、source_id、source_version、source_record_id、exact_locator、source_quote、media_assets。
- 圖片欄位是 `remote_asset_id`, page, kind；使用 remote_asset_id 組 `/v1/media/{id}`。
- `result`：answer_status、answer_origin、raw_model_answer、final_answer、supporting_chunk_ids、missing_information、validation_status。
- 顯示文字只用 `final_answer`。不可把 raw_model_answer 當成守門失敗的備用輸出。App 服務入口應刪除 raw_model_answer，避免終端取得被攔截原文。
- 將 supporting_chunk_ids 對應 top5，以 bootstrap.sources[source_id] 取得 title、publisher、attribution。來源不完整時顯示缺漏，不虛構頁碼或標題。
- exact_locator 未承諾固定資料型別，需容忍文字、結構及缺值。只在已有明確頁碼時顯示頁碼。
- 目前公開 record 沒有固定 corpus_version 欄位；App 應要求服務入口以本次實際執行版本寫入，而非僅使用可能過期的 bootstrap 快取。

| answer_status | App 呈現 |
|---|---|
| ANSWERED_GROUNDED | 有據回答，附可查來源；不表示專家認證 |
| ANSWERED_PARTIAL | 部分資訊，列出 missing_information |
| INSUFFICIENT_EVIDENCE | 證據不足，提示可補充資訊 |
| VALIDATION_FAILED | 回答待核對，不顯示被攔截原文 |
| 未知值 | 保守顯示未能提供回答，記錄診斷，不當成功 |

answer_origin 另外區分 MODEL_GENERATED、DETERMINISTIC_EVIDENCE_EXTRACTION、SYSTEM_GUIDANCE、ABSTAINED、VALIDATION_FAILED。不能把來源摘取、系統指引算成模型直接成功作答。

守門可能攔截未充分核實的用藥內容或未被要求的管理數值；此時清除引用 Context，保留受控提示。其餘文字亦不因此保證專業正確。

## 小知識契約

POST 欄位：title、body、species、topic、note_id（更新時）、origin、provenance。

- title：去空白後 1–80 字；body：1–8,000 字。
- species：通用或六類魚種，**不同於問答的「全部魚種」**。
- topic：養殖管理、水質環境、魚種認識、氣候防寒、疾病觀察、其他。
- origin：PERSONAL_NOTE 或 SAVED_RAG_ANSWER。provenance 為物件，JSON 字串長度 ≤16,000。
- note_id 更新時需 32 位小寫十六進位；找不到時 400。現行更新只變更標題、內容、魚種、主題、更新時間，不更新 origin／provenance。
- GET note 列包含 note_id、title、body、species、topic、origin、**provenance_json（字串）**、created_at、updated_at；服務入口宜統一轉為 provenance 物件。
- 若收藏答案後直接編輯 body，原證據與改寫內容可能不一致。App 應分開保存不可變 answer_snapshot 與 personal_note，而非把改寫答案仍標為有據回答。

## HTTP 錯誤

| 狀態 | 已有含義 | 手機處理 |
|---|---|---|
| 400 | 欄位、UUID、JSON 或同 ID 請求不一致 | 修正資料，不自動無限重試 |
| 401 | 共用服務金鑰不符 | 由服務入口處理；不能一律當使用者密碼錯誤 |
| 403 | 帶 Origin 被拒絕 | 使用服務入口，非瀏覽器直接連線 |
| 404 | 路徑、任務、圖片不存在 | 依資源提供缺漏狀態 |
| 413／415 | 長度／媒體格式錯誤 | 限制輸入及修正請求 |
| 429 | 問答忙碌，或全服務授權失敗過多 | 現有均只有 error 文字；需新增機器可讀 code 以區分，不展示虛構排隊數 |
| 503 | 未完成的內部錯誤 | 先查原任務再決定重試 |

現行錯誤大多是 `{error:"文字"}`；沒有統一錯誤碼／Retry-After 承諾。

## App 新增契約草案（尚未實作）

| 功能 | 建議對 App 路徑 | 必要條件 |
|---|---|---|
| 登入、註冊、密碼重設 | 交由選定帳號服務 | 可撤銷登入、Token 更新、登出及帳號刪除 |
| 初始化／問答 | `/app/v1/bootstrap`, `/app/v1/jobs`, `/app/v1/jobs/{id}` | 使用者 Token；模型先固定 M2；檢查任務所有權；回傳 error.code、corpus_version |
| 個人紀錄 | GET／DELETE `/app/v1/history`、DELETE `/app/v1/history/{id}` | 使用者隔離、cursor 分頁、刪除與保存政策 |
| 收藏 | GET／POST `/app/v1/saved-answers`、PATCH／DELETE `/app/v1/saved-answers/{id}` | 不可變回答快照、獨立個人筆記、擁有者檢查及重複收藏策略 |
| 回報 | POST `/app/v1/feedback` | attempt_id、原因、備註；只有本人有權讀取的回答可回報 |
| 圖片 | GET `/app/v1/media/{id}` | 回答權限與來源授權檢查，不能只依全工作區 published_media |
| 我的／刪除資料 | GET／DELETE `/app/v1/me`、DELETE `/app/v1/me/data` | 再驗證、刪除範圍與備份保存政策 |
| 狀態 | GET `/app/v1/status` | 區分入口、引擎可連線與推論可用性；不洩漏內部環境 |

歷史研究工作區不自動歸屬任一新使用者。私人資料另存，不修改 Frozen Corpus 或原始研究生成紀錄。

## 開發優先順序

1. 確認本文件與畫面原型；凍結 App 回答、來源、任務及錯誤格式。
2. 建立帳號服務入口與使用者資料表；先以測試帳號驗證隔離。
3. Android／iPhone 打通 M2 提問 → 任務恢復 → 回答 → 來源。
4. 加入收藏、獨立筆記、紀錄、刪除及回報。
5. 導入穩定連線、容量策略及真機弱網路測試後進行封閉測試。

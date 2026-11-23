# Existing RAG service integration

mobile_gateway.py is the deployed standard-library adapter around the existing Service in backend/rag_api.py. It reuses the active corpus, source registry, validate_question, start_job and job. It does not copy the corpus or load another model. Original management-key routes remain unchanged.

rag_api_integration.patch records the exact deployed mobile and serving changes. Copy both mobile_gateway.py and serving_runtime.py beside rag_api.py, review/apply the patch against the matching deployment, and use the existing restart workflow after confirming no question is running. The adapter dispatches /app/v1/ before legacy management-key authorization and initializes MobileGateway with the existing server-side workspace code and SQLite inside service.state. Do not publish credentials, state or endpoint signing secrets.

Version 0.3.2 adds a persistent inference worker, startup model preparation, length-bucketed CPU reranking and a bounded exact retrieval cache. It retains the existing 40 candidates, FP32 checkpoint and 512-token window; it restores scores to original input positions before the existing ranking code runs. The cache contains retrieval traces, never generated answers. It uses the exact question/species/limit, corpus version/SHA, policy version and checkpoint path, returns deep copies, holds at most 16 entries and is cleared on restart. Every new job still invokes the generator and existing answer/citation guard.

The startup preload runs on the same worker as asynchronous questions; a first question can wait for preparation. Synchronous legacy calls share the runtime initialization lock. PRIVATE phase timings are written to service.state/serving_timings.jsonl with opaque request IDs and numbers, without questions, prompts, answers, source text or tokens. Rerank timing is contained in retrieval timing and must not be summed twice. Local CPU defaults are measured on this development machine, not universal hardware recommendations. See the [performance report](../docs/PERFORMANCE.md).

SQLite persists token hashes and per-session request mappings across API restarts. The original RAG service retains research results; mobile logout/clear does not delete them. Sessions expire after 24 hours and are cleaned up on login. This is a shared workspace, not an individual-account system.

Discovery reuses the website's GitHub endpoint manifest and tunnel update tooling. The client relies on GitHub HTTPS and validates the Cloudflare hostname; it does not embed the website HMAC key. A tunnel address change requires mobile re-login. Production deployment should use a stable domain and proper individual authentication when needed.

Run without GPU, model or credentials:

```sh
python -m unittest discover -s server -v
```

See the [implemented API contract](../docs/api/APP_GATEWAY.md) and [validation](../docs/VALIDATION.md). Mobile clients never receive the legacy RAG API key or raw model output.

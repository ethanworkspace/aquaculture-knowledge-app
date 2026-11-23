# Existing RAG service integration

mobile_gateway.py is the deployed standard-library adapter around the existing Service in backend/rag_api.py. It reuses the active corpus, source registry, validate_question, start_job and job. It does not copy the corpus or load another model. Original management-key routes remain unchanged.

rag_api_integration.patch records the exact deployed changes: import the adapter, dispatch /app/v1/ before legacy management-key authorization in GET/POST/DELETE, and initialize MobileGateway in Server with the existing server-side workspace access code and SQLite inside service.state. Copy the adapter beside rag_api.py, review/apply the patch against the matching deployment, and use the existing restart workflow after confirming no question is running. Do not publish credentials, state or endpoint signing secrets.

SQLite persists token hashes and per-session request mappings across API restarts. The original RAG service retains research results; mobile logout/clear does not delete them. Sessions expire after 24 hours and are cleaned up on login. This is a shared workspace, not an individual-account system.

Discovery reuses the website's GitHub endpoint manifest and tunnel update tooling. The client relies on GitHub HTTPS and validates the Cloudflare hostname; it does not embed the website HMAC key. A tunnel address change requires mobile re-login. Production deployment should use a stable domain and proper individual authentication when needed.

Run without GPU, model or credentials:

```sh
python -m unittest discover -s server -v
```

See the [implemented API contract](../docs/api/APP_GATEWAY.md) and [validation](../docs/VALIDATION.md). Mobile clients never receive the legacy RAG API key or raw model output.

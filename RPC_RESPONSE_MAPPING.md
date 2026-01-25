# RPC Response Mapping (Week 2)

| Error message | UI meaning |
|---|---|
| AUTH_REQUIRED | Login required |
| NO_TENANT_SELECTED | Select a workspace |
| WRITE_NOT_ALLOWED | Workspace is read-only (status gating) |
| IDEMPOTENCY_KEY_REQUIRED | Retry (missing op id) |
| DEAL_ID_REQUIRED | Retry (missing deal id) |
| EXPECTED_ROW_VERSION_REQUIRED | Reload and try again |
| ROW_VERSION_CONFLICT | Record changed elsewhere |
| NOT_FOUND | Item not found |

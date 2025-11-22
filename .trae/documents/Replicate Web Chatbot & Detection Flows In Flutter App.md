## Scope Update
Implements the web-spec flows for chatbot and disease detection: token-auth on all requests, session lifecycle, idempotency, streaming (SSE fallback), resilient retries, and local persistence keys. Aligns mobile app with your provided API contract.

## Current State (App)
- Chatbot uses `/health`, `/v1/sessions`, `/v1/chat/history`, `/v1/chat/send` with no auth token or idempotency: `lib/services/chatbot_api.dart:5–64`, `lib/pages/ai_chatbot_page.dart:22–49, 90–179`.
- Disease detection uses `/health`, `/labels`, `/predict` single-shot analysis, no session/job polling: `lib/services/disease_api.dart:7–84`, `lib/pages/disease_detection_page.dart:86–179`.
- Persistence with `SharedPreferences`: session onboarding keys exist: `lib/services/session_manager.dart:3–41`.

## Data & Storage Keys
- `auth:token` — read/write via `SharedPreferences`.
- `chat:sessionId`, `chat:history:<sessionId>` — persisted as JSON array of `{id, role, content, createdAt}`.
- `detect:sessionId`, `detect:lastJobId`.
- `ui:cameraPermissionGranted`.

## Service Layer Changes
### ChatbotService (replace endpoints)
- Base: `https://mitran-chatbot.onrender.com` (keep, but change paths per spec).
- `POST /v1/chat/sessions` with optional metadata `{ appVersion, deviceId }` → returns `{ sessionId, createdAt, expiresAt }`.
- `GET /v1/chat/sessions/:id` → returns `{ sessionId, messages? }`.
- `POST /v1/chat/messages` with headers `Authorization`, `X-Session-Id`, `Idempotency-Key` and body `{ role: "user", content, attachments? }` → returns `{ messages: [...] }`.
- Optional streaming: `GET /v1/chat/stream?sessionId=<id>` using EventSource polyfill if available; otherwise fallback to sync.
- `DELETE /v1/chat/sessions/:id` to reset.
- Add auth header from `auth:token`. Implement idempotency with a UUID.
- Persist updates to `chat:history:<sessionId>` after each send.

### DiseaseService (replace endpoints)
- Base: `https://mitran-disease-detection.onrender.com` (keep, change paths per spec).
- `GET /v1/ai/health` → `{ status }`; if not `ready`, call `POST /v1/ai/warmup` and poll health until `ready`.
- `POST /v1/detection/sessions` → `{ sessionId }`.
- `POST /v1/detection/analyze` (multipart): headers `Authorization`, `X-Session-Id`; body fields `image`, `model?`, `options?` → returns `{ jobId, status, result? }`.
- `GET /v1/detection/jobs/:jobId` for polling; optional `GET /v1/detection/stream/:jobId` for SSE.
- `POST /v1/detection/feedback`.
- Persist `detect:sessionId` and `detect:lastJobId`.

## UI Logic Changes
### Chatbot Page
- Initialization:
  - Read `auth:token`; if missing, show auth-required banner.
  - Read `chat:sessionId`; if missing/expired: create via `POST /v1/chat/sessions` → store.
  - Hydrate history via `GET /v1/chat/sessions/:id` and merge with `chat:history:<id>`; render.
- Send message:
  - Optimistic UI add; generate `Idempotency-Key`.
  - Try SSE: open stream; concurrently `POST /v1/chat/messages`; append chunks on `message_chunk`, finalize on `message_complete`. If SSE unavailable, use sync response and render returned assistant message.
  - Persist to `chat:history:<id>` after each update.
- Reset:
  - `DELETE /v1/chat/sessions/:id`; clear `chat:*` keys; create new session; clear UI history except welcome message.
- Error handling:
  - Toast + retry with same idempotency key on 5xx/429/408; no retry for 4xx except 408; fallback from stream to sync.

### Disease Detection Page
- Enter page:
  - `GET /v1/ai/health`; if not `ready`, call `POST /v1/ai/warmup`; show dialog and poll health every 1–2s until `ready`.
  - Read `detect:sessionId`; create if absent via `POST /v1/detection/sessions`.
- Analyze:
  - Build `FormData` with compressed image; `POST /v1/detection/analyze`.
  - If response `completed`: render result.
  - If `queued`/`processing`: subscribe to stream or poll `GET /v1/detection/jobs/:jobId` every 1s until `completed`.
  - Persist `detect:lastJobId` and final result.
- Results UI:
  - Show `label`, `confidence`; if `boxes` present, draw overlays on preview.
  - “Analyze Again” resets image selector.
- Feedback:
  - Optional button to `POST /v1/detection/feedback`.
- Errors:
  - Validate type/size; show guidance; retry.

## Code Changes (Files)
- `lib/services/chatbot_api.dart` — refactor to new endpoints, auth headers, idempotency, history persistence.
- `lib/services/disease_api.dart` — refactor to new endpoints (health/warmup/session/analyze/jobs/feedback), polling and optional SSE, persistence.
- `lib/services/session_manager.dart` — add helpers for `auth:token`, `chat:*`, `detect:*`, JSON read/write for histories.
- `lib/pages/ai_chatbot_page.dart` — integrate new flow (init/hydrate, send with idempotency, streaming fallback, reset).
- `lib/pages/disease_detection_page.dart` — warmup dialog + health poll, detection session, analyze + poll/stream, overlays, persistence.
- `lib/pages/ai_care_page.dart` — keep GoRouter navigation; no change in this plan unless we add health prompt entry.
- `pubspec.yaml` — add `uuid: ^3.x` for idempotency keys if not present.

## Implementation Notes
- Use `SharedPreferences` for persistence keys; JSON encode history arrays.
- For SSE in Flutter, use fallback polling (no new package unless required). If later needed, we can add an SSE client; initial delivery will rely on sync + polling for reliability.
- Keep existing Firestore persistence of predictions optional; web spec focuses on external API. We will maintain Firestore save after `completed` to match PRD data model.

## Verification
- Chatbot:
  - First open: creates session, hydrates history, sends message with idempotency, handles retry and displays assistant reply; reset clears and recreates.
- Detection:
  - Enter page on cold server: shows warmup, becomes `ready`; analyze returns `queued`, polls to `completed`; shows results and overlays; feedback posts.
- Persistence:
  - Relaunch app and verify `chat:history:<id>` and `detect:lastJobId` rehydrate UI.

## Risks & Mitigations
- SSE unavailability → polling fallback.
- Token absent → block actions with banner and route to auth; 401 triggers re-auth flow in `AuthService`.
- Large uploads → pre-compress with `image_picker` sizing; add size guard (~8MB).

## Next Step
Proceed to implement the service refactors, page logic updates, and persistence helpers as listed above, following existing style and Riverpod patterns.
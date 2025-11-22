## What Will Be Implemented
- Replicate the exact web workflows for Chatbot and Disease Detection in the Flutter app, using the same endpoints, payloads, timing, and storage.

## Chatbot (Web Workflow Replication)
- Session storage: Use `chatbot_session_id` via `SessionManager.getSessionId/saveSessionId/clearSessionId` (`lib/services/session_manager.dart:12–31`).
- API: Keep base `https://mitran-chatbot.onrender.com` and endpoints `GET /health`, `POST /v1/sessions`, `GET /v1/chat/history?session_id=<id>`, `POST /v1/chat/send` (`lib/services/chatbot_api.dart:6–61`).
- Page initialization (AIChatbotPage):
  1. On open, read `chatbot_session_id`. If present, hydrate via `GET /v1/chat/history` and show full chat UI (`lib/pages/ai_chatbot_page.dart:33–52`).
  2. If not present, show a minimal “Create Session” panel (new UI section) with one button.
  3. On “Create Session”, first `GET /health`. If healthy, `POST /v1/sessions`, save `session_id`, then reveal full chat UI.
- Send flow: Optimistically append the user message, call `POST /v1/chat/send`, render assistant reply. Use `_extractReply` for different response shapes (`lib/services/chatbot_api.dart:63–74`).
- Error UX: Inline banner for readiness errors; for send/history 404/429 show actions: “Resend” (retry last send) and “New Session” (clear session and return to create panel).

## Disease Detection (Web Workflow Replication)
- API: Use `GET /health` and `POST /predict` (`lib/services/disease_api.dart:10–39`).
- Page initialization (DiseaseDetectionPage):
  1. On enter, call `GET /health`. If not ready, show “starting up” banner with Retry (`lib/pages/disease_detection_page.dart:87–90, 225–237`).
  2. When ready, image selection enables the Analyze button.
- Analyze flow:
  1. On click, `POST /predict` with multipart `file=@image` (`lib/services/disease_api.dart:19–39`).
  2. Upload the image to Firebase Storage and save prediction in Firestore `predictions` (`lib/pages/disease_detection_page.dart:121–166`).
  3. Render result card with label, confidence, title/description when present (`lib/pages/disease_detection_page.dart:352–386`).
- Error UX: Inline messages for health and analysis errors; no local storage keys used.

## Files To Update
- `lib/pages/ai_chatbot_page.dart`: Add “Create Session” panel for when no saved session; wire button to health check + session creation; add “Resend” and “New Session” actions in the error state.
- `lib/services/session_manager.dart`: Already uses `chatbot_session_id` and has aliases.
- `lib/services/chatbot_api.dart`: Already matches the required endpoints and reply extraction.
- `lib/pages/disease_detection_page.dart`: Ensure health check gates the Analyze button and banner has Retry; confirm upload-and-save flow remains.

## Verification
- Open Chatbot without a saved session: see “Create Session”, click to create, then send a message, receive assistant reply; trigger error paths to verify Retry/New Session.
- Open Disease Detection with service starting: see banner; Retry until ready; pick an image, Analyze, verify Firestore record and result rendering.

## Notes
- Streaming is intentionally not used for the chatbot page per the web workflow.
- Keep the existing PRD models and Firestore persistence intact. 
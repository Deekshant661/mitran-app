## Summary of Findings
- Data models match PRD: `UserModel`, `DogModel`, `PostModel`, `PredictionModel`, `Message`, `QRScanResult`, `DogFilters` all implemented with required fields and helpers.
- External APIs implemented:
  - Chatbot client and health check: `lib/services/chatbot_api.dart:5–64`.
  - Disease detection client, labels, health: `lib/services/disease_api.dart:7–84`.
- Routing matches PRD: `lib/router.dart:15–64`.
- Page logic broadly aligned, with gaps:
  - Chatbot page does not load chat history and has no “reset session” option: `lib/pages/ai_chatbot_page.dart:22–49`, `90–179`, `181–206`.
  - Disease page does not check API health or show supported labels before analysis: `lib/pages/disease_detection_page.dart:24–51`, `86–179`.
  - AI Care page uses `Navigator.pushNamed` instead of `GoRouter`: `lib/pages/ai_care_page.dart:97–110`.

## Fix Plan
### Chatbot Page Compliance
- Load existing conversation history after session creation and render it.
- Add “Reset Session” action: clears stored session (`SessionManager.clearSession`) and creates a fresh session.
- Keep health-check banner and retry as-is.

### Disease Detection Page Compliance
- Perform `/health` check before enabling analysis; show an error banner with retry when unhealthy.
- Fetch and display `/labels` so users know supported classes.
- Keep current upload → analyze → persist flow; ensure analysis disabled until healthy.

### Routing Consistency
- Replace `Navigator.pushNamed` with `context.push('/ai-care/chatbot')` and `context.push('/ai-care/disease-scan')` in `AICarePage` for consistency with `GoRouter`.

## Implementation Steps
### 1) AIChatbotPage
- After acquiring `_sessionId`, call `getHistory(_sessionId!)` and append to `_messages` using `Message.fromJson`.
- Add AppBar overflow menu with “Reset Session”; on select:
  - `ref.read(sessionManagerProvider).clearSession()`
  - Create a new session and set `_sessionId`.
- Ensure welcome message remains when no history exists.

### 2) DiseaseDetectionPage
- On init, call `diseaseDetectionServiceProvider.checkHealth()` and `getLabels()`; store in state.
- Show a top banner when unhealthy with a Retry button.
- Show labels list under instructions.
- Disable Analyze button when not healthy.

### 3) AICarePage Navigation
- Update tool cards to use `context.push` for `/ai-care/chatbot` and `/ai-care/disease-scan`.

## Files To Update
- `lib/pages/ai_chatbot_page.dart`
- `lib/pages/disease_detection_page.dart`
- `lib/pages/ai_care_page.dart`

## Verification
- Run the app; navigate to AI Care → Chatbot:
  - Verify banner shows when `/health` returns non-200.
  - Verify history loads on first render when a prior session exists.
  - Use Reset Session; confirm a new session is created and history cleared.
- Navigate to Disease Detection:
  - Verify labels display.
  - Disable Analyze when unhealthy; Retry restores when healthy.
- Confirm navigation from AI Care works with `GoRouter`.

## Notes
- No backend changes required; uses existing endpoints and providers.
- All edits follow current style and Riverpod patterns.
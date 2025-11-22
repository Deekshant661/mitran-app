## Summary
- Performed a full PRD vs implementation audit across models, pages, providers, and services.
- Identified concrete divergences that can break data consistency or user flows.
- Proposed targeted code changes, keeping your existing architecture and style.

## Critical Data Model Mismatches
- UserModel
  - Extra fields not in PRD: `bio`, `phoneNumber` used throughout
  - Reference: lib/models/user_model.dart:8–9
  - PRD spec: users.contactInfo holds `phone`; no `bio`
  - Impact: Duplicate/undefined fields in Firestore and UI; PRD consumers may miss `bio`
  - Fix: Remove `bio` and `phoneNumber` from the model and UI; rely on `contactInfo.phone` only. Update serializers and all usages.
- DogModel
  - Extra fields not in PRD: `breed`, `status`, `description`, `medicalInfo`
  - Reference: lib/models/dog_model.dart:8–11, 29–33, 76–80
  - PRD spec includes `vaccinationStatus`, `sterilizationStatus`, `readyForAdoption`, `temperament`, `healthNotes` (already present)
  - Impact: Directory/search/UI wired to non‑PRD attributes; risks misaligned Firestore schema
  - Fix: Remove non‑PRD fields, drive UI and forms using PRD booleans and strings only
- PostModel
  - Extra social fields not in PRD: `images`, `likesCount`, `commentsCount`, `isLiked`
  - Reference: lib/models/post_model.dart:9–12, 21–23, 35–37, 47–51
  - PRD MVP excludes comments/likes
  - Fix: Strip social fields from model/UI; keep simple text posts per PRD
- PredictionModel
  - Extra field: `diseaseName`
  - Reference: lib/models/prediction_model.dart:8, 41, 58; lib/services/disease_api.dart:67
  - PRD does not define this; use `label` + metadata only
  - Fix: Remove `diseaseName`; adapt result rendering accordingly

## Screen Flow And UX Deviations
- Add Record flow
  - Current: standalone form with `breed/status/medicalInfo`
  - Reference: lib/pages/add_record_page.dart:22–37, 347–428
  - PRD: QR scan first; if new, open registration form with PRD fields; includes `city`, status checkboxes, temperament dropdown, health notes
  - Fix: Replace AddRecord with QR-first flow; registration form should include PRD fields and prefill QR ID; wire uploads to Firebase Storage
- Directory filters and search
  - UI shows status/breed/location filters that PRD does not specify
  - References: lib/pages/directory_page.dart:66, 82–116, 319–333; lib/models/dog_filters.dart:5–18
  - Logic filters only vaccinated/sterilized/adoption and name/area
  - Fix: Align UI to PRD chips: Vaccinated/Sterilized/Adoption + search by name/area; remove non‑PRD chips and fields
- Dog Detail page
  - Shows non‑PRD fields (`breed/status/medicalInfo`) and social actions
  - Reference: lib/pages/dog_detail_page.dart:170–176, 215–237, 268–275, 122–149
  - Fix: Show PRD info cards only; adoptable contact bottom sheet when `readyForAdoption` is true; remove social actions for MVP
- Home/Feed
  - PostCard includes likes/comments/share/report
  - Reference: lib/widgets/post_card.dart:80–115
  - Fix: Minimal card per PRD: author, content, timestamp only
- Profile page
  - Adds `bio` and `phoneNumber` separate from PRD
  - References: lib/pages/profile_page.dart:22–24, 130–132, 239–241, 392–403
  - Fix: Remove `bio`; keep phone inside `contactInfo`; retain edit fields per PRD: username, phone, city, area, userType
- Disease Detection page
  - Does not upload images to Storage or save predictions
  - Reference: lib/pages/disease_detection_page.dart:82–135
  - Fix: Add Firebase Storage upload and `predictions` write per PRD; single‑image submission is acceptable for MVP
- QR Scanner entry point
  - Separate `QRScannerPage` exists, but Bottom Nav “Add Record” opens form
  - References: lib/widgets/custom_bottom_nav.dart:21–22; lib/pages/qr_scanner_page.dart
  - Fix: Route “Add Record” to scanner; after scan, branch to existing dog summary or new registration

## Non‑Functional And UI Guidelines Gaps
- Text overflow handling
  - PRD requires `overflow: TextOverflow.ellipsis` for all text
  - Many `Text` widgets lack overflow
  - Fix: Audit and add overflow across feed, cards, headers, and lists
- SafeArea and scroll hygiene
  - Some pages not wrapped in `SafeArea` or rely on default
  - Fix: Wrap core pages in `SafeArea`; ensure scrollable layouts use `SingleChildScrollView`/`ListView` consistently

## Services And Providers
- Chatbot
  - Missing health check before session init
  - Reference: lib/pages/ai_chatbot_page.dart
  - Fix: Call `chatbotApi.checkHealth()` and show error banner/retry per PRD before loading session/history
- Disease API convenience
  - Uses `diseaseName` in mapper
  - Reference: lib/services/disease_api.dart:67
  - Fix: Map strictly to PRD fields and return one prediction object per image; save to Firestore

## Exact Fixes To Apply
1) Models
- Update `lib/models/user_model.dart` to remove `bio` and `phoneNumber`; keep `contactInfo.phone` (PRD)
- Update `lib/models/dog_model.dart` to remove `breed/status/description/medicalInfo`; keep PRD fields only
- Update `lib/models/post_model.dart` to remove social fields and images
- Update `lib/models/prediction_model.dart` to remove `diseaseName`

2) Pages And Widgets
- `lib/pages/create_profile_page.dart`: stop setting `bio`/`phoneNumber`; write `contactInfo.phone`; retain PRD fields
- `lib/pages/profile_page.dart`: remove bio UI and update save logic to use `contactInfo` and PRD fields
- `lib/pages/add_record_page.dart`: redesign to PRD fields; add `city`, `vaccinationStatus`, `sterilizationStatus`, `readyForAdoption` checkboxes; `temperament` dropdown; `healthNotes` textarea; prefill QR ID when navigated from scanner
- `lib/pages/qr_scanner_page.dart` + `lib/widgets/qr_scanner_widget.dart`: set Bottom Nav “Add Record” to open scanner; on new QR → navigate to registration form
- `lib/pages/directory_page.dart`: adjust search hint to name/area; show PRD chips (vaccinated/sterilized/adoption); remove non‑PRD chips; hook chips to `filteredDogsProvider`
- `lib/widgets/dog_card.dart` and `lib/pages/dog_detail_page.dart`: remove breed/status/medicalInfo; show PRD basic info, status badges, adoption contact sheet when applicable
- `lib/pages/home_page.dart` + `lib/widgets/post_card.dart`: strip likes/comments/share; keep author, content, timestamp
- `lib/pages/disease_detection_page.dart`: upload to Storage and write to `predictions`; render PRD result sections

3) Providers And Services
- `lib/providers/filters_provider.dart`: ensure filters match PRD (vaccinated/sterilized/adoption) and search name/area
- `lib/services/disease_api.dart`: return PRD fields only; helper returns a single prediction per image; integrate Storage upload in page logic
- `lib/pages/ai_chatbot_page.dart`: add health check + retry banner before session init

4) UI Hygiene
- Add `overflow: TextOverflow.ellipsis` in all visible `Text` rendering per PRD NFR
- Wrap core pages in `SafeArea` where missing

## Validation Plan
- Manual verification by navigating all tabs and flows
- Create a few test Firestore documents to validate schema writes for `users`, `dogs`, `posts`, `predictions`
- Run QR scan end‑to‑end: scan existing → summary; new → registration with QR ID; verify Storage uploads
- Confirm disease detection saves to `predictions` and renders sections per PRD

## Deliverables
- A single refactor PR touching the listed files, keeping imports and coding style
- No changes to external configurations or secrets
- Clear commit messages grouped by model, pages, and providers

Would you like me to proceed implementing these fixes now?
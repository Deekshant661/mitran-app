# Mitran Mobile Application - Product Requirements Document (PRD)

## 1. Executive Summary

**Project Name:** Mitran Mobile Application  
**Version:** 1.0 (MVP)  
**Date:** November 2025  
**Document Owner:** Product Team

### Mission Statement
Create a mobile application for stray dog welfare that extends the Mitran web platform with enhanced mobile-first features, including QR code scanning for dog registration and native mobile capabilities.

### Core Problem
Mobile users need on-the-go access to dog profiles, quick dog registration via QR codes, and mobile-optimized interfaces for field work.

### Solution Overview
The Mitran mobile application provides:
- **Mobile-First Community Hub:** Optimized feed and posting experience
- **QR Code Dog Registration:** Quick field registration of stray dogs
- **Information Directory:** Mobile-optimized searchable dog database
- **AI-Powered Support:** Native mobile interface for chatbot and disease detection
- **Seamless Sync:** Real-time synchronization with web platform data

---

## 2. Target Audience

### Primary User Persona: "Mobile Guardian"

**Description:** A community member, volunteer, or feeder who actively works in the field and needs mobile access to the Mitran platform.

**User Goals:**
- Quickly register new stray dogs using QR codes
- Access dog information while on location
- Post updates from the field
- Get immediate AI assistance for health concerns
- Stay connected with the community on-the-go

**User Characteristics:**
- Age range: 18-65
- Tech comfort: Basic to intermediate
- Motivation: Active field work in animal welfare
- Device usage: Primarily mobile (Android/iOS)
- Context: Outdoor, on-location, time-sensitive situations

---

## 3. Technical Architecture

### 3.1 Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Frontend | Flutter (Mobile) | Native iOS and Android application |
| State Management | Riverpod | Clean, predictable state management |
| Authentication | Firebase Authentication | Google Sign-In |
| Database | Cloud Firestore | Real-time NoSQL database (shared with web) |
| Storage | Firebase Storage | Image uploads (profiles, dogs) |
| AI Backend | Python FastAPI (Render) | Chatbot + disease detection APIs (shared with web) |
| QR Scanner | mobile_scanner | Native QR code scanning |
| Local Storage | shared_preferences | Session persistence and app preferences |
| Image Picker | image_picker | Camera and gallery access |

### 3.2 Flutter Mobile-Specific Dependencies

```yaml
environment:
  sdk: ^3.9.2

dependencies:
  flutter:
    sdk: flutter
  
  # Core Dependencies (shared with web)
  http: ^1.2.0
  http_parser: ^4.0.2
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.0
  cloud_firestore: ^5.4.4
  firebase_storage: ^12.3.1
  google_sign_in: ^6.2.1
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.1
  cached_network_image: ^3.3.1
  intl: ^0.19.0
  
  # Mobile-Specific Dependencies
  mobile_scanner: ^5.2.3              # QR code scanning
  image_picker: ^1.1.2                # Camera and gallery access
  shared_preferences: ^2.3.2          # Local data persistence
  permission_handler: ^11.3.1         # Runtime permissions
  connectivity_plus: ^6.0.5           # Network connectivity status
  path_provider: ^2.1.4               # File system access
  flutter_native_splash: ^2.4.1       # Splash screen
  introduction_screen: ^3.1.14        # Onboarding slider

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

### 3.3 Project Folder Structure

```
lib/
  main.dart
  router.dart
  firebase_options.dart
  
  models/
    user_model.dart
    dog_model.dart
    post_model.dart
    prediction_model.dart
    message_model.dart
    qr_scan_result.dart
    
  services/
    auth_service.dart
    firestore_service.dart
    storage_service.dart
    chatbot_api.dart
    disease_api.dart
    qr_service.dart
    permission_service.dart
    session_manager.dart
    
  providers/
    auth_provider.dart
    user_provider.dart
    posts_provider.dart
    dogs_provider.dart
    filters_provider.dart
    
  pages/
    splash_screen.dart
    onboarding_screen.dart
    create_profile_page.dart
    home_page.dart
    directory_page.dart
    dog_detail_page.dart
    add_record_page.dart
    ai_care_page.dart
    ai_chatbot_page.dart
    ai_disease_scan_page.dart
    profile_page.dart
    
  widgets/
    post_card.dart
    dog_card.dart
    custom_bottom_nav.dart
    qr_scanner_widget.dart
    common UI components
    
  utils/
    validators.dart
    image_helper.dart
    date_formatter.dart
```

### 3.4 Application Flow & Navigation

#### Initial Launch Flow
```
App Start
    ↓
Splash Screen (2-3 seconds)
    ↓
Check Authentication
    ├── Authenticated → Check Profile → Home Page
    └── Not Authenticated → Onboarding Slider
                                ↓
                        "Join Community" Button
                                ↓
                        Google Sign-In Popup
                                ↓
                        Check Profile Existence
                        ├── Exists → Home Page
                        └── New User → Create Profile Page → Home Page
```

#### Main Navigation Structure (Bottom Navigation Bar)

```
Bottom Navigation Bar (5 tabs):
1. Home/Feed        (Icon: Home)        → HomePage
2. Directory        (Icon: List)         → DirectoryPage
3. Add Record       (Icon: QR Code)      → AddRecordPage
4. AI Care          (Icon: Brain/Star)   → AiCarePage
5. Profile          (Icon: Person)       → ProfilePage
```

### 3.5 Routing Map

```dart
/splash                 → SplashScreen
/onboarding             → OnboardingScreen
/create-profile         → CreateProfilePage (authed, first-time)
/home                   → HomePage (authed) - Bottom Nav Tab 1
/directory              → DirectoryPage (authed) - Bottom Nav Tab 2
/directory/:dogId       → DogDetailPage (authed)
/add-record             → AddRecordPage (authed) - Bottom Nav Tab 3
/ai-care                → AiCarePage (authed) - Bottom Nav Tab 4
/ai-care/chatbot        → AiChatbotPage
/ai-care/disease-scan   → AiDiseaseScanPage
/profile                → ProfilePage (authed) - Bottom Nav Tab 5
```

### 3.6 Firebase Data Architecture (Shared with Web)

#### Collection: `users`
```json
{
  "userId": "string (Firebase Auth UID)",
  "email": "string",
  "username": "string (unique)",
  "profilePictureUrl": "string (Firebase Storage URL)",
  "contactInfo": {
    "phone": "string (optional)",
    "email": "string"
  },
  "city": "string",
  "area": "string",
  "userType": "string (Volunteer/Feeder/NGO Member/Citizen)",
  "postIds": ["array of post document IDs"],
  "dogIds": ["array of dog document IDs added by this user"],
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### Collection: `dogs`
```json
{
  "dogId": "string (auto-generated OR QR code ID)",
  "qrCodeId": "string (unique QR code, nullable)",
  "name": "string",
  "photos": ["array of Firebase Storage URLs"],
  "mainPhotoUrl": "string (primary photo)",
  "area": "string",
  "city": "string",
  "vaccinationStatus": "boolean",
  "sterilizationStatus": "boolean",
  "readyForAdoption": "boolean",
  "temperament": "string (Friendly/Shy/Aggressive/Calm, etc.)",
  "healthNotes": "string (optional)",
  "addedBy": {
    "userId": "string (reference to users collection)",
    "username": "string",
    "contactInfo": {
      "phone": "string",
      "email": "string"
    }
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### Collection: `posts`
```json
{
  "postId": "string (auto-generated)",
  "content": "string (text content)",
  "author": {
    "userId": "string",
    "username": "string",
    "profilePictureUrl": "string"
  },
  "timestamp": "timestamp",
  "createdAt": "timestamp"
}
```

#### Collection: `predictions`
```json
{
  "imageUrl": "string (Firebase Storage URL)",
  "label": "string",
  "confidence": "number (0-100)",
  "title": "string",
  "description": "string",
  "symptoms": ["string"],
  "treatments": ["string"],
  "homecare": ["string"],
  "note": "string",
  "userId": "string",
  "timestamp": "timestamp"
}
```

### 3.7 External API Integration

**Note:** Mobile applications do NOT require CORS handling.

#### 1. Chatbot API
- **Base URL:** `https://mitran-chatbot.onrender.com`
- **Endpoints:**
  - `POST /v1/sessions` → `{"session_id": "uuid"}`
  - `GET /v1/chat/history?session_id=<id>` → Fetch history
  - `POST /v1/chat/send` → Send message and receive reply
  - `GET /v1/chat/stream?session_id=<id>&text=<message>` → SSE streaming (optional)
  - `GET /health` → Health check

**Mobile Implementation:**
- Session ID stored in `shared_preferences`
- Restore session on app launch

#### 2. Disease Detection API
- **Base URL:** `https://mitran-disease-detection.onrender.com`
- **Endpoints:**
  - `GET /health` → Health check
  - `GET /labels` → Supported disease labels
  - `POST /predict` → Upload image for prediction

**Mobile Implementation:**
- Use `image_picker` to capture/select images
- Native image compression available

---

## 4. Feature Specifications

### 4.1 Screen: Splash Screen

**Purpose:** Display app branding while initializing Firebase and checking authentication state.

**Components:**
1. Mitran logo (centered)
2. App tagline
3. Loading indicator (subtle)

**Navigation Logic:**
```dart
// Splash screen (2-3 seconds)
await Future.delayed(Duration(seconds: 2));

// Check authentication
final user = FirebaseAuth.instance.currentUser;

if (user != null) {
  // Check if profile exists
  final hasProfile = await checkUserProfile(user.uid);
  
  if (hasProfile) {
    navigate('/home');
  } else {
    navigate('/create-profile');
  }
} else {
  // First time user - show onboarding
  final hasSeenOnboarding = await getOnboardingStatus();
  
  if (hasSeenOnboarding) {
    navigate('/home');
  } else {
    navigate('/onboarding');
  }
}
```

**Acceptance Criteria:**
- [ ] Splash screen displays for 2-3 seconds
- [ ] Firebase initializes successfully
- [ ] Authentication state checked correctly
- [ ] Proper navigation based on auth state

---

### 4.2 Screen: Onboarding Slider

**Purpose:** Introduce first-time users to the app's features and mission.

**Components:**

**Introduction Screens (2-3 slides):**
- **Slide 1: Welcome**
  - Title: "Welcome to Mitran"
  - Description: Brief mission statement
  - Image: Community/dog welfare illustration

- **Slide 2: Features**
  - Title: "Connect & Care"
  - Description: Overview of community features
  - Image: App features illustration

- **Slide 3: Get Started**
  - Title: "Join the Community"
  - Description: Call to action
  - Button: "Join the Community"

**Navigation Controls:**
- Dot indicators for current slide
- Skip button (top-right)
- Next/Previous swipe gestures
- Final slide shows primary CTA button

**Business Logic:**
```dart
// Save onboarding completion status
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('has_seen_onboarding', true);
```

**Acceptance Criteria:**
- [ ] Slides are swipeable with smooth animations
- [ ] Skip button works from any slide
- [ ] "Join the Community" button triggers authentication
- [ ] Onboarding only shown once per installation
- [ ] Back button exits app

---

### 4.3 Screen: Create Guardian Profile

**Purpose:** Onboard new users and collect necessary profile information.

**Components:**

1. **Profile Picture Section**
   - Circular avatar placeholder
   - Camera button overlay
   - Options: Take Photo / Choose from Gallery
   - Preview selected image

2. **Profile Information Form**
   - Public Username (text input, unique validation)
   - Contact Phone (optional, text input with formatter)
   - City (dropdown or text input)
   - Area (text input)
   - User Type (dropdown: Volunteer, Feeder, NGO Member, Citizen, Other)

3. **Form Actions**
   - "Save and Enter Mitran" button (bottom)
   - Loading indicator during submission

**Mobile-Specific Features:**
- Native image picker with camera access
- Phone number formatter
- Keyboard type optimization
- Form auto-scroll on keyboard appearance

**Business Logic:**
1. Request camera and storage permissions
2. Validate all required fields
3. Check username uniqueness in Firestore
4. Compress and upload profile picture to Firebase Storage
5. Create user document in `users` collection
6. Navigate to home page

**Permission Handling:**
```dart
// Request camera permission
final cameraStatus = await Permission.camera.request();
if (!cameraStatus.isGranted) {
  // Show explanation and settings redirect
}

// Request storage permission (Android < 13)
final storageStatus = await Permission.storage.request();
```

**Acceptance Criteria:**
- [ ] Camera and gallery access work correctly
- [ ] Image preview shows before upload
- [ ] All required fields validated
- [ ] Username uniqueness checked in real-time
- [ ] Profile picture compressed before upload
- [ ] Form scrolls properly with keyboard
- [ ] Success navigation to home page

---

### 4.4 Screen: Home Page (Community Feed)

**Bottom Nav Position:** Tab 1 (Home icon)

**Purpose:** Main dashboard showing community posts with ability to create new posts.

**Components:**

1. **App Bar**
   - Title: "Mitran Hub"
   - No back button (root screen)

2. **Create Post Section** (top of feed)
   - User's profile picture (circular)
   - Text input hint: "Share an update..."
   - Character counter (500 max)
   - Post button (enabled when content exists)

3. **Posts Feed**
   - Pull-to-refresh functionality
   - Real-time updates
   - Infinite scroll / pagination
   - Empty state: "No posts yet. Be the first to share!"

4. **Post Card Component** (repeatable)
   - Author profile picture
   - Author username
   - Post content (text)
   - Timestamp (relative: "2h ago")

**Mobile-Specific Features:**
- Pull-to-refresh gesture
- Smooth scroll performance
- Optimized image loading with `CachedNetworkImage`
- Keyboard-aware scrolling

**Business Logic:**

**Create Post:**
```dart
// Validate content
if (content.trim().isEmpty || content.length > 500) {
  return;
}

// Create post object
final post = PostModel(
  postId: '',
  content: content.trim(),
  author: PostAuthor(
    userId: currentUser.uid,
    username: currentUser.username,
    profilePictureUrl: currentUser.profilePictureUrl,
  ),
  timestamp: DateTime.now(),
  createdAt: DateTime.now(),
);

// Save to Firestore
await firestoreService.createPost(post, currentUser.uid);
```

**Load Feed:**
```dart
// Stream posts from Firestore
return FirebaseFirestore.instance
  .collection('posts')
  .orderBy('timestamp', descending: true)
  .limit(20)
  .snapshots()
  .map((snapshot) => 
    snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList()
  );
```

**Acceptance Criteria:**
- [ ] Pull-to-refresh updates feed
- [ ] Create post submits successfully
- [ ] Character counter updates in real-time
- [ ] New posts appear immediately
- [ ] Smooth scrolling with large lists
- [ ] Images load efficiently
- [ ] Empty state displays correctly

---

### 4.5 Screen: Directory Page

**Bottom Nav Position:** Tab 2 (List icon)

**Purpose:** Searchable, filterable gallery of all registered dogs.

**Components:**

1. **App Bar**
   - Title: "Mitran Directory"
   - Search icon (opens search bar)

2. **Search Bar** (collapsible)
   - Search input: "Search by name or area..."
   - Close button
   - Real-time filtering

3. **Filter Chips** (horizontal scroll)
   - Chip: "Vaccinated" (toggle)
   - Chip: "Sterilized" (toggle)
   - Chip: "Available for Adoption" (toggle)
   - Clear filters button (when filters active)

4. **Dog Cards Grid**
   - 2-column grid layout
   - Each card shows:
     - Dog's main photo
     - Dog's name (bold)
     - Area (with location icon)
     - Status badges

**Business Logic:**

**Search & Filter:**
```dart
List<DogModel> filterDogs(
  List<DogModel> dogs,
  String searchTerm,
  DogFilters filters,
) {
  return dogs.where((dog) {
    // Search filter
    if (searchTerm.isNotEmpty) {
      final matchesName = dog.name
        .toLowerCase()
        .contains(searchTerm.toLowerCase());
      final matchesArea = dog.area
        .toLowerCase()
        .contains(searchTerm.toLowerCase());
      
      if (!matchesName && !matchesArea) return false;
    }
    
    // Status filters
    if (filters.vaccinated && !dog.vaccinationStatus) return false;
    if (filters.sterilized && !dog.sterilizationStatus) return false;
    if (filters.readyForAdoption && !dog.readyForAdoption) return false;
    
    return true;
  }).toList();
}
```

**Acceptance Criteria:**
- [ ] Search filters results in real-time
- [ ] Filter chips toggle correctly
- [ ] Multiple filters work together
- [ ] Grid layout responsive
- [ ] Images load efficiently
- [ ] Card tap navigates to dog detail
- [ ] Clear filters button resets all

---

### 4.6 Screen: Dog Detail Page

**Navigation:** Accessed from Directory Page

**Purpose:** Display comprehensive information for a specific dog.

**Components:**

1. **App Bar**
   - Back button
   - Dog's name as title

2. **Photo Gallery**
   - Full-width image viewer
   - Swipeable photo carousel
   - Page indicators
   - Pinch-to-zoom functionality

3. **Information Section**
   - **Basic Info Card**
     - Area with location icon
     - City
     - Temperament with icon
   
   - **Status Card**
     - Vaccination Status badge
     - Sterilization Status badge
     - Adoption Status badge (if applicable)
   
   - **Health Notes Card** (if available)
     - Health notes text
     - Added date
   
   - **Added By Card**
     - Profile picture
     - Username
     - "Added on [date]"

4. **Adoption Section** (conditional)
   - Only shown if `readyForAdoption === true`
   - "Interested in Adopting?" button
   - Bottom sheet with contact information:
     - Contact person name
     - Email (with copy/call action)
     - Phone (with copy/call action)

**Mobile-Specific Features:**
- Swipeable photo gallery
- Pinch-to-zoom on images
- Call/SMS actions for contact info
- Bottom sheet for contact details

**Business Logic:**

**Load Dog Data:**
```dart
Future<DogModel> loadDogDetails(String dogId) async {
  final doc = await FirebaseFirestore.instance
    .collection('dogs')
    .doc(dogId)
    .get();
  
  if (!doc.exists) {
    throw Exception('Dog not found');
  }
  
  return DogModel.fromFirestore(doc);
}
```

**Contact Actions:**
```dart
// Call phone number
void callPhone(String phoneNumber) async {
  final uri = Uri(scheme: 'tel', path: phoneNumber);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

// Send email
void sendEmail(String email) async {
  final uri = Uri(scheme: 'mailto', path: email);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}
```

**Acceptance Criteria:**
- [ ] Dog data loads correctly
- [ ] Photo gallery swipes smoothly
- [ ] All information displays correctly
- [ ] Adoption section only appears for adoptable dogs
- [ ] Contact bottom sheet displays correctly
- [ ] Call/SMS/Email actions work

---

### 4.7 Screen: Add Record Page (QR Scanner)

**Bottom Nav Position:** Tab 3 (QR Code icon - center, prominent)

**Purpose:** Scan QR codes on dog collars and create/update dog profiles.

**Components:**

1. **QR Scanner View** (full-screen camera)
   - Live camera feed
   - Scanning frame overlay (centered)
   - Instruction text: "Align QR code within frame"
   - Flash toggle button (top-right)
   - Gallery button (select QR from photos)
   - Close button (top-left)

2. **Post-Scan Actions**
   - **If QR Code Exists:**
     - Show dog summary card
     - "View Profile" button
     - "Update Information" button
   
   - **If QR Code is New:**
     - Automatically open registration form with QR ID pre-filled

3. **Dog Registration Form**
   - QR Code ID (read-only, auto-filled)
   - Dog Name (text input)
   - Photos (multi-image picker)
     - "Take Photo" button
     - "Choose from Gallery" button
     - Photo preview grid (with remove option)
     - Select main photo (tap to mark)
   - Area (text input)
   - City (text input or dropdown)
   - Vaccination Status (checkbox)
   - Sterilization Status (checkbox)
   - Ready for Adoption (checkbox)
   - Temperament (dropdown: Friendly, Shy, Aggressive, Calm, Other)
   - Health Notes (text area, optional)
   - "Save Dog Profile" button

**Mobile-Specific Features:**
- Native camera access with QR detection
- Flash control for low-light scanning
- Gallery picker for QR images
- Multi-image selection
- Image preview and management

**Permission Requirements:**
- Camera permission (required)
- Storage permission (for gallery access)

**Business Logic:**

**QR Scanning:**
```dart
// On QR code detected
void onDetect(BarcodeCapture capture) async {
  final String? qrCode = capture.barcodes.first.rawValue;
  
  if (qrCode == null) return;
  
  // Vibrate on successful scan
  HapticFeedback.mediumImpact();
  
  // Check if dog exists with this QR code
  final existingDog = await checkDogByQRCode(qrCode);
  
  if (existingDog != null) {
    showDogSummaryDialog(existingDog);
  } else {
    navigateToRegistrationForm(qrCode);
  }
}

// Check if QR code exists
Future<DogModel?> checkDogByQRCode(String qrCodeId) async {
  final query = await FirebaseFirestore.instance
    .collection('dogs')
    .where('qrCodeId', isEqualTo: qrCodeId)
    .limit(1)
    .get();
  
  if (query.docs.isEmpty) return null;
  
  return DogModel.fromFirestore(query.docs.first);
}
```

**Dog Registration:**
```dart
Future<void> registerDog(DogModel dog) async {
  // Validate required fields
  if (dog.name.isEmpty || dog.photos.isEmpty) {
    showError('Please provide dog name and at least one photo');
    return;
  }
  
  // Upload photos to Firebase Storage
  final List<String> photoUrls = [];
  for (int i = 0; i < dog.photos.length; i++) {
    final url = await uploadDogPhoto(
      File(dog.photos[i]),
      dog.qrCodeId ?? dog.dogId,
      i,
    );
    photoUrls.add(url);
  }
  
  // Create dog document
  final dogData = dog.copyWith(
    photos: photoUrls,
    mainPhotoUrl: photoUrls.first,
    addedBy: DogAddedBy(
      userId: currentUser.uid,
      username: currentUser.username,
      contactInfo: currentUser.contactInfo,
    ),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  // Save to Firestore
  await firestoreService.createDogRecord(dogData, currentUser.uid);
  
  showSuccessSnackBar('Dog profile created successfully!');
  navigateToTab(1); // Directory tab
}
```

**Acceptance Criteria:**
- [ ] Camera permission requested correctly
- [ ] QR scanner detects codes accurately
- [ ] Flash toggle works correctly
- [ ] Existing dog detection works
- [ ] Registration form opens for new QR codes
- [ ] Multi-image picker works
- [ ] Photo preview and removal works
- [ ] Main photo selection works
- [ ] Dog profile saves successfully
- [ ] Photos upload to Firebase Storage

---

### 4.8 Screen: AI Care Page

**Bottom Nav Position:** Tab 4 (Brain/Star icon)

**Purpose:** Hub for AI-powered features: Chatbot and Disease Detection.

**Components:**

1. **App Bar**
   - Title: "Mitran AI Care"
   - Info icon (explains AI features)

2. **Feature Cards**
   - **AI Chatbot Card**
     - Icon: Chat bubble
     - Title: "Ask AI Assistant"
     - Description: "Get instant answers about dog care and health"
     - Tap → Navigate to AI Chatbot Page
   
   - **Disease Detection Card**
     - Icon: Medical scan
     - Title: "Disease Scanner"
     - Description: "Analyze symptoms from photos"
     - Tap → Navigate to Disease Detection Page

**Acceptance Criteria:**
- [ ] Both feature cards display correctly
- [ ] Cards navigate to correct pages
- [ ] Info dialog explains features clearly

---

### 4.9 Screen: AI Chatbot Page

**Navigation:** From AI Care Page

**Purpose:** Interactive chatbot for dog care questions and advice.

**Components:**

1. **App Bar**
   - Back button
   - Title: "AI Assistant"
   - Menu (options: Clear Chat, New Session)

2. **Chat Interface**
   - Message list (scrollable)
   - User messages (right-aligned, blue bubble)
   - AI messages (left-aligned, grey bubble)
   - Timestamps
   - Loading indicator during AI response
   - Empty state: Welcome message with suggested questions

3. **Input Section** (bottom)
   - Text input field: "Ask me anything..."
   - Send button (icon)

**Mobile-Specific Features:**
- Keyboard-aware scrolling
- Auto-scroll to latest message
- Copy message on long-press
- Pull-to-refresh to reload history

**Session Management:**
```dart
class SessionManager {
  static const String _sessionKey = 'chatbot_session_id';
  
  // Get or create session
  Future<String> getOrCreateSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString(_sessionKey);
    
    if (sessionId == null) {
      // Create new session
      final response = await chatbotApi.createSession();
      sessionId = response['session_id'];
      await prefs.setString(_sessionKey, sessionId);
    }
    
    return sessionId;
  }
  
  // Clear session
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
```

**Business Logic:**

**Initialize Chat:**
```dart
Future<void> _initializeChat() async {
  try {
    // Check API health
    final isHealthy = await chatbotApi.checkHealth();
    if (!isHealthy) {
      setState(() => _showError = true);
      return;
    }
    
    // Get or create session
    final sessionId = await sessionManager.getOrCreateSession();
    
    // Load chat history
    final history = await sessionManager.getHistory(sessionId);
    setState(() {
      _messages = history;
      _sessionId = sessionId;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _showError = true;
      _isLoading = false;
    });
  }
}
```

**Send Message:**
```dart
Future<void> sendMessage(String text) async {
  if (text.trim().isEmpty) return;
  
  // Add user message to UI
  final userMessage = Message(
    role: 'user',
    text: text.trim(),
    timestamp: DateTime.now(),
  );
  
  setState(() {
    _messages.add(userMessage);
    _isWaitingForResponse = true;
  });
  
  try {
    // Send to API
    final response = await chatbotApi.sendMessage(_sessionId, text.trim());
    
    // Add AI response to UI
    final aiMessage = Message(
      role: 'assistant',
      text: response['text'] ?? response['content'],
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(aiMessage);
      _isWaitingForResponse = false;
    });
    
  } catch (e) {
    setState(() => _isWaitingForResponse = false);
    showErrorSnackBar('Failed to send message. Please try again.');
  }
}
```

**Error Handling:**
```dart
// Health check failure
if (!isHealthy) {
  return ErrorBanner(
    message: 'AI Assistant is currently unavailable',
    action: TextButton(
      onPressed: () => _initializeChat(),
      child: Text('Retry'),
    ),
  );
}

// Session not found (404)
if (error.statusCode == 404) {
  await sessionManager.clearSession();
  await _initializeChat();
  return;
}

// Rate limit (429)
if (error.statusCode == 429) {
  showErrorSnackBar('Too many requests. Please wait a moment.');
  return;
}
```

**Acceptance Criteria:**
- [ ] Health check passes before initialization
- [ ] Session persists across app restarts
- [ ] Chat history loads correctly
- [ ] Messages send successfully
- [ ] AI responses display correctly
- [ ] Keyboard scrolling works properly
- [ ] Auto-scroll to latest message
- [ ] Error banner shows on API failure
- [ ] Retry functionality works
- [ ] Clear chat removes messages and session

---

### 4.10 Screen: Disease Detection Page

**Navigation:** From AI Care Page

**Purpose:** Analyze dog photos to detect potential diseases.

**Components:**

1. **App Bar**
   - Back button
   - Title: "Disease Scanner"
   - Info icon (explains feature limitations)

2. **Image Selection Section**
   - Large upload area (dashed border)
   - Icon: Camera/Image
   - Text: "Take or select a photo"
   - Buttons:
     - "Take Photo" (camera icon)
     - "Choose from Gallery" (gallery icon)
   - Selected image preview (if image chosen)
     - Remove button (X icon)

3. **API Status Banner** (conditional)
   - Shows when API is initializing
   - "AI model is warming up. Please wait..."
   - Progress indicator

4. **Analysis Section**
   - "Analyze Image" button (prominent)
   - Loading indicator during analysis
   - Disabled when no image selected

5. **Results Card** (after analysis)
   - Disease label (large, bold)
   - Confidence percentage (with color indicator)
   - Disease title
   - Expandable sections:
     - Description
     - Symptoms (bulleted list)
     - Treatments (bulleted list)
     - Home Care (bulleted list)
   - Disclaimer banner:
     - "This is AI-generated advice. Please consult a veterinarian for accurate diagnosis."

**Mobile-Specific Features:**
- Native camera integration
- Image compression before upload
- Photo preview with zoom
- Expandable/collapsible result sections

**Permission Requirements:**
- Camera permission
- Storage/Photo library permission

**Business Logic:**

**Image Selection:**
```dart
// Take photo with camera
Future<void> takePhoto() async {
  final status = await Permission.camera.request();
  if (!status.isGranted) {
    showPermissionDeniedDialog('Camera');
    return;
  }
  
  final XFile? image = await ImagePicker().pickImage(
    source: ImageSource.camera,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );
  
  if (image != null) {
    setState(() => _selectedImage = File(image.path));
  }
}

// Choose from gallery
Future<void> chooseFromGallery() async {
  if (Platform.isAndroid) {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      showPermissionDeniedDialog('Storage');
      return;
    }
  }
  
  final XFile? image = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );
  
  if (image != null) {
    setState(() => _selectedImage = File(image.path));
  }
}
```

**Analyze Image:**
```dart
Future<void> analyzeImage() async {
  if (_selectedImage == null) return;
  
  setState(() => _isAnalyzing = true);
  
  try {
    // Check API health
    final isHealthy = await diseaseApi.checkHealth();
    if (!isHealthy) {
      throw Exception('API not ready');
    }
    
    // Validate file type (PNG/JPEG only)
    final extension = _selectedImage!.path.split('.').last.toLowerCase();
    if (!['png', 'jpg', 'jpeg'].contains(extension)) {
      throw Exception('Unsupported file type. Please use PNG or JPEG.');
    }
    
    // Upload image to Firebase Storage
    final imageUrl = await uploadImageToStorage(_selectedImage!);
    
    // Call prediction API
    final prediction = await diseaseApi.predict(_selectedImage!);
    
    // Save prediction to Firestore
    await savePredictionToFirestore(
      imageUrl: imageUrl,
      prediction: prediction,
    );
    
    // Show results
    setState(() {
      _predictionResult = prediction;
      _isAnalyzing = false;
    });
    
  } catch (e) {
    setState(() => _isAnalyzing = false);
    
    if (e.toString().contains('Unsupported file type')) {
      showErrorDialog('Invalid File', e.toString());
    } else if (e.toString().contains('Model not ready')) {
      showErrorDialog('AI Model Initializing', 
        'The AI model is warming up. Please wait a moment and try again.');
    } else {
      showErrorDialog('Analysis Failed', 
        'Unable to analyze image. Please try again.');
    }
  }
}

// Upload to Firebase Storage
Future<String> uploadImageToStorage(File image) async {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final ref = FirebaseStorage.instance
    .ref()
    .child('disease_scans/${currentUser.uid}/$timestamp.jpg');
  
  await ref.putFile(image);
  return await ref.getDownloadURL();
}

// Save prediction to Firestore
Future<void> savePredictionToFirestore({
  required String imageUrl,
  required Map<String, dynamic> prediction,
}) async {
  await FirebaseFirestore.instance.collection('predictions').add({
    'imageUrl': imageUrl,
    'label': prediction['label'],
    'confidence': prediction['confidence'],
    'title': prediction['title'],
    'description': prediction['description'],
    'symptoms': prediction['symptoms'],
    'treatments': prediction['treatments'],
    'homecare': prediction['homecare'],
    'note': prediction['note'],
    'userId': currentUser.uid,
    'timestamp': FieldValue.serverTimestamp(),
  });
}
```

**Error Handling:**
```dart
// File type validation
if (!['png', 'jpg', 'jpeg'].contains(extension)) {
  showErrorDialog(
    'Unsupported File Type',
    'Please select a PNG or JPEG image.',
  );
  return;
}

// API not ready (503)
if (error.statusCode == 503) {
  showErrorBanner(
    'AI model is initializing. Please wait and try again.',
    action: 'Retry',
  );
  return;
}
```

**Acceptance Criteria:**
- [ ] Camera and gallery permissions work
- [ ] Image selection works from both sources
- [ ] Image preview displays correctly
- [ ] File type validation works (PNG/JPEG only)
- [ ] Image compression before upload
- [ ] API health check before analysis
- [ ] Upload to Firebase Storage succeeds
- [ ] Prediction API returns results
- [ ] Results display correctly with all sections
- [ ] Disclaimer banner is prominent
- [ ] Results saved to Firestore
- [ ] Error handling for all failure scenarios

---

### 4.11 Screen: Profile Page

**Bottom Nav Position:** Tab 5 (Person icon)

**Purpose:** Display and edit user profile information, view activity, and logout.

**Components:**

1. **App Bar**
   - Title: "My Profile"
   - Edit button (pencil icon) → Toggle edit mode

2. **Profile Header**
   - Profile picture (large, circular)
   - Camera icon overlay (in edit mode)
   - Username (large text)
   - Email (smaller text)
   - User type badge

3. **Profile Information Section**
   - In View Mode: Display fields in cards
   - In Edit Mode: Editable text fields
   - Fields:
     - Username (editable, unique validation)
     - Phone (editable, formatted)
     - City (editable)
     - Area (editable)
     - User Type (editable dropdown)

4. **Activity Tabs**
   - Tab 1: "My Posts" (count badge)
     - List of user's posts
     - Empty state: "You haven't posted anything yet"
   
   - Tab 2: "Dogs I've Added" (count badge)
     - Grid of dog cards
     - Empty state: "You haven't added any dogs yet"

5. **Actions Section**
   - "Logout" button (red, destructive)

**Mobile-Specific Features:**
- Image picker for profile picture
- Smooth edit mode transitions
- Keyboard-aware form scrolling
- Pull-to-refresh activity
- Swipeable tabs

**Business Logic:**

**Load Profile:**
```dart
Future<void> _loadProfile() async {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  
  // Listen to user profile
  FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .snapshots()
    .listen((doc) {
      if (doc.exists) {
        setState(() => _user = UserModel.fromFirestore(doc));
      }
    });
  
  // Load user's posts
  _loadUserPosts(userId);
  
  // Load user's dogs
  _loadUserDogs(userId);
}
```

**Update Profile:**
```dart
Future<void> updateProfile() async {
  // Validate fields
  if (_usernameController.text.trim().isEmpty) {
    showError('Username cannot be empty');
    return;
  }
  
  // Check username uniqueness (if changed)
  if (_usernameController.text != _user.username) {
    final isAvailable = await firestoreService.isUsernameAvailable(
      _usernameController.text.trim(),
    );
    
    if (!isAvailable) {
      showError('Username is already taken');
      return;
    }
  }
  
  setState(() => _isSaving = true);
  
  try {
    String? newImageUrl;
    
    // Upload new profile picture if changed
    if (_newProfileImage != null) {
      newImageUrl = await storageService.uploadProfilePicture(
        _newProfileImage!,
        _user.userId,
      );
    }
    
    // Update user document
    final updates = {
      'username': _usernameController.text.trim(),
      'contactInfo': {
        'phone': _phoneController.text.trim(),
        'email': _user.email,
      },
      'city': _cityController.text.trim(),
      'area': _areaController.text.trim(),
      'userType': _selectedUserType,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (newImageUrl != null) {
      updates['profilePictureUrl'] = newImageUrl;
    }
    
    await firestoreService.updateUserProfile(_user.userId, updates);
    
    showSuccessSnackBar('Profile updated successfully');
    
    setState(() {
      _isEditMode = false;
      _isSaving = false;
      _newProfileImage = null;
    });
    
  } catch (e) {
    setState(() => _isSaving = false);
    showErrorSnackBar('Failed to update profile');
  }
}
```

**Change Profile Picture:**
```dart
Future<void> changeProfilePicture() async {
  showModalBottomSheet(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(Icons.camera_alt),
          title: Text('Take Photo'),
          onTap: () async {
            Navigator.pop(context);
            await _pickImage(ImageSource.camera);
          },
        ),
        ListTile(
          leading: Icon(Icons.photo_library),
          title: Text('Choose from Gallery'),
          onTap: () async {
            Navigator.pop(context);
            await _pickImage(ImageSource.gallery);
          },
        ),
        if (_user.profilePictureUrl.isNotEmpty)
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Remove Photo', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _newProfileImage = null);
            },
          ),
      ],
    ),
  );
}
```

**Logout:**
```dart
Future<void> logout() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Logout'),
      content: Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Logout', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  
  if (confirmed != true) return;
  
  try {
    // Clear local data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    
    // Navigate to onboarding
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => OnboardingScreen()),
      (route) => false,
    );
    
  } catch (e) {
    showErrorSnackBar('Failed to logout. Please try again.');
  }
}
```

**Acceptance Criteria:**
- [ ] Profile data loads correctly
- [ ] Edit mode toggle works smoothly
- [ ] All fields editable in edit mode
- [ ] Username uniqueness checked in real-time
- [ ] Profile picture change options work
- [ ] Image preview shows before save
- [ ] Save changes updates Firestore
- [ ] Cancel discards unsaved changes
- [ ] Activity tabs show correct data
- [ ] Logout confirmation dialog shows
- [ ] Logout clears session and redirects

---

## 5. Non-Functional Requirements

### 5.1 Performance

- **App Launch Time:** Cold start under 3 seconds, warm start under 1 second
- **Screen Transitions:** Smooth 60fps animations
- **Image Loading:** Progressive loading with placeholders, cached images
- **Database Queries:** Optimized with proper Firestore indexing
- **QR Scanning:** Real-time detection with < 500ms response time
- **API Calls:** Timeout after 30 seconds with retry logic

### 5.2 Security

- **Authentication:** Firebase Authentication with Google Sign-In
- **Authorization:** Users can only edit their own profiles and records
- **Data Validation:** Client-side and Firestore security rules validation
- **Image Upload:** File type and size validation before upload
- **API Security:** No API keys stored in app (Firebase handles auth)

**Firestore Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isOwner(userId);
    }
    
    match /posts/{postId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && 
                               isOwner(resource.data.author.userId);
    }
    
    match /dogs/{dogId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && 
                               isOwner(resource.data.addedBy.userId);
    }
    
    match /predictions/{predictionId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow delete: if isAuthenticated() && isOwner(resource.data.userId);
    }
  }
}
```

### 5.3 Accessibility

- **Screen Reader Support:** All images have semantic labels
- **Touch Targets:** Minimum 48x48dp for all interactive elements
- **Color Contrast:** WCAG 2.1 AA compliance (4.5:1 for text)
- **Text Scaling:** Support for system text size settings

### 5.4 Responsive Design

- **Screen Sizes:** Support from 4.7" to 12.9" displays
- **Orientations:** Portrait primary, landscape supported where appropriate
- **Safe Areas:** Respect notches, home indicators, and system UI
- **Flexible Layouts:** Use Flex, Expanded, and MediaQuery

### 5.5 Flutter Mobile UI Guidelines

**CRITICAL: Preventing Overflow Errors**
- All text widgets MUST use `overflow: TextOverflow.ellipsis`
- All scrollable content MUST be wrapped in `SingleChildScrollView` or `ListView`
- All images MUST use `fit: BoxFit.cover` or `fit: BoxFit.contain`
- Column/Row widgets MUST use `Expanded` or `Flexible` where needed
- Always use `SafeArea` widget to avoid notch/system UI overlaps

**UI Design Principles**
- Material Design 3 theming
- Consistent spacing: 8dp, 16dp, 24dp, 32dp
- Elevation for cards: 1-4dp max
- Border radius: 8dp for cards, 24dp for buttons
- Loading indicators: CircularProgressIndicator
- Error states: SnackBars and AlertDialogs

### 5.6 Platform Support

- **Android:** API 21 (Lollipop) and above
- **iOS:** iOS 12.0 and above

### 5.7 Offline Capability

- **Firebase Offline Persistence:** Enable Firestore offline caching
- **Image Caching:** Cache images locally using `cached_network_image`
- **Graceful Degradation:** Show cached data when offline
- **Sync on Reconnect:** Automatically sync changes when connection restored

```dart
// Enable Firestore offline persistence
await FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

---

## 6. User Stories

### Epic 1: User Onboarding & Authentication

**US-1.1:** As a new user, I want to see an engaging introduction to the app so that I understand its purpose and features.

**US-1.2:** As a new user, I want to sign up with my Google account so that I can quickly create an account.

**US-1.3:** As a new user, I want to create my Guardian profile with my photo and details so that the community knows who I am.

**US-1.4:** As a returning user, I want the app to remember me so that I don't have to sign in every time.

### Epic 2: Community Engagement

**US-2.1:** As a Guardian, I want to post updates from my mobile device so that I can share information while in the field.

**US-2.2:** As a Guardian, I want to see a feed of community posts so that I stay informed about activities.

**US-2.3:** As a Guardian, I want to refresh the feed by pulling down so that I can see the latest updates.

**US-2.4:** As a Guardian, I want to view my posting history so that I can track my contributions.

### Epic 3: Dog Directory & Search

**US-3.1:** As a Guardian, I want to search for dogs by name or area on my mobile so that I can quickly find specific dogs.

**US-3.2:** As a Guardian, I want to filter dogs by health status so that I can find dogs needing specific care.

**US-3.3:** As a Guardian, I want to view detailed dog profiles on my mobile so that I can access information while on location.

**US-3.4:** As a potential adopter, I want to call or message the contact person directly from the app so that I can inquire easily.

### Epic 4: QR Code Dog Registration

**US-4.1:** As a field volunteer, I want to scan QR codes on dog collars so that I can quickly access their profiles.

**US-4.2:** As a field volunteer, I want to register new dogs by scanning their collar QR codes so that I can add them efficiently.

**US-4.3:** As a field volunteer, I want to take multiple photos of dogs during registration so that I can document their appearance.

**US-4.4:** As a field volunteer, I want to update existing dog information after scanning their QR code so that I can keep records current.

**US-4.5:** As a volunteer, I want to use my phone's flash while scanning QR codes in low light so that I can register dogs anytime.

### Epic 5: AI-Powered Features

**US-5.1:** As a Guardian, I want to ask the AI chatbot questions about dog care from my mobile so that I can get quick answers.

**US-5.2:** As a Guardian, I want to take a photo of a dog's symptoms and get AI analysis so that I can identify potential health issues.

**US-5.3:** As a Guardian, I want clear disclaimers on AI advice so that I know when to consult a veterinarian.

### Epic 6: Profile Management

**US-6.1:** As a Guardian, I want to edit my profile on mobile so that I can update my information anytime.

**US-6.2:** As a Guardian, I want to change my profile picture using my phone's camera so that I can keep my profile current.

**US-6.3:** As a Guardian, I want to see all dogs I've registered so that I can track my field work.

**US-6.4:** As a Guardian, I want to logout securely so that my account is protected.

---

## 7. Out of Scope (MVP)

The following features are **explicitly excluded** from the mobile app MVP:

1. **Comment/Reply on Posts:** Social interactions beyond posting are deferred
2. **Push Notifications:** No real-time notifications
3. **Offline Post Creation:** Posts can only be created when online
4. **Advanced QR Features:** QR code generation, bulk scanning, printing
5. **Social Features:** User-to-user messaging, following system
6. **Map Integration:** GPS tracking and map views
7. **Multi-language Support:** MVP will be English-only
8. **Advanced AI Features:** Voice interaction, multi-image detection
9. **Adoption Management:** Full adoption workflow
10. **Emergency Reporting:** Direct NGO/municipal ticketing

---

## 8. Success Metrics (KPIs)

### User Engagement
- **Daily Active Users (DAU):** Target 150+ mobile users within first month
- **Post Creation Rate:** 10+ mobile posts per day
- **QR Scans:** 20+ dog registrations per week via QR scanning

### Feature Adoption
- **QR Scanner Usage:** 60% of active users scan at least one QR code
- **AI Chatbot Usage:** 40% of users try the chatbot feature
- **Disease Detection Usage:** 30% of users perform at least one disease scan
- **Directory Searches:** 70% of users perform searches or use filters

### Technical Performance
- **App Crashes:** Less than 0.5% crash rate
- **API Success Rate:** 95%+ successful API calls
- **Average Load Time:** Pages load in under 2 seconds

---

## 9. Release Plan

### Phase 1: MVP Release (Current Scope)

**Features:**
- User authentication and profile creation
- Community feed (view and post)
- Dog directory with search/filters
- QR code scanning and dog registration
- AI chatbot integration
- Disease detection integration
- User profile management

**Success Criteria:**
- 200+ registered users
- 50+ dogs registered via QR scanning
- < 1% crash rate

### Phase 2: Social Enhancement (Future)

**Features:**
- Comments on posts
- Like/reaction system
- Push notifications
- User-to-user messaging

### Phase 3: Advanced Features (Future)

**Features:**
- GPS map integration
- Offline post drafting
- QR code generation
- Emergency reporting

---

## Appendix A: Data Model Classes

### UserModel (Shared with Web)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String email;
  final String username;
  final String profilePictureUrl;
  final ContactInfo contactInfo;
  final String city;
  final String area;
  final String userType;
  final List<String> postIds;
  final List<String> dogIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.userId,
    required this.email,
    required this.username,
    required this.profilePictureUrl,
    required this.contactInfo,
    required this.city,
    required this.area,
    required this.userType,
    required this.postIds,
    required this.dogIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      profilePictureUrl: data['profilePictureUrl'] ?? '',
      contactInfo: ContactInfo.fromMap(data['contactInfo'] ?? {}),
      city: data['city'] ?? '',
      area: data['area'] ?? '',
      userType: data['userType'] ?? '',
      postIds: List<String>.from(data['postIds'] ?? []),
      dogIds: List<String>.from(data['dogIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'profilePictureUrl': profilePictureUrl,
      'contactInfo': contactInfo.toMap(),
      'city': city,
      'area': area,
      'userType': userType,
      'postIds': postIds,
      'dogIds': dogIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? email,
    String? username,
    String? profilePictureUrl,
    ContactInfo? contactInfo,
    String? city,
    String? area,
    String? userType,
    List<String>? postIds,
    List<String>? dogIds,
    DateTime? updatedAt,
  }) {
    return UserModel(
      userId: userId,
      email: email ?? this.email,
      username: username ?? this.username,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      contactInfo: contactInfo ?? this.contactInfo,
      city: city ?? this.city,
      area: area ?? this.area,
      userType: userType ?? this.userType,
      postIds: postIds ?? this.postIds,
      dogIds: dogIds ?? this.dogIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class ContactInfo {
  final String phone;
  final String email;

  ContactInfo({
    required this.phone,
    required this.email,
  });

  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    return ContactInfo(
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'email': email,
    };
  }
}
```

### DogModel (Enhanced for Mobile)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DogModel {
  final String dogId;
  final String? qrCodeId;
  final String name;
  final List<String> photos;
  final String mainPhotoUrl;
  final String area;
  final String city;
  final bool vaccinationStatus;
  final bool sterilizationStatus;
  final bool readyForAdoption;
  final String temperament;
  final String healthNotes;
  final DogAddedBy addedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  DogModel({
    required this.dogId,
    this.qrCodeId,
    required this.name,
    required this.photos,
    required this.mainPhotoUrl,
    required this.area,
    required this.city,
    required this.vaccinationStatus,
    required this.sterilizationStatus,
    required this.readyForAdoption,
    required this.temperament,
    required this.healthNotes,
    required this.addedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DogModel(
      dogId: doc.id,
      qrCodeId: data['qrCodeId'],
      name: data['name'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      mainPhotoUrl: data['mainPhotoUrl'] ?? '',
      area: data['area'] ?? '',
      city: data['city'] ?? '',
      vaccinationStatus: data['vaccinationStatus'] ?? false,
      sterilizationStatus: data['sterilizationStatus'] ?? false,
      readyForAdoption: data['readyForAdoption'] ?? false,
      temperament: data['temperament'] ?? '',
      healthNotes: data['healthNotes'] ?? '',
      addedBy: DogAddedBy.fromMap(data['addedBy'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'qrCodeId': qrCodeId,
      'name': name,
      'photos': photos,
      'mainPhotoUrl': mainPhotoUrl,
      'area': area,
      'city': city,
      'vaccinationStatus': vaccinationStatus,
      'sterilizationStatus': sterilizationStatus,
      'readyForAdoption': readyForAdoption,
      'temperament': temperament,
      'healthNotes': healthNotes,
      'addedBy': addedBy.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  DogModel copyWith({
    String? qrCodeId,
    String? name,
    List<String>? photos,
    String? mainPhotoUrl,
    String? area,
    String? city,
    bool? vaccinationStatus,
    bool? sterilizationStatus,
    bool? readyForAdoption,
    String? temperament,
    String? healthNotes,
    DateTime? updatedAt,
  }) {
    return DogModel(
      dogId: dogId,
      qrCodeId: qrCodeId ?? this.qrCodeId,
      name: name ?? this.name,
      photos: photos ?? this.photos,
      mainPhotoUrl: mainPhotoUrl ?? this.mainPhotoUrl,
      area: area ?? this.area,
      city: city ?? this.city,
      vaccinationStatus: vaccinationStatus ?? this.vaccinationStatus,
      sterilizationStatus: sterilizationStatus ?? this.sterilizationStatus,
      readyForAdoption: readyForAdoption ?? this.readyForAdoption,
      temperament: temperament ?? this.temperament,
      healthNotes: healthNotes ?? this.healthNotes,
      addedBy: addedBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class DogAddedBy {
  final String userId;
  final String username;
  final ContactInfo contactInfo;

  DogAddedBy({
    required this.userId,
    required this.username,
    required this.contactInfo,
  });

  factory DogAddedBy.fromMap(Map<String, dynamic> map) {
    return DogAddedBy(
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      contactInfo: ContactInfo.fromMap(map['contactInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'contactInfo': contactInfo.toMap(),
    };
  }
}
```

### PostModel (Shared with Web)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String content;
  final PostAuthor author;
  final DateTime timestamp;
  final DateTime createdAt;

  PostModel({
    required this.postId,
    required this.content,
    required this.author,
    required this.timestamp,
    required this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      postId: doc.id,
      content: data['content'] ?? '',
      author: PostAuthor.fromMap(data['author'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'author': author.toMap(),
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class PostAuthor {
  final String userId;
  final String username;
  final String profilePictureUrl;

  PostAuthor({
    required this.userId,
    required this.username,
    required this.profilePictureUrl,
  });

  factory PostAuthor.fromMap(Map<String, dynamic> map) {
    return PostAuthor(
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      profilePictureUrl: map['profilePictureUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'profilePictureUrl': profilePictureUrl,
    };
  }
}
```

### PredictionModel (Mobile)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PredictionModel {
  final String? predictionId;
  final String imageUrl;
  final String label;
  final double confidence;
  final String title;
  final String description;
  final List<String> symptoms;
  final List<String> treatments;
  final List<String> homecare;
  final String note;
  final String userId;
  final DateTime timestamp;

  PredictionModel({
    this.predictionId,
    required this.imageUrl,
    required this.label,
    required this.confidence,
    required this.title,
    required this.description,
    required this.symptoms,
    required this.treatments,
    required this.homecare,
    required this.note,
    required this.userId,
    required this.timestamp,
  });

  factory PredictionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PredictionModel(
      predictionId: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      label: data['label'] ?? '',
      confidence: (data['confidence'] ?? 0).toDouble(),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      symptoms: List<String>.from(data['symptoms'] ?? []),
      treatments: List<String>.from(data['treatments'] ?? []),
      homecare: List<String>.from(data['homecare'] ?? []),
      note: data['note'] ?? '',
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'label': label,
      'confidence': confidence,
      'title': title,
      'description': description,
      'symptoms': symptoms,
      'treatments': treatments,
      'homecare': homecare,
      'note': note,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
```

### Message Model (Chatbot)

```dart
class Message {
  final String role;
  final String text;
  final DateTime timestamp;

  Message({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'],
      text: json['text'],
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'text': text,
    };
  }
}
```

### QR Scanner Result Model

```dart
class QRScanResult {
  final String qrCodeId;
  final bool isValid;
  final DogModel? existingDog;
  final DateTime scannedAt;

  QRScanResult({
    required this.qrCodeId,
    required this.isValid,
    this.existingDog,
    required this.scannedAt,
  });
}
```

### DogFilters

```dart
class DogFilters {
  final bool vaccinated;
  final bool sterilized;
  final bool readyForAdoption;

  DogFilters({
    required this.vaccinated,
    required this.sterilized,
    required this.readyForAdoption,
  });

  DogFilters copyWith({
    bool? vaccinated,
    bool? sterilized,
    bool? readyForAdoption,
  }) {
    return DogFilters(
      vaccinated: vaccinated ?? this.vaccinated,
      sterilized: sterilized ?? this.sterilized,
      readyForAdoption: readyForAdoption ?? this.readyForAdoption,
    );
  }

  bool get hasActiveFilters =>
      vaccinated || sterilized || readyForAdoption;
}
```

---

## Appendix B: Service Classes

### AuthService

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign in aborted');
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
```

### FirestoreService

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create user profile
  Future<void> createUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.userId).set(user.toMap());
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('users').doc(userId).update(updates);
  }

  // Check username uniqueness
  Future<bool> isUsernameAvailable(String username) async {
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  // Create post
  Future<String> createPost(PostModel post, String userId) async {
    final postRef = await _db.collection('posts').add(post.toMap());
    
    await _db.collection('users').doc(userId).update({
      'postIds': FieldValue.arrayUnion([postRef.id]),
    });
    
    return postRef.id;
  }

  // Delete post
  Future<void> deletePost(String postId, String userId) async {
    await _db.collection('posts').doc(postId).delete();
    
    await _db.collection('users').doc(userId).update({
      'postIds': FieldValue.arrayRemove([postId]),
    });
  }

  // Create dog record
  Future<String> createDogRecord(DogModel dog, String userId) async {
    final dogRef = await _db.collection('dogs').add(dog.toMap());
    
    await _db.collection('users').doc(userId).update({
      'dogIds': FieldValue.arrayUnion([dogRef.id]),
    });
    
    return dogRef.id;
  }

  // Update dog record
  Future<void> updateDogRecord(String dogId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('dogs').doc(dogId).update(updates);
  }

  // Delete dog record
  Future<void> deleteDogRecord(String dogId, String userId) async {
    await _db.collection('dogs').doc(dogId).delete();
    
    await _db.collection('users').doc(userId).update({
      'dogIds': FieldValue.arrayRemove([dogId]),
    });
  }
}
```

### QRService

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class QRService {
  // Check if QR code exists in database
  Future<DogModel?> getDogByQRCode(String qrCodeId) async {
    try {
      final query = await FirebaseFirestore.instance
        .collection('dogs')
        .where('qrCodeId', isEqualTo: qrCodeId)
        .limit(1)
        .get();
      
      if (query.docs.isEmpty) return null;
      
      return DogModel.fromFirestore(query.docs.first);
    } catch (e) {
      throw Exception('Failed to fetch dog: $e');
    }
  }
  
  // Validate QR code format
  bool isValidQRCode(String qrCode) {
    final regex = RegExp(r'^MIT-DOG-[A-Z0-9]{4,8});
    return regex.hasMatch(qrCode);
  }
}
```

### PermissionService

```dart
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  // Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    return false;
  }
  
  // Request storage permission
  Future<bool> requestStoragePermission() async {
    if (Platform.isIOS) return true;
    
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      
      if (androidInfo.version.sdkInt >= 33) {
        return true;
      }
      
      final status = await Permission.storage.request();
      
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
    }
    
    return false;
  }
  
  // Check if permissions are granted
  Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'camera': await Permission.camera.isGranted,
      'storage': await Permission.storage.isGranted,
    };
  }
}
```

### SessionManager

```dart
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _sessionKey = 'chatbot_session_id';
  
  // Get or create session
  Future<String> getOrCreateSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString(_sessionKey);
    
    if (sessionId == null) {
      // Create new session via API
      final response = await chatbotApi.createSession();
      sessionId = response['session_id'];
      await prefs.setString(_sessionKey, sessionId);
    }
    
    return sessionId;
  }
  
  // Clear session
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
  
  // Get session history
  Future<List<Message>> getHistory(String sessionId) async {
    return await chatbotApi.getHistory(sessionId);
  }
}
```

### ChatbotApi

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotApi {
  static const String baseUrl = 'https://mitran-chatbot.onrender.com';
  
  // Health check
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // Create session
  Future<Map<String, dynamic>> createSession() async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/sessions'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create session');
    }
  }
  
  // Get history
  Future<List<Message>> getHistory(String sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/v1/chat/history?session_id=$sessionId'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final messages = data['messages'] as List;
      return messages.map((m) => Message.fromJson(m)).toList();
    } else {
      throw Exception('Failed to get history');
    }
  }
  
  // Send message
  Future<Map<String, dynamic>> sendMessage(String sessionId, String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/chat/send'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'session_id': sessionId,
        'text': text,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to send message');
    }
  }
}
```

### DiseaseApi

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class DiseaseApi {
  static const String baseUrl = 'https://mitran-disease-detection.onrender.com';
  
  // Health check
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // Get labels
  Future<List<String>> getLabels() async {
    final response = await http.get(Uri.parse('$baseUrl/labels'));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['labels']);
    } else {
      throw Exception('Failed to get labels');
    }
  }
  
  // Predict
  Future<Map<String, dynamic>> predict(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/predict'),
    );
    
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to predict: ${response.body}');
    }
  }
}
```

---

## Appendix C: Utility Classes

### Validators

```dart
class Validators {
  // Validate username
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    
    if (value.length > 20) {
      return 'Username must be less than 20 characters';
    }
    
    final regex = RegExp(r'^[a-zA-Z0-9_-]+);
    if (!regex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, underscores, and hyphens';
    }
    
    return null;
  }
  
  // Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    final numbers = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (numbers.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    return null;
  }
  
  // Validate dog name
  static String? validateDogName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Dog name is required';
    }
    
    if (value.length < 2) {
      return 'Dog name must be at least 2 characters';
    }
    
    if (value.length > 30) {
      return 'Dog name must be less than 30 characters';
    }
    
    return null;
  }
  
  // Validate post content
  static String? validatePostContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Post content cannot be empty';
    }
    
    if (value.length > 500) {
      return 'Post must be less than 500 characters';
    }
    
    return null;
  }
  
  // Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
```

### DateFormatter

```dart
import 'package:intl/intl.dart';

class DateFormatter {
  // Get relative time string
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }
  
  // Format date for display
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM d, yyyy').format(dateTime);
  }
  
  // Format date and time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
  }
  
  // Format timestamp for posts
  static String formatPostTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays < 1) {
      return getRelativeTime(dateTime);
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return formatDate(dateTime);
    }
  }
}
```

### ImageHelper

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ImageHelper {
  // Compress image for upload
  static Future<File> compressImage(
    File imageFile, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    // Use flutter_image_compress or similar package
    // This is a placeholder - implement with actual compression
    return imageFile;
  }
  
  // Get image size
  static Future<Size> getImageSize(File imageFile) async {
    final image = await decodeImageFromList(
      await imageFile.readAsBytes(),
    );
    return Size(image.width.toDouble(), image.height.toDouble());
  }
  
  // Validate image file
  static bool isValidImageFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png'].contains(extension);
  }
  
  // Get file size in MB
  static Future<double> getFileSizeInMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }
}
```

---

## Appendix D: Riverpod Providers

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Auth Provider
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// User Profile Provider
final userProfileProvider = StreamProvider.family<UserModel, String>((ref, userId) {
  return FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .snapshots()
    .map((doc) => UserModel.fromFirestore(doc));
});

// Posts Feed Provider
final postsProvider = StreamProvider<List<PostModel>>((ref) {
  return FirebaseFirestore.instance
    .collection('posts')
    .orderBy('timestamp', descending: true)
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => PostModel.fromFirestore(doc))
      .toList());
});

// Dogs Directory Provider
final dogsProvider = StreamProvider<List<DogModel>>((ref) {
  return FirebaseFirestore.instance
    .collection('dogs')
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => DogModel.fromFirestore(doc))
      .toList());
});

// Single Dog Provider
final dogProvider = StreamProvider.family<DogModel, String>((ref, dogId) {
  return FirebaseFirestore.instance
    .collection('dogs')
    .doc(dogId)
    .snapshots()
    .map((doc) => DogModel.fromFirestore(doc));
});

// Filter State Provider
final dogFiltersProvider = StateProvider<DogFilters>((ref) {
  return DogFilters(
    vaccinated: false,
    sterilized: false,
    readyForAdoption: false,
  );
});

// Search Term Provider
final searchTermProvider = StateProvider<String>((ref) => '');

// Filtered Dogs Provider
final filteredDogsProvider = Provider<List<DogModel>>((ref) {
  final dogs = ref.watch(dogsProvider).value ?? [];
  final filters = ref.watch(dogFiltersProvider);
  final searchTerm = ref.watch(searchTermProvider);
  
  return dogs.where((dog) {
    // Search filter
    if (searchTerm.isNotEmpty) {
      final matchesName = dog.name.toLowerCase().contains(searchTerm.toLowerCase());
      final matchesArea = dog.area.toLowerCase().contains(searchTerm.toLowerCase());
      if (!matchesName && !matchesArea) return false;
    }
    
    // Status filters
    if (filters.vaccinated && !dog.vaccinationStatus) return false;
    if (filters.sterilized && !dog.sterilizationStatus) return false;
    if (filters.readyForAdoption && !dog.readyForAdoption) return false;
    
    return true;
  }).toList();
});
```

---

## Appendix E: Key Differences from Web Platform

| Feature | Web Platform | Mobile App |
|---------|--------------|------------|
| **Onboarding** | Direct to landing page | Splash screen + intro slider |
| **Navigation** | Top navigation bar | Bottom navigation bar (5 tabs) |
| **QR Scanning** | Not available | Native camera QR scanner |
| **Dog Registration** | Not available | Via QR scan + form |
| **Image Capture** | File upload only | Camera + gallery picker |
| **Session Storage** | localStorage | shared_preferences |
| **Permissions** | Not applicable | Camera, storage permissions |
| **Offline** | Limited | Firestore offline persistence |
| **CORS** | Required for APIs | Not applicable |
| **Contact Actions** | Display only | Call/SMS/Email intents |

---

**END OF DOCUMENT**
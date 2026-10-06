# BeemView — Task Management Mobile App

[![Flutter](https://img.shields.io/badge/Flutter-3.47.6-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.5-blue.svg)](https://dart.dev)
[![State Management](https://img.shields.io/badge/Bloc%2FCubit-9.1.0-orange.svg)](https://pub.dev/packages/flutter_bloc)
[![License](https://img.shields.io/badge/license-Proprietary-lightgrey.svg)]()

A modern, production-grade Flutter mobile application built for the **BeemView Flutter Developer Assignment**. The app enables users to securely authenticate with their tenant subdomain, explore active projects, view and filter project tasks, update task statuses across 8 distinct states, and attach notes/comments.

---

## 📱 Project Overview

BeemView is a multi-tenant task and project management mobile application designed with a modern, creative aesthetic:
1. **Screen 1: Authentication (Login)**: Secure multi-tenant login with email, password, and tenant subdomain validation, persisted bearer token storage, and session restoration.
2. **Screen 2: Executive Dashboard**: Real-time KPI metrics, health score overview, task distribution charts, and quick-access initiatives.
3. **Screen 3: Projects List**: Paginated project cards with vibrant gradients, pull-to-refresh, search, and project creation.
4. **Screen 4: Project Tasks**: Project tasks overview with real-time search filtering, status filter chips, color-coded badges, and task creation.
5. **Screen 5: Task Details & Status Update**: Detailed view showing project hierarchy, assignee avatars, timestamps, description, latest comments, and 2-step status updates.
6. **Screen 6: User Profile**: Live authenticated user profile (`/api/users/me/profile`), personal & workspace details, live Dark/Light mode toggle, and language switcher.

### 🌟 Key Enhancements
- **Dynamic Theming**: Full **Dark Mode** & **Light Mode** switching with persistent state.
- **Internationalization**: Full **English** & **Arabic (العربية)** bilingual support.
- **APK Optimization**: Architecture splitting & R8 minification reducing build size from >150MB to ~19MB.

---

## 🛠️ Setup & Run

### Prerequisites
- Flutter SDK **3.47.6** (or compatible 3.x)
- Dart SDK **^3.13.5**
- Android device / emulator or Chrome browser

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure API & Tenant Subdomain
Open [`lib/config/api_config.dart`](file:///c:/Users/DELL/Desktop/flutter/lib/config/api_config.dart) and configure your tenant subdomain (if pre-filling is desired):

```dart
class ApiConfig {
  static const String origin = 'https://beemview.com';
  static const String subdomain = 'your-subdomain'; // Optional default
  ...
}
```

### 3. Run the App

#### On Connected Android Device / Emulator:
```bash
flutter run
```

#### On Web (Chrome):
Because the backend API does not serve CORS headers for web localhost, pass the web security flag during local browser testing:
```bash
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

#### Build Android APK:
```bash
flutter build apk --debug
# The output APK will be generated at:
# build/app/outputs/flutter-apk/app-debug.apk
```

---

## 📦 Key Packages

| Package | Version | Purpose |
|---|---|---|
| [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) | `^9.1.0` | Predictable state management via Cubits |
| [`dio`](https://pub.dev/packages/dio) | `^5.8.0+1` | HTTP client with interceptors, timeouts, and token injection |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | `^9.2.4` | Keychain/Keystore encrypted token & credentials persistence |
| [`equatable`](https://pub.dev/packages/equatable) | `^2.0.7` | Value equality for immutable states and models |
| [`intl`](https://pub.dev/packages/intl) | `^0.20.2` | Clean date formatting and relative timestamps |
| [`mocktail`](https://pub.dev/packages/mocktail) | `^1.0.4` | Null-safe mocking for unit & widget tests |
| [`bloc_test`](https://pub.dev/packages/bloc_test) | `^10.0.0` | Comprehensive testing utilities for Cubit states |

---

## 🏛️ Architecture

The codebase follows the **Repository Pattern** and clean architectural separation of concerns:

```
lib/
├── blocs/               # Presentation State Management (Cubits & States)
│   ├── auth/            # Authentication, session restoration & logout
│   ├── projects/        # Projects list & pagination
│   ├── tasks/           # Project tasks, local search & chip filtering
│   └── task_detail/     # Task detail loading, 2-step status/comment update
├── config/              # App themes, constants & API configuration
├── data/
│   ├── api/             # Raw HTTP Dio endpoints & AuthInterceptor
│   └── repositories/    # Data transformation, error mapping & business logic
├── models/              # Immutable data models with contract normalization
├── screens/             # UI screens with responsive, modern aesthetic
├── utils/               # Status helpers, date formatting & utilities
└── widgets/             # Reusable UI components (badges, cards, chips)
```

### 🧠 State Management: Why Cubit?
- **Lightweight & Predictable**: Cubits reduce event boilerplate while maintaining strict unidirectional data flow (`Action -> Cubit Method -> Emitted State`).
- **Testability**: Easily testable with `bloc_test` without creating repetitive event classes.
- **Granular Reactivity**: Clear state transitions (`Initial`, `Loading`, `Loaded`, `Success`, `Error`) with `BlocConsumer` and `BlocBuilder`.

---

## 🔄 Critical API Normalization & Contract Details

### API Field Normalization Table
The BeemView API returns varying field names and priority casing depending on the endpoint. The `Task` model normalizes these variations transparently:

| Field | `/tasks/project/:id` (List) | `/tasks/:id` (Detail) | Normalized Model Field |
|---|---|---|---|
| **Due date** | `dueDate` | `due_date` | `dueDate` (`DateTime?`) |
| **Start date** | `startedDate` | `start_date` | `startDate` (`DateTime?`) |
| **Priority** | `"High"` (capitalized) | `"high"` (lowercase) | Normalized lowercase (`low`, `medium`, `high`, `urgent`) |
| **Task title** | `name` | `name` | `name` (`String`) |

### Response Envelope Handling
The projects endpoint returns two different shapes which are handled transparently by `PaginatedResponse.fromJson`:
- **Normal**: `{"total": N, "count": N, "limit": 10, "offset": 0, "data": [...]}`
- **Empty**: `{"result": [], "count": 0}`

### Status Update Flow (Two-Step Operation)
Status updates and comments are separate endpoints (`PUT /tasks/:id` and `POST /tasks/comment`).
1. **Duplicate Prevention**: Submission is locked via `isSubmitting = true`.
2. **PUT `/tasks/:id`**: Sends `{"status": "<status>"}` (never sends a `progress` field).
3. **If note provided**: Calls `POST /tasks/comment`.
4. **Partial Success Handling**: If status succeeds but comment fails, the note is preserved and the UI offers a dedicated **"Retry Comment"** button (preventing re-submission of the already-saved status).
5. **No Auto-Retry**: Ambiguous network failures never auto-retry comments to avoid duplicates.

---

## 🛡️ Error Handling Matrix

| HTTP Code / Condition | Meaning | Application Action |
|---|---|---|
| **400** | Invalid credentials / input | Displays specific validation error message from response |
| **401** | Missing / invalid / expired token | Interceptor calls `onSessionExpired()` → clears storage → redirects to Login |
| **403** | Insufficient access / inactive account | Shows specific access error (**not** treated as session expiry) |
| **404** | Task or project not found | Shows "Not found" view with retry option |
| **429** | Rate limited | Shows "Too many requests, try again later" |
| **500** | Server error | Displays server error message with retry button |
| **Timeout / Offline** | Network failure | Displays connectivity warning with retry |

---

## 📋 Assumptions

1. **Token Lifetime**: Token lifetime is approximately 7 days; expired tokens receive `401` which triggers session clearance.
2. **No Refresh Endpoint**: Token refreshing is not provided by the API; expired tokens require user re-authentication.
3. **No Logout Endpoint**: Session destruction is handled securely client-side by purging encrypted local storage.
4. **Task Progress**: No progress percentage is updated or passed during task status updates per specification.

---

## ⚠️ Known Limitations

- **Web CORS**: The production API does not provide CORS headers for web browsers (`localhost`), requiring `--disable-web-security` for Chrome testing. Native mobile platforms (Android/iOS) communicate over sockets and are completely unaffected.
- **Offline Storage**: Network calls require an active internet connection (no offline caching or local database sync implemented per scope).

---

## 🚫 Out of Scope (Per Assignment)

- Project / task creation
- File attachments & media uploads
- Push notifications
- Offline synchronization & local database
- 3D / BIM viewing
- Backend modifications
- Task progress percentage modification
- Complete comment history screen
- Priority editing
- Task codes
- Server-side filtering via `/api/tasks`

---

## 🧪 Running Tests

To run the automated test suite:

```bash
flutter test
```

To run static analysis:

```bash
flutter analyze
```

---

## ⏱️ Time Estimate

| Phase | Task Description | Estimated Hours |
|---|---|:---:|
| **1** | Project setup & configuration | ~1.0 h |
| **2** | Models & data layer (normalization) | ~2.0 h |
| **3** | API client & interceptors (AuthInterceptor) | ~1.5 h |
| **4** | Repositories (Auth, Project, Task) | ~1.5 h |
| **5** | State management (Cubits & States) | ~2.0 h |
| **6** | Screens & UI (Login, Projects, Tasks, Details) | ~4.0 h |
| **7** | Tests & verification | ~1.0 h |
| **8** | README & documentation cleanup | ~0.5 h |
| **Total** | | **~13.5 h** |

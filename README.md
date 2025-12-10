# 🎓 Attendance App

![QR Attendance](assets/pics/qrAttendance.jpg)

## Overview

AttendanceApp is a comprehensive Flutter mobile application for schools and organizations to streamline attendance tracking through QR code scanning, geolocation verification, and real-time cloud synchronization. The system provides role-based dashboards for students, teachers, and administrators with centralized attendance management via Firebase Firestore.

## ✨ Core Features

### Student Features

- **QR Code Check-In/Out**: Scan QR codes with automatic timestamp recording
- **Dual Timestamp Tracking**: Separate check-in and check-out time logging
- **Location Verification**: GPS coordinates with reverse geocoding to physical addresses
- **Real-Time Status Display**: Live attendance status with formatted timestamps
- **Attendance Calendar**: Monthly view of personal attendance history
- **Profile Management**: Update personal information with Cloudinary image uploads

### Teacher Features

- **Attendance Dashboard**: View all advisory class attendance records in real-time
- **Student Roster Management**: Track students by advisory section or teacher UID
- **Detailed Time Logs**: See exact check-in and check-out times for each student
- **Status Filtering**: Monitor Present, Late, and Absent records with color-coded badges
- **Profile Overview**: Manage teacher profile with contact details and advisory assignment

### Admin Features

- **User Verification**: Approve or reject pending student/teacher registrations
- **Event Management**: Create and manage attendance events with QR code generation
- **System-Wide Analytics**: Overview of all attendance records across the institution
- **Role Management**: Assign and manage user roles (student/teacher/admin)

### Technical Features

- **Firebase Authentication**: Secure email/password and social provider login
- **Role-Based Access Control**: Dedicated dashboards per user type
- **Real-Time Sync**: Instant Firestore updates across all connected devices
- **Composite Firestore Queries**: Optimized multi-field indexing for performance
- **Offline Support**: Local data capture with automatic cloud sync when online
- **Multi-Provider Linking**: Support for Google, Facebook, and email authentication

## 🛠️ Tech Stack

### Frontend

- **Flutter 3.10+** – Cross-platform UI framework
- **Dart SDK** – Primary programming language
- **Material Design 3** – Modern UI components with custom theming

### Backend & Cloud Services

- **Firebase Authentication** – Secure user authentication with multi-provider support
- **Cloud Firestore** – Real-time NoSQL database for attendance records
- **Firebase Storage** – Media file storage (deprecated, migrated to Cloudinary)
- **Cloudinary** – Profile picture uploads and management
- **Firebase Cloud Functions** – Server-side triggers for notifications and approvals

### Key Packages

- **`mobile_scanner`** – High-performance QR code scanning
- **`qr_flutter`** – Dynamic QR code generation for events
- **`geolocator`** – GPS location capture with high accuracy
- **`geocoding`** – Reverse geocoding for address resolution
- **`flutter_map`** – Interactive maps with OpenStreetMap tiles
- **`intl`** – Date/time formatting and localization
- **`image_picker`** – Camera/gallery photo selection
- **`shared_preferences`** – Local key-value storage

### Database Collections

- **`Users`** – User profiles with role, status, and authentication metadata
- **`Student`** – Student-specific data including advisory assignments
- **`AttendanceRecords`** – Centralized attendance logs with check-in/out timestamps
- **`Events`** – Attendance events with location and time window validation
- **`Student/{studentDocId}/Record`** – Legacy daily attendance subcollection (deprecated)

## 👥 Development Team

- **Christian Misal** – Project Lead & System Architect
- **Kenneth D. Lico** – Frontend Engineer & UI/UX Designer
- **John Lyold C. Lozada** – Backend Developer & Firebase Integration
- **Joseph Claire L. Paquinol** – Full-Stack Engineer & QR Implementation

## 📐 Architecture

### Design Pattern

- **Layered Architecture**: Presentation → Application → Domain → Data
- **StatefulWidget Management**: State management via Flutter's built-in setState
- **Service Layer**: Centralized AuthService for authentication logic
- **Repository Pattern**: Firestore data access abstraction

### Project Structure

```
lib/
  ├── main.dart                          # App entry point with role-based routing
  ├── model/
  │   └── user.dart                      # Global user model
  ├── services/
  │   ├── auth_service.dart              # Authentication logic
  │   └── location_service.dart          # GPS and geocoding utilities
  ├── config/
  │   └── firebase_options.dart          # Firebase configuration
  ├── screens/
  │   ├── homescreen.dart                # Student dashboard
  │   ├── todayscreen.dart               # QR scanning and attendance
  │   ├── teacher_home.dart              # Teacher dashboard with attendance log
  │   ├── admin_home.dart                # Admin dashboard
  │   ├── verification_screen.dart       # User approval interface
  │   ├── unified_event_screen.dart      # Event management
  │   └── complete_credentials_screen.dart # Social auth completion
  └── widgets/                           # Reusable UI components

assets/
  ├── fonts/                             # Custom fonts (Nexa)
  ├── icons/                             # App icons
  └── pics/                              # Images and screenshots

android/                                 # Android-specific configuration
ios/                                     # iOS-specific configuration
web/                                     # Web support files
```

### Data Flow

1. **Authentication**: User signs in → `AuthService` validates → User model hydrated
2. **Attendance Recording**: QR scan → Token validation → Firestore write with timestamps
3. **Teacher Dashboard**: Query `AttendanceRecords` → Filter by advisory/section → Display with formatting
4. **Real-Time Updates**: Firestore listeners trigger UI rebuilds automatically

## 🚀 Project Setup

### Prerequisites

1. **Flutter SDK 3.10+**: [Installation Guide](https://docs.flutter.dev/get-started/install)
2. **Firebase Project**: Create a project at [Firebase Console](https://console.firebase.google.com/)
3. **Cloudinary Account**: Sign up at [Cloudinary](https://cloudinary.com/) for image uploads
4. **Android Studio / VS Code**: With Flutter and Dart plugins installed

### Installation Steps

1. **Clone the repository**

   ```bash
   git clone https://github.com/DeJure12705/Attendance-App.git
   cd Attendance-App
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**

   - Download `google-services.json` (Android) and place in `android/app/`
   - Download `GoogleService-Info.plist` (iOS) and place in `ios/Runner/`
   - Ensure package names match your Firebase project settings
   - Add SHA-1 and SHA-256 fingerprints for Android in Firebase Console

4. **Enable Firebase Services**

   - Authentication → Enable Email/Password, Google, Facebook providers
   - Firestore Database → Create database in production mode
   - Storage → Enable (or configure Cloudinary)
   - Cloud Functions → Deploy approval notification triggers (optional)

5. **Create Firestore Indexes**

   - Navigate to Firestore → Indexes tab
   - Create composite index: `Users` collection with fields:
     - `status` (Ascending)
     - `createdAt` (Descending)

6. **Run the app**

   ```bash
   # Run on connected device
   flutter run

   # Run on specific platform
   flutter run -d chrome          # Web
   flutter run -d android         # Android
   flutter run -d ios             # iOS (macOS only)
   ```

7. **Build release versions**

   ```bash
   # Android APK
   flutter build apk --release

   # Android App Bundle
   flutter build appbundle --release

   # iOS (requires macOS)
   flutter build ipa --release
   ```

## Environment Configuration

Create a file (example): `lib/config/app_config.dart` or use `.env` with `flutter_dotenv`.
Placeholders:

- API_BASE_URL=
- AUTH_PROVIDER=
- ANALYTICS_ENABLED=true|false

## 📊 Current Implementation Details

### Attendance Recording System

The app uses a **centralized AttendanceRecords collection** for efficient querying and teacher dashboard access:

**Collection**: `AttendanceRecords`  
**Document ID Format**: `{date}_{studentId}` (e.g., `09 December 2025_12345`)

**Document Structure**:

```javascript
{
  studentId: "12345",                    // Student identifier
  studentName: "John Doe",               // Full name from Users collection
  date: Timestamp,                       // Date-only timestamp (midnight)
  status: "Present" | "Late" | "Absent", // Attendance status
  timestamp: Timestamp,                  // Original event timestamp (legacy)
  checkInTime: Timestamp,                // Exact check-in time
  checkOutTime: Timestamp,               // Exact check-out time
  advisory: "Grade 10-A",                // Student's advisory/section
  section: "Grade 10-A",                 // Duplicate for query flexibility
  adviserTeacherUid: "uid123",           // Teacher UID for roster queries
  qrCode: "CHECKIN:12345",               // Scanned QR code content
  location: "123 Main St, City",         // Reverse-geocoded address
  latitude: 14.5995,                     // GPS coordinates
  longitude: 120.9842
}
```

### QR Code Attendance Flow

1. **Check-In Process**:

   - Student scans QR code with `CHECKIN:` prefix
   - System captures GPS coordinates and timestamp
   - Firestore document created with `checkInTime` and status (Present/Late based on time window)
   - UI displays formatted check-in time and location

2. **Check-Out Process**:

   - Student scans QR code with `CHECKOUT:` prefix on same day
   - System updates existing document with `checkOutTime`
   - GPS coordinates captured for check-out location
   - UI updates to show both timestamps

3. **Token Classification**:

   - `CHECKIN:` – Morning/start of event check-in
   - `CHECKOUT:` – End of day/event check-out
   - `DYN:` – Dynamic tokens with time-window validation
   - `EVENT:{id}` – Specific event attendance

4. **Status Determination**:
   - **Present**: Check-in within configured time window
   - **Late**: Check-in after grace period
   - **Absent**: No check-in record for the day

### Teacher Dashboard Features

**File**: `lib/teacher_home.dart`

Teachers can view real-time attendance logs for their advisory class:

- **Query Strategy**: Multi-field queries by `advisory`, `section`, and `adviserTeacherUid`
- **Student Roster Integration**: Cross-references `Student` collection for complete class list
- **Fallback Queries**: If targeted queries return empty, fetches all recent records
- **Display Format**:
  - Student name (resolved from Users collection)
  - Date (MM/DD/YYYY format)
  - Check-in time (hh:mm a format, e.g., "08:30 AM")
  - Check-out time (hh:mm a format, e.g., "03:45 PM")
  - Status badge (color-coded: green=Present, orange=Late, red=Absent)

**Key Query Logic**:

```dart
// Query by advisory/section
await collection('AttendanceRecords')
  .where('advisory', isEqualTo: teacherAdvisory)
  .get();

// Query by teacher UID
await collection('AttendanceRecords')
  .where('adviserTeacherUid', isEqualTo: teacherUid)
  .get();

// Query by student roster IDs (chunked for whereIn limit)
await collection('AttendanceRecords')
  .where('studentId', whereIn: studentIds)
  .get();
```

## 🔐 Role-Based Authentication

### Authentication Flow

1. **User Registration**:

   - Users register via `RoleLoginScreen` with email, password, and role selection
   - Students must provide Student ID to link with existing `Student` documents
   - Document created in `Users` collection with `status: 'pending'` or `status: 'incomplete'` (social auth)

2. **User Document Structure** (`Users` collection):

   ```javascript
   {
     uid: "firebase_auth_uid",
     email: "user@example.com",
     role: "student" | "teacher" | "admin",
     studentId: "12345",              // Students only
     status: "incomplete" | "pending" | "approved" | "rejected",
     providers: ["password", "google", "facebook"],
     fullName: "John Doe",
     advisory: "Grade 10-A",          // Teachers and students
     contactNumber: "+1234567890",
     address: "123 Main St",
     profilePictureUrl: "https://...",
     fcmToken: "device_token",
     createdAt: Timestamp
   }
   ```

3. **Role-Based Routing** (`main.dart`):

   ```dart
   switch (User.role) {
     case 'student': → Homescreen
     case 'teacher': → TeacherHome
     case 'admin': → AdminHome
   }
   ```

4. **Status-Based Access**:
   - `incomplete` → `CompleteCredentialsScreen` (social auth only)
   - `pending` → `PendingVerificationScreen` (awaiting admin approval)
   - `approved` → Role-specific dashboard
   - `rejected` → Access denied message

### Multi-Provider Authentication

**Supported Providers**:

- Email/Password (Firebase Auth)
- Google Sign-In
- Facebook Login

**Social Sign-In Flow**:

1. User selects social provider on login screen
2. OAuth flow completes → Firebase creates user account
3. If first login: `status: 'incomplete'`, routed to credential completion
4. User selects role and (if student) enters Student ID
5. Status changes to `pending` → Admin approval required
6. Approved users gain full dashboard access

**Provider Linking**:

- Multiple auth methods can be linked to one account
- `providers` array tracks all linked methods
- Example: User signs in with Google, later links Facebook → both work for login

## 📱 QR Code & Location Workflow

### QR Code Generation

**Event QR Codes** (`unified_event_screen.dart`):

- Admins/Teachers create events with date, time, location
- System generates unique QR codes with prefixes:
  - `CHECKIN:{eventId}` – For morning/entry scanning
  - `CHECKOUT:{eventId}` – For evening/exit scanning
  - `DYN:{token}` – Dynamic tokens with time-window validation
- QR codes displayed on screen for printing or projection

### Scanning Process

**Scanner Implementation** (`todayscreen.dart`):

1. Student opens Today Screen → Taps scan button
2. Camera permission requested (if not granted)
3. `mobile_scanner` package activates device camera
4. QR code detected → Token classification begins

**Token Classification**:

```dart
_ScanType _classifyToken(String token) {
  if (token.startsWith('CHECKIN:')) return checkIn;
  if (token.startsWith('CHECKOUT:')) return checkOut;
  if (token.startsWith('DYN:')) return dynamicToken;
  if (token.startsWith('EVENT:')) return event;
  return unknown;
}
```

### Location Services

**GPS Capture**:

- Location permission requested on app launch
- `geolocator` package with `LocationAccuracy.best` (±10m accuracy)
- Coordinates captured at scan time: `(latitude, longitude)`

**Reverse Geocoding**:

- `geocoding` package converts coordinates to human-readable addresses
- Format: "Street, Barangay, City, Country"
- Fallback: Shows coordinates if geocoding fails

**Geofence Validation** (Event-based):

- Events define allowed radius from target location
- System calculates distance using Haversine formula
- Check-in rejected if outside allowed radius (configurable, default 100m)

### Location Display

**Interactive Map** (`flutter_map` with OpenStreetMap):

- Shows student's current location with blue marker
- Check-in location marked with green pin
- Check-out location marked with red pin
- Pan and zoom controls enabled
- Real-time updates as student moves

## ⚙️ Firebase Configuration & Troubleshooting

### Common Firebase Errors

#### `CONFIGURATION_NOT_FOUND` Error

**Symptoms**:

- `FirebaseAuthException: CONFIGURATION_NOT_FOUND`
- reCAPTCHA internal errors during sign-in
- App crashes on authentication attempts

**Solutions**:

1. **Verify Configuration Files**:

   - `android/app/google-services.json` must match Firebase project
   - `ios/Runner/GoogleService-Info.plist` must match Firebase project
   - Check package name in `android/app/build.gradle` matches Firebase Console

2. **Add SHA Fingerprints** (Android):

   ```bash
   # Debug SHA-1
   cd android
   ./gradlew signingReport

   # Add both SHA-1 and SHA-256 to Firebase Console:
   # Project Settings → Android App → Add fingerprint
   ```

   - Re-download `google-services.json` after adding fingerprints

3. **Enable Authentication Providers**:

   - Firebase Console → Authentication → Sign-in method
   - Enable: Email/Password, Google, Facebook
   - Add OAuth redirect URIs for social providers

4. **Clean and Rebuild**:

   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

5. **Android API 33+ Considerations**:
   - Update `minSdkVersion` to 21+ in `android/app/build.gradle`
   - Ensure Play Integrity API enabled in Google Cloud Console

#### Index Creation Errors

**Error**: `FAILED_PRECONDITION: The query requires an index`

**Required Index** (Users collection):

- Field 1: `status` (Ascending)
- Field 2: `createdAt` (Descending)

**Create via Firebase Console**:

1. Firestore Database → Indexes tab → Create Index
2. Collection: `Users`
3. Add fields as above → Create

**Create via CLI**:

```json
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "Users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

```bash
firebase deploy --only firestore:indexes
```

### Firebase Security Rules (Sample)

**Firestore Rules** (see `firestore.rules.sample`):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - authenticated users can read own doc
    match /Users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // AttendanceRecords - students write own, teachers read advisory
    match /AttendanceRecords/{recordId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null &&
                       request.resource.data.studentId == request.auth.token.studentId;
      allow update: if request.auth != null &&
                       resource.data.studentId == request.auth.token.studentId;
    }

    // Admin-only collections
    match /Events/{eventId} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.role == 'admin' ||
                      request.auth.token.role == 'teacher';
    }
  }
}
```

## 👤 Account Verification & Approval Workflow

### Registration States

**Status Progression**:

```
Registration → incomplete/pending → approved → Full Access
                                  ↘ rejected → Access Denied
```

### Email/Password Registration

1. User fills form on `RoleLoginScreen`:
   - Email, password, role selection
   - Student ID (for students only)
2. `Users/{uid}` document created with:
   - `status: 'pending'`
   - `role: selected_role`
   - `createdAt: Timestamp`
3. User routed to `PendingVerificationScreen`
4. Admin/Teacher approves → `status: 'approved'` → Dashboard access

### Social Provider Registration

1. User selects Google/Facebook sign-in
2. OAuth flow completes → Firebase user created
3. `Users/{uid}` document created with:
   - `status: 'incomplete'`
   - `providers: ['google']` or `['facebook']`
   - No `role` field yet
4. User routed to `CompleteCredentialsScreen`
5. User selects role + enters Student ID (if student)
6. Document updated:
   - `status: 'pending'`
   - `role: selected_role`
   - `studentId: entered_id` (students)
7. Same approval flow as email/password

### Admin Verification Interface

**File**: `lib/verification_screen.dart`

**Features**:

- Lists all users with `status: 'pending'`
- Ordered by `createdAt` (newest first)
- Displays: Name, email, role, registration date
- Actions:
  - ✅ **Approve**: Sets `status: 'approved'`, triggers FCM notification
  - ❌ **Reject**: Sets `status: 'rejected'`, sends rejection notification

**Query**:

```dart
FirebaseFirestore.instance
  .collection('Users')
  .where('status', isEqualTo: 'pending')
  .orderBy('createdAt', descending: true)
  .snapshots();
```

### FCM Push Notifications

**Approval Notification Flow**:

1. Admin approves user in `VerificationScreen`
2. Firestore document updated: `status: 'approved'`
3. Cloud Function triggered on document update
4. Function reads `fcmToken` from user document
5. Sends push notification: "Your account has been approved!"
6. User's app receives notification → Refreshes auth state
7. Next app launch routes to appropriate dashboard

**Cloud Function** (see `cloud_functions_sample/index.js`):

```javascript
exports.notifyApproval = functions.firestore
  .document("Users/{userId}")
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    if (oldData.status === "pending" && newData.status === "approved") {
      const token = newData.fcmToken;
      if (token) {
        await admin.messaging().send({
          token: token,
          notification: {
            title: "Account Approved",
            body: "Welcome! Your account has been verified.",
          },
        });
      }
    }
  });
```

## 🖼️ Cloudinary Image Upload Integration

### Configuration

**Setup** (see `CLOUDINARY_SETUP.md`):

1. Create Cloudinary account at [cloudinary.com](https://cloudinary.com)
2. Obtain: Cloud Name, API Key, API Secret
3. Store credentials securely (do not commit to repository)

### Profile Picture Upload

**Flow**:

1. User navigates to profile screen
2. Taps profile picture → Image picker dialog
3. Selects from camera or gallery
4. Image uploaded to Cloudinary via HTTP POST
5. Returns secure URL: `https://res.cloudinary.com/{cloud_name}/image/upload/...`
6. URL saved to Firestore: `Users/{uid}.profilePictureUrl`
7. UI updates with new profile picture

**Implementation**:

```dart
// Upload to Cloudinary
final request = http.MultipartRequest('POST', cloudinaryUrl);
request.files.add(await http.MultipartFile.fromPath('file', imagePath));
request.fields['upload_preset'] = 'your_preset';

final response = await request.send();
final responseData = await response.stream.bytesToString();
final jsonData = json.decode(responseData);
final imageUrl = jsonData['secure_url'];

// Save to Firestore
await FirebaseFirestore.instance
  .collection('Users')
  .doc(userId)
  .update({'profilePictureUrl': imageUrl});
```

### Image Display

**Caching & Performance**:

- NetworkImage with automatic caching
- Cloudinary transformations for thumbnails: `/w_200,h_200,c_fill/`
- Fallback to default icon if URL invalid or network error

**Legacy Storage Migration**:

- Old system used Firebase Storage: `profilePictures/{studentDocId}.jpg`
- Migrated to Cloudinary for better CDN performance and transformations
- Existing Firebase Storage URLs still work (backwards compatible)

## Firestore Composite Index (status + createdAt)

`VerificationScreen` queries pending accounts ordered by creation time. Firestore requires a composite index for `where status == 'pending' orderBy createdAt DESC`.

Index Definition:

- Collection: `Users`
- Fields:
  - `status` (Ascending)
  - `createdAt` (Descending)

### Firebase Console Steps

1. Open Firebase Console → Firestore Database → Indexes tab.
2. Click "Add Index" (Composite section).
3. Collection ID: `Users`.
4. Fields:
   - `status` → Ascending
   - `createdAt` → Descending
5. No additional filters needed.
6. Save; build takes ~minutes. UI will show state "Building" then "Ready".
7. Re-run the app; the query error (FAILED_PRECONDITION) disappears.

### CLI Alternative

Create a file `firestore.indexes.json` at the project root:

```
{
  "indexes": [
    {
      "collectionGroup": "Users",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    }
  ]
}
```

Deploy:

```
firebase deploy --only firestore:indexes
```

(Requires global install: `npm i -g firebase-tools` and project initialization.)

Verification:
Use Firebase Console → Firestore → Indexes to confirm entry is present and active.

## 🧪 Testing Guide

### Manual Testing Checklist

#### Authentication Flow Tests

- [ ] Email/password registration creates pending user
- [ ] Social sign-in (Google) routes to credential completion
- [ ] Credential completion updates status to pending
- [ ] Admin approval changes status and grants dashboard access
- [ ] Rejected users see appropriate error message
- [ ] Multi-provider linking (Google + Facebook) works correctly

#### Attendance Recording Tests

- [ ] QR check-in creates AttendanceRecords document with checkInTime
- [ ] QR check-out updates same document with checkOutTime
- [ ] Location captured and reverse-geocoded to address
- [ ] Status correctly calculated (Present vs Late based on time)
- [ ] Duplicate scans on same day handled properly
- [ ] Wrong QR type (checkout before checkin) shows error

#### Teacher Dashboard Tests

- [ ] Teacher sees only their advisory students' records
- [ ] Check-in and check-out times display correctly (hh:mm a format)
- [ ] Status badges color-coded (green/orange/red)
- [ ] Records sorted by date descending
- [ ] Empty state shows when no records exist
- [ ] Real-time updates when new attendance recorded

#### Profile & Settings Tests

- [ ] Profile picture upload to Cloudinary succeeds
- [ ] Image URL saved to Firestore and displays correctly
- [ ] Profile information editable and persists
- [ ] Logout clears session and returns to login

### Automated Testing

**Run Unit Tests**:

```bash
flutter test
```

**Run Widget Tests**:

```bash
flutter test --tags widget
```

**Run Integration Tests**:

```bash
flutter test integration_test
# OR
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart
```

### Performance Testing

**Build Optimization**:

```bash
# Check app size
flutter build apk --release --analyze-size

# Profile mode with performance overlay
flutter run --profile --trace-skia
```

**Memory Profiling**:

- Open Flutter DevTools
- Monitor memory usage during QR scanning
- Check for image caching efficiency
- Verify Firestore query performance

## 🔧 Troubleshooting Common Issues

### QR Code & Camera Issues

**Camera Permission Denied**:

- Go to device Settings → Apps → Attendance App → Permissions
- Enable Camera permission
- Restart app

**QR Code Not Scanning**:

- Ensure adequate lighting
- Hold device steady 6-12 inches from QR code
- Verify QR code uses UTF-8 text encoding
- Check QR code has valid prefix (CHECKIN:, CHECKOUT:, etc.)

**Scanner Freezes or Crashes**:

```bash
flutter clean
flutter pub get
flutter run --release
```

### Location & GPS Issues

**Location Not Captured**:

- Enable GPS/Location Services in device settings
- Grant Location permission to app (Always or While Using)
- Ensure device has clear view of sky (for GPS accuracy)
- Wait 10-30 seconds for initial GPS fix

**Address Shows Coordinates Instead of Street Name**:

- Requires active internet connection for reverse geocoding
- Check network connectivity
- Geocoding may fail in remote areas with limited mapping data

**Map Not Loading**:

- Verify internet connection for OpenStreetMap tiles
- Check if device has VPN/firewall blocking map requests
- Try different map tile provider in `flutter_map` configuration

### Firestore & Authentication Issues

**Documents Not Appearing in Teacher Dashboard**:

- Verify student has `advisory` or `section` field matching teacher's advisory
- Check `adviserTeacherUid` matches teacher's Firebase UID
- Ensure AttendanceRecords documents have required fields
- Review debug logs in console for query results

**"User Not Found" After Login**:

- Ensure `Users/{uid}` document created during registration
- Verify `AuthService.hydrateUser()` called after sign-in
- Check Firebase Console → Authentication → Users for account existence

**Firestore Permission Denied**:

- Review `firestore.rules` for proper access controls
- Ensure custom claims set correctly (if using)
- Verify user authenticated before Firestore queries
- Check Security Rules test in Firebase Console

### Build & Deployment Issues

**Android Build Fails**:

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

**iOS Pod Installation Fails** (macOS):

```bash
cd ios
pod deintegrate
pod install --repo-update
cd ..
flutter run
```

**"Plugin Not Found" Errors**:

```bash
flutter pub cache repair
flutter pub get
```

**App Size Too Large**:

```bash
# Enable code shrinking
flutter build apk --release --shrink --split-per-abi
```

### Database Issues

**Composite Index Missing**:

- Error: `FAILED_PRECONDITION: query requires an index`
- Solution: Create index in Firebase Console (see Firebase Configuration section)
- Index builds take 2-10 minutes

**Old Data Structure Conflicts**:

- Migration script needed if changing document structure
- Use Firestore batch writes for bulk updates
- Consider versioning documents with `schemaVersion` field

### Performance Issues

**Slow Query Response**:

- Add composite indexes for complex queries
- Limit query results with `.limit(50)`
- Use pagination for large datasets
- Cache frequently accessed data with `shared_preferences`

**High Memory Usage**:

- Dispose of image controllers and listeners
- Use `const` constructors where possible
- Implement lazy loading for lists
- Clear scanner camera when leaving screen

## FAQ Additions

**Why an 'incomplete' status?** Prevents granting privileges or dashboard access before the user picks an enforced role and (for students) supplies Student ID.

**Can users change role after approval?** Should be restricted; implement admin-only role changes in future with proper auditing.

**Why not rely solely on custom claims?** Claims require backend issuance; storing `status` in Firestore enables UI logic and manual moderation while claims secure privileged operations.

Token & Claim Security:

- Clients cannot self‑assign admin/approved status; Firestore rules should verify `request.auth.token.admin` for privileged paths.
- Custom claims are signed; tampering with local UI or stored fields cannot forge them.

## Firestore / Functions Samples

Sample Cloud Functions (see `cloud_functions_sample/index.js`):

- `promoteToAdmin` callable: only existing admin claim can assign new admin.
- `notifyApproval` trigger: detects `pending -> approved` and sends FCM.

Sample Rules (see `firestore.rules.sample`): restrict writes requiring admin.

## Push Notifications (FCM)

Flow:

1. App requests notification permission; retrieves FCM token.
2. Token stored in `Users/{uid}.fcmToken`.
3. Approval trigger uses this token to send notification.
4. Token refresh events update Firestore automatically.

Notes:

- For iOS add APNs setup (cert or key) in Firebase console.
- For Android 13+ request notification runtime permission.
- Avoid sending sensitive data in notification payloads.

## Troubleshooting QR & Location

- Camera permission denied: Grant in system settings and restart the app.
- QR not detected: Ensure sufficient lighting and that code uses standard encoding (UTF-8 text).
- Location null: Check permissions or toggle GPS; first fix may appear after a short delay due to reverse geocoding.

## Future Enhancements

- Teacher/Admin dashboards (session creation, reports)
- Attendance anomaly detection (late/early patterns)
- Push notifications (class reminders)
- Export attendance ranges to CSV

---

For contribution questions about auth or QR flow, open an issue referencing the relevant section above.

## Folder Structure (simplified)

```
lib/
  main.dart
  core/               # constants, utilities
  features/
    attendance/
      data/
      domain/
      presentation/
    auth/
    session/
  widgets/
  config/
assets/
test/
```

## Running Tests

- Unit: `flutter test`
- Widget: `flutter test --tags widget`
- Integration: `flutter test integration_test`
  (Ensure integration_test/ directory exists)

## 📝 Code Style & Best Practices

### Linting & Formatting

**Format Code**:

```bash
dart format .
```

**Run Static Analysis**:

```bash
flutter analyze
```

**Configuration**: See `analysis_options.yaml` for linting rules

### Coding Conventions

**File Naming**:

- Snake case: `teacher_home.dart`, `auth_service.dart`
- Screens end with `_screen.dart`: `login_screen.dart`
- Services end with `_service.dart`: `location_service.dart`

**Class Naming**:

- PascalCase for classes: `TeacherHome`, `AuthService`
- Prefix private classes with underscore: `_TeacherHomeState`

**Variable Naming**:

- camelCase for variables and functions: `checkInTime`, `loadAttendanceRecords()`
- UPPER_CASE for constants: `const PRIMARY_COLOR = ...`

**State Management**:

- Use StatefulWidget for local UI state
- Centralize auth state in `model/user.dart`
- Avoid global mutable state where possible

**Async Patterns**:

```dart
// Use async/await
Future<void> loadData() async {
  try {
    final data = await fetchFromFirestore();
    setState(() => _data = data);
  } catch (e) {
    print('Error: $e');
  }
}
```

**Error Handling**:

- Wrap Firestore calls in try-catch
- Show user-friendly error messages
- Log errors for debugging: `print()` or logger package

### Git Workflow

**Branch Naming**:

- Features: `feat/add-teacher-dashboard`
- Bug fixes: `fix/qr-scanner-crash`
- Refactoring: `refactor/attendance-model`

**Commit Messages** (Conventional Commits):

```
feat: add check-in/out timestamp tracking
fix: resolve empty teacher attendance log
refactor: migrate to centralized AttendanceRecords collection
docs: update README with current system architecture
```

**Pull Request Guidelines**:

- Keep PRs focused on single feature/fix
- Include screenshots for UI changes
- Update documentation if changing public APIs
- Test on both Android and iOS before submitting

## CI/CD (placeholder)

Suggested steps:

- Install Flutter
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- Build artifacts (release)

## 🔒 Security & Privacy

### Data Protection

**Personal Information Handling**:

- User emails, names, and contact info encrypted in transit (HTTPS)
- Firebase Authentication handles password hashing and security
- No plaintext passwords stored anywhere in the system
- Profile pictures uploaded to secure CDN (Cloudinary)

**Location Data**:

- GPS coordinates captured only during check-in/out (with user consent)
- Location permission requested explicitly
- Coordinates stored in Firestore with access controls
- Reverse-geocoded addresses help verify attendance location
- Location data not shared with third parties

**Access Control**:

- Role-based authentication (student/teacher/admin)
- Firestore security rules enforce data isolation
- Students can only read/write their own attendance records
- Teachers access only their advisory students' data
- Admins have elevated privileges for user management

### Best Practices

**For Developers**:

- Never commit API keys, secrets, or credentials to repository
- Use environment variables for sensitive configuration
- Enable Firebase App Check to prevent API abuse
- Implement rate limiting for Cloud Functions
- Regular security audits of Firestore rules

**For Users**:

- Use strong passwords (8+ characters, mixed case, numbers, symbols)
- Enable two-factor authentication in Firebase Console (future feature)
- Log out from shared devices
- Report suspicious activity to administrators
- Keep app updated to latest version

**Data Retention**:

- Attendance records retained for academic year + 2 years (configurable)
- Deleted accounts trigger cascade deletion of associated data
- Anonymization option for historical analytics
- Compliance with local data protection regulations (GDPR, CCPA)

### Vulnerability Reporting

If you discover a security vulnerability:

1. **DO NOT** open a public GitHub issue
2. Email security concerns to: [security contact email]
3. Include detailed steps to reproduce
4. Allow reasonable time for fixes before disclosure
5. We'll credit you in security acknowledgments (optional)

### Compliance

- **Firebase**: SOC 2, ISO 27001 compliant infrastructure
- **Cloudinary**: GDPR and CCPA compliant image storage
- **Mobile Permissions**: Follows Android and iOS privacy guidelines
- **Data Encryption**: TLS 1.3 for all network communications

### Release Security

**Production Builds**:

```bash
# Obfuscate Dart code
flutter build apk --release --obfuscate --split-debug-info=build/debug

# Android App Bundle (recommended)
flutter build appbundle --release --obfuscate --split-debug-info=build/debug
```

**Code Signing**:

- Android: Keystore properly secured (not in repository)
- iOS: Distribution certificates managed via Apple Developer account
- Continuous monitoring of app signing integrity

## 🚀 Roadmap & Future Enhancements

### Planned Features

#### Phase 1: Core Improvements (Q1 2025)

- [ ] **Advanced Analytics Dashboard**

  - Attendance rate graphs and charts
  - Monthly/weekly attendance summaries
  - Late arrival pattern detection
  - Export reports to PDF/CSV

- [ ] **Enhanced Notifications**

  - Remind students to check in (geofence-triggered)
  - Alert teachers of low attendance rates
  - Parent notifications for student absences
  - Push notifications for event reminders

- [ ] **Attendance History Export**
  - CSV export for teacher records
  - Excel format with formatting
  - Date range filtering
  - Student-specific reports

#### Phase 2: Advanced Features (Q2 2025)

- [ ] **Offline Mode Enhancement**

  - Queue attendance records when offline
  - Auto-sync when connection restored
  - Conflict resolution for duplicate entries
  - Local database with SQLite

- [ ] **Parent Portal**

  - View child's attendance history
  - Receive absence notifications
  - Submit excuse letters digitally
  - Communication with teachers

- [ ] **Biometric Integration**

  - Fingerprint check-in (Android/iOS)
  - Face recognition backup
  - Prevent proxy attendance fraud

- [ ] **Multi-Tenant Support**
  - Support multiple schools/organizations
  - Tenant-specific branding
  - Isolated data per institution
  - Super-admin dashboard

#### Phase 3: Enterprise Features (Q3 2025)

- [ ] **Advanced Event Management**

  - Recurring events (daily, weekly, monthly)
  - Multiple check-in points per event
  - Capacity limits and registration
  - Waitlist management

- [ ] **Integration APIs**

  - RESTful API for third-party systems
  - Webhook support for attendance events
  - LMS integration (Moodle, Canvas)
  - Student information system sync

- [ ] **Reporting & Compliance**

  - Government attendance reporting formats
  - Custom report templates
  - Scheduled automated reports
  - Audit trail for all changes

- [ ] **Mobile App Enhancements**
  - Dark mode theme
  - Accessibility improvements (screen readers)
  - Localization (multiple languages)
  - Tablet-optimized layouts

### Known Limitations

- **Legacy Data**: Old `Student/{studentDocId}/Record` subcollection not automatically migrated
- **Query Limits**: Firestore `whereIn` limited to 10 items per query (chunking implemented)
- **Offline Conflicts**: Manual resolution needed if same record edited offline by multiple users
- **Image Storage**: Migration from Firebase Storage to Cloudinary ongoing
- **Web Support**: Limited testing on web platform (primarily mobile-focused)

### Technical Debt

- [ ] Refactor StatefulWidget to Riverpod/Provider for better state management
- [ ] Implement proper error logging service (Sentry/Crashlytics)
- [ ] Add comprehensive unit test coverage (currently minimal)
- [ ] Document API endpoints if backend service added
- [ ] Optimize Firestore security rules with custom claims
- [ ] Migrate remaining Firebase Storage references to Cloudinary

## 🤝 Contributing

We welcome contributions from the community! Here's how you can help:

### Getting Started

1. **Fork the repository**

   ```bash
   git clone https://github.com/YOUR_USERNAME/Attendance-App.git
   cd Attendance-App
   ```

2. **Create a feature branch**

   ```bash
   git checkout -b feat/your-feature-name
   ```

3. **Make your changes**

   - Follow coding conventions (see Code Style section)
   - Add comments for complex logic
   - Update documentation if needed

4. **Test thoroughly**

   ```bash
   flutter test
   flutter analyze
   dart format .
   ```

5. **Commit your changes**

   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

6. **Push and create Pull Request**
   ```bash
   git push origin feat/your-feature-name
   ```

### Contribution Guidelines

**Code Quality**:

- Keep PRs focused and small (< 500 lines when possible)
- Write descriptive commit messages
- Include screenshots for UI changes
- Ensure no breaking changes without discussion

**Testing**:

- Add unit tests for new business logic
- Test on both Android and iOS
- Verify QR scanning in different lighting conditions
- Check location accuracy in various environments

**Documentation**:

- Update README.md if adding features
- Add inline comments for complex algorithms
- Document API changes in commit messages
- Update CHANGELOG.md (if exists)

### Areas Needing Help

- 🐛 Bug fixes for reported issues
- 📱 iOS testing and optimization
- 🌐 Web platform support improvements
- 🧪 Increased test coverage
- 📖 Documentation improvements
- 🌍 Localization (translations)
- ♿ Accessibility enhancements

### Reporting Issues

When reporting bugs, include:

- Device model and OS version
- Flutter version (`flutter --version`)
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/screen recordings if applicable
- Relevant error logs or console output

### Feature Requests

For new features:

- Check existing issues/PRs first
- Explain use case and benefits
- Consider implementation complexity
- Discuss in Issues before starting large changes

## 📚 Additional Resources

### Documentation Links

- **Flutter Official Docs**: https://docs.flutter.dev/
- **Firebase for Flutter**: https://firebase.google.com/docs/flutter/setup
- **Firestore Data Modeling**: https://firebase.google.com/docs/firestore/data-model
- **Cloud Functions**: https://firebase.google.com/docs/functions
- **Cloudinary Flutter SDK**: https://cloudinary.com/documentation/flutter_integration
- **Mobile Scanner**: https://pub.dev/packages/mobile_scanner
- **Flutter Map**: https://pub.dev/packages/flutter_map

### Project-Specific Documentation

- **Firebase Setup**: See "Firebase Configuration" section above
- **Cloudinary Setup**: See `CLOUDINARY_SETUP.md`
- **Image URL Fixes**: See `IMAGE_URLS_FIXED.md`
- **Firestore Rules**: See `firestore.rules.sample`
- **Cloud Functions**: See `cloud_functions_sample/index.js`

### Learning Resources

**Flutter Development**:

- [Flutter Codelabs](https://docs.flutter.dev/codelabs) - Hands-on tutorials
- [Flutter Widget Catalog](https://docs.flutter.dev/ui/widgets) - UI components reference
- [Dart Language Tour](https://dart.dev/guides/language/language-tour) - Dart fundamentals

**Firebase Integration**:

- [Firebase YouTube Channel](https://www.youtube.com/firebase) - Official tutorials
- [FlutterFire Documentation](https://firebase.flutter.dev/) - Firebase for Flutter
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started) - Data security

**State Management**:

- [Flutter State Management](https://docs.flutter.dev/data-and-backend/state-mgmt) - Official guide
- [Provider Package](https://pub.dev/packages/provider) - Alternative state solution
- [Riverpod](https://riverpod.dev/) - Modern state management

### Community & Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/DeJure12705/Attendance-App/issues)
- **Flutter Community**: [flutter.dev/community](https://flutter.dev/community)
- **Firebase Support**: [firebase.google.com/support](https://firebase.google.com/support)
- **Stack Overflow**: Tag questions with `flutter`, `firebase`, `dart`

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### MIT License Summary

- ✅ Commercial use allowed
- ✅ Modification allowed
- ✅ Distribution allowed
- ✅ Private use allowed
- ℹ️ License and copyright notice required
- ❌ No liability or warranty provided

---

## 📧 Contact & Support

**Development Team**:

- **Project Lead**: Christian Misal
- **Technical Lead**: John Lyold C. Lozada
- **GitHub Repository**: [DeJure12705/Attendance-App](https://github.com/DeJure12705/Attendance-App)

**For Questions**:

- Open an issue on GitHub for bug reports or feature requests
- Check existing documentation before asking questions
- Include relevant details (OS, Flutter version, error logs)

**Acknowledgments**:

- Firebase team for comprehensive backend infrastructure
- Flutter community for excellent packages and support
- OpenStreetMap contributors for map tiles
- Cloudinary for reliable image hosting

---

**⭐ Star this repository if you find it helpful!**

**🔗 Related Tags**: `flutter` `dart` `firebase` `attendance-system` `qr-code` `mobile-app` `education` `firestore` `cloudinary` `geolocation` `authentication` `cross-platform`

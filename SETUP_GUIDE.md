# 📚 Attendance App Setup Guide

Complete step-by-step guide to set up and deploy the Flutter Attendance Management System.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Development Environment Setup](#development-environment-setup)
3. [Firebase Project Configuration](#firebase-project-configuration)
4. [Cloudinary Setup](#cloudinary-setup)
5. [Project Installation](#project-installation)
6. [Database Initialization](#database-initialization)
7. [User Roles & Permissions](#user-roles--permissions)
8. [Testing the System](#testing-the-system)
9. [Deployment](#deployment)
10. [Troubleshooting](#troubleshooting)

---

## 🔧 Prerequisites

### Required Software

| Software           | Version | Download Link                                                 |
| ------------------ | ------- | ------------------------------------------------------------- |
| Flutter SDK        | 3.10+   | [flutter.dev](https://docs.flutter.dev/get-started/install)   |
| Dart SDK           | 3.10+   | Included with Flutter                                         |
| Android Studio     | Latest  | [developer.android.com](https://developer.android.com/studio) |
| VS Code (Optional) | Latest  | [code.visualstudio.com](https://code.visualstudio.com/)       |
| Git                | Latest  | [git-scm.com](https://git-scm.com/)                           |
| Node.js            | 16+     | [nodejs.org](https://nodejs.org/) (for Firebase CLI)          |

### Required Accounts

- **Firebase Account**: [console.firebase.google.com](https://console.firebase.google.com/)
- **Cloudinary Account**: [cloudinary.com/users/register/free](https://cloudinary.com/users/register/free)
- **Google Cloud Console**: [console.cloud.google.com](https://console.cloud.google.com/) (for OAuth)

### Development Machine Requirements

- **OS**: Windows 10/11, macOS 10.14+, or Linux
- **RAM**: Minimum 8GB (16GB recommended)
- **Storage**: 10GB free space
- **Internet**: Stable connection for package downloads

---

## 🛠️ Development Environment Setup

### 1. Install Flutter SDK

#### Windows:

```powershell
# Download Flutter SDK and extract to C:\src\flutter
# Add to PATH: C:\src\flutter\bin

# Verify installation
flutter doctor
```

#### macOS/Linux:

```bash
# Download and extract Flutter
cd ~
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Add to .bashrc or .zshrc for persistence
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc

# Verify installation
flutter doctor
```

### 2. Install Android Studio

1. Download from [developer.android.com/studio](https://developer.android.com/studio)
2. Install Android SDK (minimum SDK 21)
3. Install Android Emulator
4. Accept Android licenses:
   ```bash
   flutter doctor --android-licenses
   ```

### 3. Install Flutter & Dart Plugins

**Android Studio:**

- File → Settings → Plugins
- Search "Flutter" → Install
- Search "Dart" → Install
- Restart IDE

**VS Code:**

- Extensions → Search "Flutter" → Install
- Extensions → Search "Dart" → Install

### 4. Verify Setup

```bash
flutter doctor -v
```

Expected output should show ✓ for Flutter, Android, and IDE.

---

## 🔥 Firebase Project Configuration

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `attendance-app` (or your preferred name)
4. Disable Google Analytics (optional for this project)
5. Click **"Create project"**

### Step 2: Register Android App

1. In Firebase Console, click **Android icon** (⚙️)
2. Enter Android package name: `com.example.attendanceapp`
   - Find in `android/app/build.gradle` under `applicationId`
3. Enter App nickname: `Attendance App Android`
4. Leave SHA-1 empty for now (we'll add it later)
5. Click **"Register app"**
6. Download `google-services.json`
7. Place it in: `android/app/google-services.json`

### Step 3: Add SHA-1 Fingerprint (Required for Google Sign-In)

#### Generate Debug SHA-1:

```bash
cd android
./gradlew signingReport

# On Windows:
gradlew.bat signingReport
```

Copy the SHA-1 and SHA-256 values.

#### Add to Firebase:

1. Firebase Console → Project Settings → Android App
2. Click **"Add fingerprint"**
3. Paste SHA-1 → Save
4. Repeat for SHA-256
5. Download new `google-services.json` and replace the old one

### Step 4: Register iOS App (Optional)

1. Click **iOS icon** (⚙️)
2. Enter iOS bundle ID: `com.example.attendanceapp`
   - Find in `ios/Runner.xcodeproj/project.pbxproj`
3. Download `GoogleService-Info.plist`
4. Place in: `ios/Runner/GoogleService-Info.plist`

### Step 5: Enable Authentication Methods

1. Firebase Console → **Authentication** → **Sign-in method**
2. Enable the following providers:

#### Email/Password:

- Click **"Email/Password"** → Enable → Save

#### Google Sign-In:

- Click **"Google"** → Enable
- Enter support email → Save
- Go to Google Cloud Console
- APIs & Services → Credentials
- Configure OAuth consent screen
- Add authorized domains: `yourdomain.com`

#### Facebook Login (Optional):

- Click **"Facebook"** → Enable
- Create Facebook App at [developers.facebook.com](https://developers.facebook.com/)
- Copy App ID and App Secret → Paste in Firebase
- Add OAuth redirect URI to Facebook app settings

### Step 6: Create Firestore Database

1. Firebase Console → **Firestore Database** → **Create database**
2. Select **Production mode** (we'll configure rules later)
3. Choose location closest to your users (e.g., `us-central1`)
4. Click **"Enable"**

### Step 7: Set Up Firestore Security Rules

1. Firestore Database → **Rules** tab
2. Replace with the following rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper function to check authentication
    function isAuthenticated() {
      return request.auth != null;
    }

    // Helper function to check if user is admin
    function isAdmin() {
      return isAuthenticated() &&
             get(/databases/$(database)/documents/Users/$(request.auth.uid)).data.role == 'admin';
    }

    // Helper function to check if user is teacher
    function isTeacher() {
      return isAuthenticated() &&
             get(/databases/$(database)/documents/Users/$(request.auth.uid)).data.role == 'teacher';
    }

    // Users collection
    match /Users/{userId} {
      // Users can read their own document
      allow read: if isAuthenticated() && request.auth.uid == userId;

      // Users can update their own profile (except role and status)
      allow update: if isAuthenticated() &&
                       request.auth.uid == userId &&
                       !request.resource.data.diff(resource.data).affectedKeys().hasAny(['role', 'status']);

      // Admins and teachers can read all users
      allow read: if isAdmin() || isTeacher();

      // Admins can write any user document
      allow write: if isAdmin();

      // New users can create their own pending account
      allow create: if isAuthenticated() &&
                       request.auth.uid == userId &&
                       request.resource.data.status in ['pending', 'incomplete'];
    }

    // Student collection
    match /Student/{studentId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin() || isTeacher();

      // Student subcollections (legacy attendance records)
      match /Record/{recordId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated();
        allow update: if isAuthenticated();
      }
    }

    // AttendanceRecords collection (centralized)
    match /AttendanceRecords/{recordId} {
      // Anyone authenticated can read
      allow read: if isAuthenticated();

      // Students can create their own records
      allow create: if isAuthenticated() &&
                       request.resource.data.studentId == request.auth.uid;

      // Students can update their own records (check-out)
      allow update: if isAuthenticated() &&
                       resource.data.studentId == request.auth.uid;

      // Teachers and admins can write any record
      allow write: if isAdmin() || isTeacher();
    }

    // Events collection
    match /Events/{eventId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin() || isTeacher();
    }
  }
}
```

3. Click **"Publish"**

### Step 8: Create Firestore Indexes

Required for complex queries:

1. Firestore Database → **Indexes** tab → **Create Index**

#### Index 1: Users by Status and CreatedAt

- Collection: `Users`
- Fields:
  - `status` → Ascending
  - `createdAt` → Descending
- Query scope: Collection
- Click **"Create"**

#### Index 2: AttendanceRecords by Advisory and Date

- Collection: `AttendanceRecords`
- Fields:
  - `advisory` → Ascending
  - `date` → Descending
- Query scope: Collection
- Click **"Create"**

**Alternative: Using Firebase CLI**

Create `firestore.indexes.json` in project root:

```json
{
  "indexes": [
    {
      "collectionGroup": "Users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "AttendanceRecords",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "advisory", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    }
  ]
}
```

Deploy indexes:

```bash
npm install -g firebase-tools
firebase login
firebase init firestore
firebase deploy --only firestore:indexes
```

### Step 9: Enable Firebase Storage (Optional)

1. Firebase Console → **Storage** → **Get started**
2. Start in **Production mode**
3. Choose same location as Firestore
4. **Note**: System now uses Cloudinary for images, but Storage can remain as backup

---

## ☁️ Cloudinary Setup

### Step 1: Create Cloudinary Account

1. Go to [cloudinary.com/users/register/free](https://cloudinary.com/users/register/free)
2. Sign up for free account
3. Verify email

### Step 2: Get API Credentials

1. Dashboard → Account Details
2. Copy:
   - **Cloud Name**: `dxxxxxxxx`
   - **API Key**: `123456789012345`
   - **API Secret**: `abcdefghijklmnopqrstuvwxyz123`

### Step 3: Create Upload Preset

1. Settings → Upload tab → **Upload presets**
2. Click **"Add upload preset"**
3. Configuration:
   - **Preset name**: `attendance_profile_pictures`
   - **Signing mode**: Unsigned
   - **Folder**: `attendance_app/profiles`
   - **Access mode**: Public
   - **Overwrite**: Yes
   - **Format**: Auto
   - **Transformation**: Limit dimensions (800x800 max)
4. Click **"Save"**

### Step 4: Configure in App

Create `lib/config/cloudinary_config.dart`:

```dart
class CloudinaryConfig {
  static const String cloudName = 'YOUR_CLOUD_NAME';
  static const String uploadPreset = 'attendance_profile_pictures';
  static const String apiKey = 'YOUR_API_KEY';

  static String get uploadUrl =>
    'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}
```

**⚠️ Security Note**: Never commit API secrets to Git. Use environment variables in production.

---

## 📦 Project Installation

### Step 1: Clone Repository

```bash
git clone https://github.com/DeJure12705/Attendance-App.git
cd Attendance-App
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Verify Configuration Files

Ensure the following files exist:

- ✅ `android/app/google-services.json`
- ✅ `ios/Runner/GoogleService-Info.plist` (iOS only)
- ✅ `lib/firebase_options.dart` (auto-generated)

If `firebase_options.dart` is missing, generate it:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for Flutter
flutterfire configure
```

Follow the prompts to select your Firebase project.

### Step 4: Update Package Names (Optional)

If you want to change the app package name:

**Android:**
Edit `android/app/build.gradle`:

```gradle
defaultConfig {
    applicationId "com.yourcompany.attendanceapp"
}
```

**iOS:**
Edit `ios/Runner.xcodeproj/project.pbxproj` and change bundle identifier.

**Update Firebase:**

- Re-register apps in Firebase Console with new package names
- Download new config files

---

## 🗄️ Database Initialization

### Step 1: Create Initial Admin Account

The first admin must be created manually in Firebase Console:

1. Firebase Console → **Authentication** → **Users** tab
2. Click **"Add user"**
3. Enter:
   - **Email**: `admin@yourschool.edu`
   - **Password**: `SecurePassword123!`
4. Click **"Add user"**
5. Copy the generated **UID**

### Step 2: Create Admin User Document

1. Firestore Database → **Users** collection
2. Click **"Add document"**
3. Document ID: Paste the UID from step 1
4. Add fields:

```javascript
{
  uid: "paste_uid_here",
  email: "admin@yourschool.edu",
  role: "admin",
  status: "approved",
  fullName: "System Administrator",
  providers: ["password"],
  createdAt: [Click "Timestamp" → "Now"],
  address: "School Main Office",
  contactNumber: "+1234567890"
}
```

5. Click **"Save"**

### Step 3: Create Sample Student Document

1. Firestore Database → **Student** collection
2. Add document with ID: `2024001`

```javascript
{
  id: "2024001",
  studentId: "2024001",
  fullName: "John Doe",
  email: "john.doe@student.edu",
  advisory: "Grade 10-A",
  section: "Grade 10-A",
  adviserTeacherUid: "", // Will be filled when teacher registers
  createdAt: [Timestamp]
}
```

### Step 4: Create Sample Teacher Document

1. Authentication → Add teacher user with email/password
2. Copy UID
3. Firestore → **Users** collection → Add document:

```javascript
{
  uid: "teacher_uid_here",
  email: "teacher@yourschool.edu",
  role: "teacher",
  status: "approved",
  fullName: "Jane Smith",
  advisory: "Grade 10-A",
  providers: ["password"],
  createdAt: [Timestamp],
  contactNumber: "+1234567890",
  teacherId: "T2024001"
}
```

---

## 👥 User Roles & Permissions

### Admin Role

**Capabilities:**

- ✅ Approve/reject ALL user registrations (students, teachers, admins)
- ✅ Create and manage attendance events
- ✅ View system-wide analytics
- ✅ Access all features without restrictions
- ✅ Modify user roles and permissions

**How to Grant Admin Role:**

1. Firebase Console → Firestore → Users collection
2. Find user document → Edit
3. Change `role` field to `"admin"`
4. Change `status` field to `"approved"`

### Teacher Role

**Capabilities:**

- ✅ Approve/reject ONLY students in their advisory section
- ✅ View attendance logs for their advisory students
- ✅ Create attendance events
- ✅ Access verification screen (filtered to their students)
- ❌ Cannot approve teachers or admins
- ❌ Cannot approve students from other advisory sections

**Advisory Assignment:**
Teachers must have an `advisory` field in their Users document:

```javascript
{
  advisory: "Grade 10-A", // Must match student advisory exactly
  role: "teacher",
  status: "approved"
}
```

**Validation Logic:**

- When teacher clicks "Approve" on a student:
  1. System checks if user is a student (not teacher/admin)
  2. System checks if student's advisory matches teacher's advisory
  3. If both pass → Approval succeeds
  4. If either fails → Error message shown

### Student Role

**Capabilities:**

- ✅ Scan QR codes for check-in/check-out
- ✅ View personal attendance calendar
- ✅ Update profile information
- ✅ Upload profile picture
- ❌ Cannot access verification screen
- ❌ Cannot create events

**Registration Flow:**

1. Student registers with email/password or social provider
2. Selects "Student" role
3. Enters Student ID
4. Document created with `status: "pending"`
5. Waits for teacher/admin approval
6. Once approved, gains access to dashboard

---

## 🧪 Testing the System

### Test Scenario 1: Admin Approval Workflow

**Setup:**

1. Create test student account (email: `student@test.com`)
2. Set status to `"pending"`

**Test Steps:**

1. Login as admin
2. Navigate to "Verify Accounts"
3. Verify you see the pending student
4. Click "Approve"
5. Check Firestore → User should have `status: "approved"`
6. Student should now be able to login and access dashboard

**Expected Result:** ✅ Admin can approve any user without restrictions

### Test Scenario 2: Teacher Approval (Same Advisory)

**Setup:**

1. Create teacher with `advisory: "Grade 10-A"`
2. Create student with `advisory: "Grade 10-A"` and `status: "pending"`

**Test Steps:**

1. Login as teacher
2. Navigate to "Verify"
3. Verify you see the student from Grade 10-A
4. Click "Approve"
5. Check Firestore → Student approved

**Expected Result:** ✅ Teacher successfully approves student in their advisory

### Test Scenario 3: Teacher Approval (Different Advisory)

**Setup:**

1. Teacher has `advisory: "Grade 10-A"`
2. Student has `advisory: "Grade 11-B"` and `status: "pending"`

**Test Steps:**

1. Login as teacher
2. Navigate to "Verify"
3. Verify student from Grade 11-B does NOT appear in list
4. (If manually triggered) System blocks approval with error message

**Expected Result:** ✅ Teacher cannot see or approve students from other advisory sections

### Test Scenario 4: QR Code Attendance

**Setup:**

1. Admin/Teacher creates event with check-in QR code
2. Student account approved and logged in

**Test Steps:**

1. Open student app
2. Navigate to "Today" screen
3. Tap "Scan QR Code"
4. Point camera at check-in QR code
5. Verify success message appears
6. Check Firestore → AttendanceRecords should have new document with `checkInTime`
7. Scan check-out QR code
8. Verify same document updated with `checkOutTime`

**Expected Result:** ✅ Attendance recorded with both timestamps

### Test Scenario 5: Teacher Dashboard

**Setup:**

1. Students have checked in/out
2. Teacher logged in

**Test Steps:**

1. Navigate to "Dashboard" → "Attendance Log"
2. Verify you see only students from your advisory
3. Check that check-in and check-out times are displayed
4. Verify status badges (Present/Late/Absent) are color-coded

**Expected Result:** ✅ Teacher sees accurate attendance data for their students

---

## 🚀 Deployment

### Android Deployment

#### Step 1: Generate Signing Key

```bash
keytool -genkey -v -keystore ~/attendance-app-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias attendance
```

Enter keystore password and details when prompted.

#### Step 2: Configure Signing

Create `android/key.properties`:

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=attendance
storeFile=/path/to/attendance-app-key.jks
```

Edit `android/app/build.gradle`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

#### Step 3: Build Release APK

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug
```

Or build App Bundle for Play Store:

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

#### Step 4: Upload to Google Play Console

1. Create Google Play Developer account ($25 one-time fee)
2. Create new app
3. Upload App Bundle
4. Fill in store listing details
5. Submit for review

### iOS Deployment (macOS only)

#### Step 1: Configure Xcode

```bash
open ios/Runner.xcworkspace
```

1. Select Runner → General
2. Update Bundle Identifier
3. Select Team (requires Apple Developer account - $99/year)
4. Configure signing certificates

#### Step 2: Build Release IPA

```bash
flutter build ipa --release
```

#### Step 3: Upload to App Store Connect

1. Open Xcode
2. Product → Archive
3. Window → Organizer
4. Select archive → Distribute App
5. Follow prompts to upload to App Store Connect
6. Submit for review in App Store Connect

### Web Deployment

#### Build for Web:

```bash
flutter build web --release
```

#### Deploy to Firebase Hosting:

```bash
firebase init hosting
# Select 'build/web' as public directory
# Configure as single-page app: Yes

firebase deploy --only hosting
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. "CONFIGURATION_NOT_FOUND" Error

**Cause:** Missing or incorrect Firebase configuration files

**Solution:**

- Verify `google-services.json` exists in `android/app/`
- Verify package name matches Firebase Console
- Re-download config files after adding SHA fingerprints
- Run `flutter clean && flutter pub get`

#### 2. QR Scanner Not Working

**Cause:** Missing camera permissions

**Solution:**

- Android: Check `AndroidManifest.xml` has camera permission
- iOS: Check `Info.plist` has camera usage description
- Grant permissions in device settings

#### 3. Firestore Query Error: "FAILED_PRECONDITION"

**Cause:** Missing composite index

**Solution:**

- Check Firebase Console → Firestore → Indexes
- Create required indexes (see Step 8 of Firebase setup)
- Wait 2-5 minutes for index to build

#### 4. Teacher Cannot See Students

**Cause:** Advisory mismatch or missing advisory field

**Solution:**

- Verify teacher's `advisory` field exactly matches student's `advisory`
- Check for trailing spaces or case differences
- Ensure both documents have advisory field populated

#### 5. Google Sign-In Fails

**Cause:** Missing SHA-1 fingerprint or OAuth misconfiguration

**Solution:**

- Add SHA-1 and SHA-256 to Firebase Console
- Re-download `google-services.json`
- Configure OAuth consent screen in Google Cloud Console
- Enable Google Sign-In in Firebase Authentication

#### 6. Image Upload Fails

**Cause:** Cloudinary configuration issues

**Solution:**

- Verify Cloud Name and Upload Preset are correct
- Check upload preset is set to "Unsigned"
- Ensure internet connection is stable
- Check Cloudinary dashboard for upload logs

### Debug Mode

Run app in debug mode with verbose logging:

```bash
flutter run --verbose
```

Check logs:

```bash
# Android
flutter logs

# iOS
flutter logs
```

### Reset Database (Development Only)

**⚠️ Warning: This deletes all data**

1. Firebase Console → Firestore Database
2. Click "..." menu → Delete database
3. Confirm deletion
4. Create new database
5. Re-run database initialization steps

---

## 📞 Support

### Getting Help

- **GitHub Issues**: [github.com/DeJure12705/Attendance-App/issues](https://github.com/DeJure12705/Attendance-App/issues)
- **Documentation**: See `README.md` for detailed feature documentation
- **Flutter Docs**: [docs.flutter.dev](https://docs.flutter.dev/)
- **Firebase Docs**: [firebase.google.com/docs](https://firebase.google.com/docs)

### Reporting Bugs

Include the following in bug reports:

- Flutter version (`flutter --version`)
- Device/OS information
- Steps to reproduce
- Error logs
- Screenshots if applicable

---

## ✅ Setup Checklist

Use this checklist to track your progress:

### Environment Setup

- [ ] Flutter SDK installed and verified
- [ ] Android Studio installed with SDK
- [ ] IDE plugins (Flutter/Dart) installed
- [ ] Physical device or emulator configured

### Firebase Setup

- [ ] Firebase project created
- [ ] Android app registered
- [ ] `google-services.json` added to project
- [ ] SHA-1/SHA-256 fingerprints added
- [ ] Authentication providers enabled
- [ ] Firestore database created
- [ ] Security rules configured
- [ ] Composite indexes created

### Cloudinary Setup

- [ ] Cloudinary account created
- [ ] Upload preset configured
- [ ] API credentials obtained
- [ ] Configuration added to app

### Project Setup

- [ ] Repository cloned
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Firebase configured (`flutterfire configure`)
- [ ] Config files in correct locations

### Database Setup

- [ ] Initial admin account created
- [ ] Admin user document created in Firestore
- [ ] Sample student/teacher documents created
- [ ] Advisory fields properly configured

### Testing

- [ ] Admin can approve all users
- [ ] Teacher can approve only their advisory students
- [ ] Student can register and login
- [ ] QR code scanning works
- [ ] Attendance records saved correctly
- [ ] Teacher dashboard displays correct data

### Deployment (Optional)

- [ ] Signing keys generated
- [ ] Release build successful
- [ ] App uploaded to store
- [ ] Store listing completed

---

## 🎉 Congratulations!

Your Attendance App is now set up and ready to use!

**Next Steps:**

1. Create real user accounts for your school
2. Configure advisory sections for teachers
3. Generate QR codes for events
4. Train staff on system usage
5. Monitor Firebase Console for usage and errors

For questions or contributions, visit the [GitHub repository](https://github.com/DeJure12705/Attendance-App).

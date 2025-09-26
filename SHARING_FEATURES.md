# Real-Time Task Sharing Features

This document describes the real-time task sharing functionality implemented in the Collab Todo app.

## Overview

The app now supports sharing tasks via links that allow recipients to view and edit tasks in real-time, with changes automatically synchronized to all participants.

## Features

### 1. Share Link Generation
- Tasks can be shared via generated links
- **Mobile App Links**: `collabtodo://task/{taskId}` (opens directly in app)
- **Universal Links**: `https://collabtodo.page.link/task/{taskId}` (fallback for web)
- Links work for both authenticated and non-authenticated users

### 2. Real-Time Updates
- All changes to shared tasks are synchronized in real-time using Firestore listeners
- Changes made by any participant are immediately visible to all others
- No need to refresh or reload the app

### 3. Sharing Methods

#### Via App Share Sheet
- Share tasks through the device's native share functionality
- Supports sharing via email, SMS, social media, etc.
- Includes formatted text with task details and share link

#### Via Email
- Direct email sharing with pre-filled subject and body
- Supports multiple email addresses (comma-separated)
- Professional email formatting with task information

#### Via External Apps
- Share through any app that supports text sharing
- Copy link to clipboard functionality

### 4. Shared Task Screen
- Dedicated screen for non-authenticated users
- View and edit task details
- Real-time updates without requiring account creation
- Clean, intuitive interface

### 5. Deep Link Handling
- Automatic deep link detection when app is opened via shared link
- Seamless navigation to shared task
- Works when app is closed, in background, or already open

## Technical Implementation

### Dependencies Added
- `url_launcher`: For opening email clients and external apps
- `uni_links`: For handling deep links and URL schemes

### Key Components

#### ShareService
- Handles all sharing functionality
- Supports multiple sharing methods
- Generates formatted share text

#### SharedTaskScreen
- Real-time task viewing and editing
- Firestore stream listeners for live updates
- No authentication required

#### Deep Link Handling
- **Custom URL Scheme**: `collabtodo://task/{taskId}` (opens directly in mobile app)
- **Universal Links**: `https://collabtodo.page.link/task/{taskId}` (web fallback)
- Android manifest configuration for intent filters
- iOS Info.plist configuration for URL schemes
- Automatic routing to shared task screen

### Real-Time Synchronization
- Uses Firestore's real-time listeners
- `streamTask()` method provides live updates
- Changes are immediately reflected across all clients

## Usage

### For Task Owners
1. Open any task in the app
2. Tap the share button (three dots menu)
3. Choose sharing method:
   - "Share via App" for general sharing
   - "Share via Email" for direct email sharing
4. Recipients receive a link to view/edit the task

### For Recipients
1. Click the shared link
2. App opens automatically (or install from store)
3. View and edit task in real-time
4. Changes are synchronized to all participants

## Configuration

### Android Deep Links
The Android manifest includes intent filters for both custom URL schemes and universal links:
```xml
<!-- Custom URL scheme for direct app opening -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="collabtodo" />
</intent-filter>
<!-- Universal links for web fallback -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https"
          android:host="collabtodo.page.link" />
</intent-filter>
```

### iOS Deep Links
The iOS Info.plist includes URL scheme configuration:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>collabtodo.deeplink</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>collabtodo</string>
        </array>
    </dict>
</array>
```

### URL Schemes
- **Mobile App**: `collabtodo://task/{taskId}` (opens directly in app)
- **Universal Link**: `https://collabtodo.page.link/task/{taskId}` (web fallback)

## Security Considerations

- Tasks are accessible via direct links (no authentication required for viewing)
- Consider implementing access controls if needed
- Share links contain task IDs - ensure proper validation
- Firestore security rules should be configured appropriately

## Future Enhancements

- Access control and permissions
- Share link expiration
- User authentication for shared tasks
- Activity logging and change tracking
- Push notifications for changes

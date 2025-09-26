# Mobile App Deep Linking Guide

## 🎯 **Problem Solved: Links Now Open in App, Not Browser!**

The shared links now use custom URL schemes (`collabtodo://task/{taskId}`) that open directly in the mobile app instead of the browser.

## 📱 **How to Test Mobile Deep Linking**

### **Step 1: Install the App**
1. **Install the APK** on your Android device:
   ```
   File location: build/app/outputs/flutter-apk/app-release.apk
   ```
2. **Transfer the APK** to your phone and install it
3. **Open the app** and create an account

### **Step 2: Create and Share a Task**
1. **Create a task** in the app
2. **Tap the share button** (three dots menu)
3. **Choose sharing method** (email, SMS, etc.)
4. **Copy the generated link** - it will look like:
   ```
   collabtodo://task/eAgH8CV4fhraSllz2jSN
   ```

### **Step 3: Test the Deep Link**
1. **Send the link** to yourself via email or SMS
2. **Click the link** on your phone
3. **The app should open automatically** and show the shared task!

## 🔧 **How It Works**

### **Custom URL Scheme**
- **Format**: `collabtodo://task/{taskId}`
- **Behavior**: Opens directly in the Collab Todo app
- **Fallback**: If app not installed, shows "App not found" message

### **Android Configuration**
The `AndroidManifest.xml` includes:
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="collabtodo" />
</intent-filter>
```

### **iOS Configuration**
The `Info.plist` includes:
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

## 🧪 **Test Scenarios**

### **Scenario 1: App Installed**
1. Share a task link
2. Click the link
3. ✅ **App opens automatically**
4. ✅ **Shows the shared task**
5. ✅ **Allows real-time editing**

### **Scenario 2: App Not Installed**
1. Share a task link
2. Click the link
3. ❌ **Shows "App not found" or similar message**
4. 💡 **User needs to install the app first**

### **Scenario 3: Real-Time Collaboration**
1. **Person A**: Shares a task link
2. **Person B**: Clicks the link (app opens)
3. **Both users**: Can edit the task simultaneously
4. **Changes sync**: In real-time between both users

## 📧 **Sharing Methods**

### **Email Sharing**
- **Subject**: "Shared Task: {taskTitle}"
- **Body**: Includes task details and deep link
- **Link**: `collabtodo://task/{taskId}`

### **SMS Sharing**
- **Message**: Includes task details and deep link
- **Link**: `collabtodo://task/{taskId}`

### **App Share Sheet**
- **Native sharing**: Uses device's share functionality
- **Works with**: Any app that supports text sharing

## 🚀 **Production Deployment**

### **For Production:**
1. **Replace localhost** with your production domain
2. **Update deep link handling** for production URLs
3. **Test on real devices** with production builds

### **Example Production Setup:**
```dart
// In task_service.dart
String generateTaskShareLink(String taskId) {
  // For production, you might want to use both:
  // 1. Custom scheme for app opening
  // 2. Universal link for web fallback
  
  return 'collabtodo://task/$taskId';
}
```

## 🐛 **Troubleshooting**

### **Link Not Opening App?**
- ✅ **Check**: App is installed on device
- ✅ **Check**: Deep link configuration is correct
- ✅ **Check**: Link format is `collabtodo://task/{taskId}`

### **App Opens But Shows Wrong Task?**
- ✅ **Check**: Task ID in URL is correct
- ✅ **Check**: Task exists in Firestore
- ✅ **Check**: Deep link parsing is working

### **Real-Time Updates Not Working?**
- ✅ **Check**: Internet connection
- ✅ **Check**: Firebase configuration
- ✅ **Check**: Firestore security rules

## 📱 **Mobile App Features**

### **What Works in Mobile App:**
- ✅ **Deep link opening** from shared links
- ✅ **Real-time task editing** and collaboration
- ✅ **No authentication required** for shared tasks
- ✅ **Instant sync** with all participants
- ✅ **Cross-platform** (Android & iOS)

### **What Doesn't Work:**
- ❌ **Web browser fallback** (by design - app only)
- ❌ **Opening in browser** (custom scheme prevents this)

## 🎉 **Success!**

Your shared links now:
- ✅ **Open directly in the mobile app**
- ✅ **Don't open in browser**
- ✅ **Enable real-time collaboration**
- ✅ **Work across all sharing methods**

The deep linking is now properly configured for mobile app usage!

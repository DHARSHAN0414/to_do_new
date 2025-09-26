# Testing Real-Time Task Sharing

## 🎯 How to Test the Sharing Functionality

### 1. **Start the App**
```bash
flutter run -d chrome --web-port=8080
```
The app will be available at: `http://localhost:8080`

### 2. **Create a Test Task**
1. Open the app in your browser
2. Sign in or create an account
3. Click "Add Task" to create a new task
4. Give it a title like "Test Meeting" and description "Discuss project updates"

### 3. **Share the Task**
1. Click the three dots menu (⋮) on any task card
2. Select "Share via App" or "Share via Email"
3. Copy the generated link

### 4. **Test the Shared Link**
The generated link will look like:
```
http://localhost:8080/#/task/eAgH8CV4fhraSllz2jSN
```

**To test:**
1. **Copy the link** from the share dialog
2. **Open a new browser tab** (or incognito window)
3. **Paste the link** in the address bar
4. **Press Enter** - the app should open and show the shared task

### 5. **Test Real-Time Updates**
1. **Open the shared task** in one browser tab
2. **Open the original app** in another browser tab
3. **Make changes** to the task in either tab
4. **Watch the changes appear** in real-time in the other tab!

## 🔗 **What the Shared Link Does**

When someone clicks the shared link:

✅ **Opens the Collab Todo app** (if running in browser)
✅ **Shows the specific task** without requiring login
✅ **Allows real-time editing** of the task
✅ **Syncs changes instantly** to all viewers
✅ **Works on any device** with a web browser

## 📱 **Mobile App Deep Links**

For mobile apps, the system also supports:
- **Custom URL scheme**: `collabtodo://task/{taskId}`
- **Android**: Configured in AndroidManifest.xml
- **iOS**: Configured in Info.plist

## 🚀 **Production Deployment**

For production, replace the localhost URL in `task_service.dart`:
```dart
// Change this line:
return 'http://localhost:8080/#/task/$taskId';

// To your deployed URL:
return 'https://yourdomain.com/#/task/$taskId';
```

## 🧪 **Test Scenarios**

### Scenario 1: Email Sharing
1. Create a task
2. Share via email
3. Click the link in the email
4. Verify it opens the task

### Scenario 2: Real-Time Collaboration
1. Share a task with a colleague
2. Both open the shared link
3. One person edits the task
4. Verify the other person sees changes instantly

### Scenario 3: Multiple Devices
1. Open the app on your phone
2. Share a task
3. Open the link on your computer
4. Edit from both devices simultaneously

## 🐛 **Troubleshooting**

### Link Not Working?
- Make sure the app is running on `http://localhost:8080`
- Check that the task ID in the URL is correct
- Try refreshing the page

### Real-Time Updates Not Working?
- Check your internet connection
- Verify Firebase is properly configured
- Look for errors in the browser console

### Mobile App Not Opening?
- Ensure the app is installed on the device
- Check that deep link configuration is correct
- Test with the custom URL scheme: `collabtodo://task/{taskId}`

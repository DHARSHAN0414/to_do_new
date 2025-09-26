# Collab Todo
A modern, collaborative to-do application built with Flutter and Firebase. Share tasks with others, manage your productivity, and stay organized with real-time synchronization across all your devices.

# Features  
- 🔐 Authentication: Secure sign-in with Google OAuth  
- 📱 Cross-Platform: Runs on Android and Windows  
- 🤝 Real-time Collaboration: Share tasks with others and see updates instantly  
- 🎨 Modern UI: Beautiful, responsive design with dark/light theme support  
- 📊 Task Management: Create, edit, complete, and delete tasks   
- 🔗 Deep Linking: Share tasks via custom URLs and deep links  
- ☁️ Cloud Sync: All data synchronized across devices using Firebase  
- 🎯 Smart Organization: Categorized task views and filtering   
- ⚡ Performance: Optimized with lazy loading and efficient state management  

## Quick Start
### Prerequisites
- Flutter SDK (3.7.2 or higher)
- Dart SDK (included with Flutter)
- Firebase Project (for backend services)
- Firebase SDK
- Git (for version control)
Installation
1.	Clone the repository
```bash
git clone https://github.com/DHARSHAN0414/to_do_new.git
cd collab_todo
````
2. Install Dependencies
```bash
flutter pub get
```
3.	Set up Firebase  
- Create a new Firebase project at Firebase Console  
- Enable Authentication (Google Sign-In)  
- Enable Firestore Database  

5.	Configure Firebase for your platform
- The `firebase (options.dart)` file should be automatically generated
- If not, run: `flutterfire configure`

# Running the App
Android
```bash
flutter run
```
🏗️ Project Structure
```
lib/
├── main.dart)                 # App entry point and theme configuration
├── firebase (options.dart)     # Firebase configuration
├── models/
│   └── task.dart)            # Task data model
├── screens/
│   ├── home (screen.dart)     # Main task list screen
│   ├── sign (in (screen.dart)  # Authentication screen
│   ├── profile (screen.dart)  # User profile management
│   ├── task (details (screen.dart) # Task editing screen
│   └── shared (task (screen.dart)  # Shared task viewing
├── services/
│   ├── task (service.dart)    # Firebase task operations
│   └── share (service.dart)   # Task sharing functionality
├── viewmodels/
│   ├── auth (viewmodel.dart)  # Authentication state management
│   └── task (viewmodel.dart)  # Task state management
└── widgets/
    ├── app (button.dart)      # Custom button components
    ├── input (components.dart) # Input field components
    ├── input (field.dart)     # Reusable input field
    ├── task (card.dart)       # Task display card
    └── user (avatar.dart)     # User profile avatar
```
## Configuration
Firebase Setup
1.	Authentication
- Enable Google Sign-In in Firebase Console
- Add your app's SHA-1 fingerprint for Android
- Configure OAuth consent screen
2.	Firestore Database
- Create database in production mode
- Set up security rules for user data protection
- Configure indexes for optimal query performance

## Security
- Authentication: Secure Google OAuth integration
- Data Protection: Firestore security rules protect user data
- Deep Links: Validated URL schemes prevent malicious links

## Troubleshooting
### Common Issues
#### Firebase connection errors
- Verify Firebase configuration files are in correct locations
- Check Firebase project settings and enabled services
- Ensure internet connectivity
#### Build errors
- Run `flutter clean` and `flutter pub get`
- Check Flutter and Dart SDK versions
- Verify platform-specific dependencies
#### Authentication issues
- Verify Google Sign-In is properly configured
- Check OAuth consent screen settings
- Ensure SHA-1 fingerprints are added for Android
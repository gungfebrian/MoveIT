# MoveIt 🏋️

AI-powered fitness tracking app with real-time pose detection for counting exercises like pull-ups and push-ups.

## Features

- **Real-time Pose Detection** - Uses Google ML Kit for accurate body tracking
- **Rep Counter** - Automatically counts your exercise repetitions
- **Streak Tracking** - Keep your workout consistency
- **Goal Setting** - Set and track your fitness goals
- **Firebase Auth** - Secure login with Google Sign-In
- **Cloud Sync** - Your data synced across devices with Firestore

## Tech Stack

- **Framework**: Flutter (Dart)
- **Backend**: Firebase (Auth, Firestore)
- **ML**: Google ML Kit Pose Detection
- **State Management**: Provider

## Getting Started

### Prerequisites

- Flutter SDK ^3.9.2
- Firebase project setup
- Android Studio / Xcode

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/MoveIt.git
cd MoveIt
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Firebase
   - Add your `google-services.json` (Android) to `android/app/`
   - Add your `GoogleService-Info.plist` (iOS) to `ios/Runner/`

4. Run the app
```bash
flutter run
```

## Project Structure

```
lib/
├── Detection/       # Exercise detection algorithms
├── screens/         # App screens (Home, Camera, Workouts)
├── services/        # Business logic (Auth, Streak, Goals)
├── widgets/         # Reusable UI components
└── main.dart        # App entry point
```

## License

This project is for educational purposes.

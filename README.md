# Brief 📰

[![Flutter](https://img.shields.io/badge/Flutter-3.33+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth/Firestore-FFCA28?logo=firebase&logoColor=white)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Brief** is a modern, minimalist news application built with Flutter and Firebase. It offers a premium, streamlined reading experience with a focus on high-quality content delivery, localized news feed, and social interactivity.

<p align="center">
  <img src="assets/icon.png" width="150" alt="Brief Logo">
</p>

## 🚀 Features

- **Personalized News Feed**: A vertical, swipeable feed tailored to your interests.
- **Creator Dashboard**: Dedicated interface for authors to publish and manage articles.
- **Instagram-Style Interactions**: Interactive "Double-tap to like" with smooth heart-pop animations.
- **Multi-lingual Support**: Full localization support (English & Telugu) including localized time-ago timestamps.
- **Location-Based Filtering**: Filter news by Global, National, State, or District levels.
- **Premium UI/UX**: Minimalist design with dark mode, modern typography, and smooth transitions.

## 🛠️ Tech Stack

- **Frontend**: Flutter SDK (v3.33+)
- **State Management**: Provider
- **Backend Service**: Firebase (Authentication, Cloud Firestore, Cloud Storage)
- **Localizations**: Flutter Intl (ARB files)
- **Dependencies**: `timeago`, `sensors_plus`, `url_launcher`, `google_fonts`

## 📱 Platform Support

- **Android**: Android 5.0 (API 21) or higher.
- **iOS**: iOS 13.0 or higher.

## 💎 Technical Wins

### 1. High-Fidelity Social Animations
The "Double-tap to Like" feature was implemented using a custom `AnimationController` to trigger a heart scale and opacity sequence. It uses a `Stack` to overlay the animation without interrupting the scroll performance.

### 2. Deep Localization (Globalization)
Beyond simple text translation, **Brief** features specialized localization for Telugu, including custom logic for the `timeago` package to ensure that relational timestamps (e.g., "5 minutes ago") feel native and accurate in regional languages.

### 3. Modern Flutter Standards
The entire codebase has been modernized to follow Flutter 3.33+ standards, migrating away from deprecated APIs like `.withOpacity()` to the more precise `.withValues(alpha: )` standard.

## 📦 Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/Brief-News-App.git
   cd Brief-News-App
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**:
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/).
   - Enable **Authentication** (Email/Password), **Cloud Firestore**, and **Cloud Storage**.
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) and place them in their respective directories.

4. **Run the app**:
   ```bash
   flutter run
   ```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
*Created with ❤️ for modern readers.*

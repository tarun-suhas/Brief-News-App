# 📱 Flutter News App — Vibecoding Spec

## 🧠 Goal
Build a **minimalist, modern news app** using:
- Flutter
- Firebase (Auth, Firestore, Storage)
- Cursor (AI-assisted coding)

---

# 👥 User Roles

## 1. User
- Signup (name, email, password)
- Login
- View swipeable news feed
- Filter news by category

## 2. Creator
- Login only (no signup UI)
- Create and publish news

---

# 🧱 Core Features

## 📰 News Feed
- Vertical swipe (like reels / Way2News)
- Full-screen cards
- Image background + gradient overlay
- Title + short content
- Breaking news badge

## ✍️ Creator Panel
- Create news with:
  - Title
  - Content
  - Image
  - Category
  - Breaking flag

## 🔍 Filters
- Categories:
  - All
  - Politics
  - Sports
  - Tech
  - Local

---

# 📂 Project Structure
```text
lib/
├── core/
│   ├── constants/
│   └── l10n/
├── models/
├── services/
├── features/
│   ├── auth/
│   ├── news_feed/
│   ├── creator/
│   └── filters/
├── widgets/
└── main.dart
```

---

# ⚡ Vibecoding Commands (for Cursor)

## 🔹 1. Project Setup
- Create a Flutter project using clean architecture.
- Add dependencies:
  - `firebase_core`
  - `firebase_auth`
  - `cloud_firestore`
  - `firebase_storage`
  - `provider`
- Set up folders: `models`, `services`, `features` (`auth`, `news_feed`, `creator`).
- Design should be minimalist with smooth animations.

---

## 🔹 2. Authentication System
- Implement Firebase Authentication.
- Features:
  - User signup (name, email, password)
  - User login
  - Creator login (email + password only)
- Store user data in Firestore:
  - Collection: `users`
  - Fields: `uid`, `name`, `email`, `role` (user / creator)
- After login:
  - If role = user → navigate to News Feed
  - If role = creator → navigate to Creator Dashboard

---

## 🔹 3. News Model
- Create a `News` model.
- Fields: `id`, `title`, `content`, `imageUrl`, `category`, `isBreaking` (bool), `createdAt`, `createdBy`.
- Include `fromMap()` and `toMap()`.

---

## 🔹 4. Swipeable News Feed UI
- Create a vertical swipe news feed using `PageView.builder`.
- Requirements:
  - Vertical scrolling
  - Full-screen cards
  - Background image
  - Gradient overlay
  - Title at bottom
  - Short content preview
  - Breaking badge (if true)
- Add: Smooth fade animations, Slide transitions.
- Keep UI clean and modern.

---

## 🔹 5. Firestore News Service
- Create `NewsService`.
- Fetch data from:
  - Collection: `news`
  - Query: Order by `createdAt` (descending)
- Use `StreamBuilder` for real-time updates.
- Convert documents to `News` model.

---

## 🔹 6. Creator Dashboard
- Create a Creator Dashboard screen.
- Form fields:
  - Title (text)
  - Content (multiline)
  - Category (dropdown)
  - Image upload
  - Breaking toggle
- On submit:
  - Upload image to Firebase Storage
  - Get download URL
  - Save news to Firestore
- Add: Loading indicator, Success message.

---

## 🔹 7. Category Filters
- Add category filters to the news feed.
- UI: Horizontal chips (`All`, `Politics`, `Sports`, `Tech`, `Local`).
- Behavior: Filter Firestore query based on selected category, Update feed dynamically.

---

## 🔹 8. Animations
- Add subtle animations: Fade-in text, Smooth transitions, Slight scale effect on swipe.
- Use `AnimatedOpacity`, `AnimatedContainer`.
- Keep animations minimal and fast.

---

## 🔹 9. Engineering Practices
- **Localization:** Set up localization using `flutter_localizations` and `intl`. Externalize text strings; avoid hardcoding strings directly in the UI.
- **Constants Management:** Store all app-wide assets and styles in `lib/core/constants/`:
  - `colors.dart`: Define all app colors and theme palettes here.
  - `text_styles.dart`: Define standardized typography usage.
  - `strings.dart`: Store fixed string constants, labels, and config keys.
  - `images.dart`: Define robust reference paths for all local image and icon assets.
- **Reusability:** Always reference these centralized constants (colors, text styles, strings, images) instead of inline or duplicated values.

---

# 🔥 Firebase Setup

## 🗃️ Firestore Structure

### `users` collection
```
users/
  {uid}:
    name
    email
    role (user / creator)
```

### `news` collection
```
news/
  {newsId}:
    title
    content
    imageUrl
    category
    isBreaking
    createdAt (timestamp)
    createdBy (uid)
```

---

## 🔐 Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /news/{newsId} {
      allow read: if true;
      allow write: if request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "creator";
    }

    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

---

# 🖼️ Image Upload Flow

## Steps:
1. Pick image from device
2. Upload to Firebase Storage
3. Get download URL
4. Save URL in Firestore

## Cursor Prompt
Implement image upload using Firebase Storage.
Steps:
- pick image from gallery
- upload to storage path: `news_images/{timestamp}.jpg`
- get download URL
- return URL for Firestore saving

---

# 🎨 UI Guidelines

- Minimalist design
- Dark mode preferred
- Clean typography
- Smooth animations
- Avoid clutter

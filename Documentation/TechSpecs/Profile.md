
# Tone Tribe Profile Page Technical Specification (Wireframe-Aligned)

## 1. Overview
The profile page is the user’s personal hub, displaying their profile picture, username, a settings button, favorite songs, and playlists. The design is clean and minimal, with a focus on visual elements and easy navigation.

---

## 2. Functional Requirements

### 2.1 User Profile Display

- **Profile Picture**
  - Large, circular avatar at the top left.
  - Default: Generic avatar if unset.
  - Size: ~120x120px, circular (ClipOval).
  - Tappable for image upload/change (gallery/camera).
- **Username**
  - Displayed to the right of the profile picture.
  - Style: Large, bold, modern sans-serif (e.g., Roboto, 24px).
- **User Info**
  - A secondary line (e.g., user ID or short bio) below the username, smaller font, muted color.
- **Settings Button**
  - Gear icon at the top right, horizontally aligned with the username.
  - Tappable, navigates to `/settings`.

---

### 2.2 Favorite Songs

- **Section Title:** "Favorite Songs" (bold, left-aligned).
- **Display**
  - Three square placeholders/thumbnails in a horizontal row.
  - Each: 100x100px (approx.), with a thin border.
  - The middle square is highlighted (e.g., purple border).
  - No song metadata (title/artist) shown in this view.
- **Interaction**
  - Tapping a song can open a detail or play preview (future).
- **Fallback**
  - If no favorite songs, show empty squares.

---

### 2.3 Your Playlists

- **Section Title:** "Your Playlists" (bold, left-aligned).
- **Display**
  - 2x2 grid of square playlist placeholders (100x100px each).
  - No playlist names or metadata shown in this view.
  - If fewer than 4 playlists, show empty squares.
- **Interaction**
  - Tapping a playlist navigates to `/playlist/:id`.

---

### 2.4 Navigation Bar

- **Bottom Navigation**
  - Three icons: Home (filled), Chat (outline), Profile (outline).
  - Home icon is filled to indicate the current page.
  - Centered horizontally at the bottom.
  - Tappable to navigate between main app sections.

---

## 3. Non-Functional Requirements

- **Performance:** Page load <2s, lazy-load images.
- **Responsiveness:** Support 320px–1024px widths, use MediaQuery.
- **Security:** OAuth 2.0 for music APIs, secure storage for tokens.
- **Offline Support:** Cache profile and music data locally.

---

## 4. UI/UX Specifications

- **Layout**
  - Use `SingleChildScrollView` for vertical scrolling.
  - Top: Profile picture, username, settings icon (horizontal row).
  - Below: "Favorite Songs" section with 3 squares.
  - Below: "Your Playlists" section with 2x2 grid.
  - Bottom: Navigation bar with 3 icons.
- **Styling**
  - Colors: Light background, black/gray text/icons, accent color for highlights (e.g., purple for selection).
  - Spacing: 16px padding/margins.
  - Fonts: Roboto or similar.
- **Interactivity**
  - Profile picture: Tap to change.
  - Settings: Tap to navigate.
  - Playlists/Songs: Tap to navigate (future).
- **No visible music app logo or bio in this version.**

---

## 5. Technical Stack

- **Framework:** Flutter (Dart)
- **Backend:** Firebase Auth, Firestore, Firebase Storage
- **APIs:** Spotify/Apple Music for song/playlist data
- **Packages:** `cached_network_image`, `http`, `flutter_secure_storage`, `provider` or `flutter_bloc`

---

## 6. Data Model

- **User Profile (Firestore)**
  ```json
  {
    "uid": "string",
    "username": "string",
    "profile_picture_url": "string"
  }
  ```
- **Songs:** List of album art URLs.
- **Playlists:** List of cover art URLs.

---

## 7. Implementation Notes

- Use `provider` for state management.
- Use `Navigator` for page transitions.
- Handle API errors gracefully.
- Use named routes: `/profile`, `/settings`, `/playlist/:id`.

---

## 8. Future Considerations

- Add bio and music app logo.
- Show song/playlist metadata.
- Add sharing/following features.

---


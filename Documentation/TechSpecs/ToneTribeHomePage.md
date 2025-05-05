# ToneTribe Technical Specification for Homescreen and Tribe Search Feature (Flutter + Firebase Edition)

## 1. Overview

ToneTribe is a mobile/web app built with Flutter that allows users to create, join, and curate collaborative playlists in tribes. Playlists are exportable to Spotify and Apple Music. The homescreen displays user-specific recommendations and tribe access, while the search feature allows discovery by tags, genres, and tribe names.

## 2. System Architecture

### Updated Architecture

* **Frontend**: Flutter (Web, iOS, Android), deployed via Firebase Hosting
* **Backend**: Firebase Cloud Functions (Node.js) for business logic
* **Database**: Firestore (NoSQL, real-time sync)
* **Authentication**: Firebase Auth (Google, Apple, Spotify via OAuth)
* **Search & Caching**: Firestore queries with cached tag suggestions via Cloud Functions and Firestore TTL
* **Third-party APIs**: Spotify & Apple Music for login & playlist sync

### Architecture Diagram (Updated)

* Flutter App → Firebase Auth (OAuth)
* Flutter App ↔ Firestore (User, Tribe, Tag, Recommendation)
* Flutter App ↔ Cloud Functions (Search, Recommendations, Join Requests)
* Firebase Hosting serves static Flutter Web App
* Firebase Storage (optional): For tribe icons/media
* Cloud Functions ↔ Spotify / Apple Music APIs

## 3. Homescreen

### UI/UX Requirements (Flutter)

**Layout:**

* **Header**: App logo, menu (My Tribes, Create, Search, Profile, Logout)
* **Hero Section**: "Welcome, Alex!" and a **Create Tribe** button
* **Recommended Tribes**: Carousel (3–5), based on Firestore recommendation scores
* **My Tribes**: Grid/ListView of user's tribes (name, tags, members)
* **Quick Actions**: Buttons for Search Tribes, Join, View Playlists
* **Footer**: About, Terms, Contact links

**Design Considerations:**

* Responsive for mobile and desktop (Flutter widgets)
* Accessible (semantic labels, high contrast mode)
* Personalized using user history and linked music accounts

### Functionality

* On load: Fetch user profile, tribes, recommendations from Firestore
* Spotify/Apple not linked: Show prompt to link
* Lazy loading: For performance on larger tribe lists
* Error handling: Show fallback UI if queries fail

### Homescreen Flow

1. User navigates to homescreen
2. Fetch user profile and tribes via Firestore
3. Fetch recommendations using Cloud Function
4. Check if Spotify/Apple is linked
5. Render UI (hero, tribe cards, carousel)

## 4. Tribe Search Feature

### UI/UX Requirements

**Search Interface:**

* **Search Bar**: Text input ("Search tribes by name or genre")
* **Filters**: Dropdowns (tags, privacy, platform)
* **Result Grid**: Tribe cards (name, tags, member count, platforms)
* **Pagination**: Infinite scroll or "Load More"
* **Join Button**: Public = Join; Restricted = Request

**Additional Features:**

* Autocomplete suggestions (via Firestore and Cloud Functions)
* Mobile-first layout with collapsible filters
* Keyboard navigation and screen reader support

### Functionality

* Search query: Call Cloud Function to filter tribes in Firestore
* Caching: Cloud Function stores recent searches with TTL
* Autocomplete: Cloud Function returns tag matches
* Join: Writes to `TribeMembership` collection (status: pending/approved)
* Sorting: By relevance (score), members, date

### Tribe Search Flow

1. User enters query or filters
2. Flutter calls search Cloud Function
3. If cached: Return results
4. Else: Query Firestore and cache
5. Render tribe cards
6. On join click:

   * Public: Write approved membership
   * Restricted: Write pending request

## 5. Data Model (Firestore)

### Collections & Documents

* **users/{userId}**

  * email, username, spotifyLinked, appleLinked, createdAt
* **tribes/{tribeId}**

  * name, description, creatorId, privacy, platforms, createdAt
* **tribe\_memberships/{userId}\_{tribeId}**

  * userId, tribeId, role (Lead/Member), status, joinedAt
* **tags/{tagId}**

  * name (e.g., Rock, Jazz)
* **tribe\_tags/{tribeId}\_{tagId}**

  * tribeId, tagId
* **recommendations/{userId}\_{tribeId}**

  * score (float), createdAt

## 6. API & Firebase Functions

### Homescreen

* **GET user/profile**: Fetch from `users/{userId}`
* **GET user/tribes**: Query `tribe_memberships` where userId == current
* **GET tribes/recommended**: Cloud Function calculates score using tags/activity

### Tribe Search

* **GET tribes/search**: Cloud Function filters `tribes` collection by text, tags, platform, privacy

  * Params: `q`, `tags`, `privacy`, `platforms`, `sort`, `page`
* **GET tags/autocomplete**: Returns tag matches from `tags` collection
* **POST tribes/\:id/join**: Cloud Function creates entry in `tribe_memberships` with appropriate status

## 7. Technical Requirements

* **Scalability**: Firebase handles scaling automatically
* **Security**: Firestore rules + Firebase Auth (JWT, OAuth)
* **Performance**: Search results < 300ms (cached), homescreen < 200ms
* **Compatibility**: Modern mobile and web via Flutter
* **Caching**: TTL for search and recommendations via Cloud Functions (5-10 mins)

## 8. Implementation Notes

### Frontend (Flutter)

* Use `FutureBuilder`/`StreamBuilder` for Firestore data
* Use `flutter_typeahead` for autocomplete
* Carousel via `carousel_slider`, infinite scroll via `infinite_scroll_pagination`
* Local storage (Hive/SharedPrefs) for user cache

### Backend (Cloud Functions)

* Written in Node.js, triggered via HTTPS callable functions
* Use Firestore's composite indexes for optimized search
* Caching via Firestore + TTL fields or Firebase Extensions

### Testing

* Unit tests for Cloud Functions (e.g., join, search)
* Widget tests for homescreen and tribe card components
* Integration tests: user flow for login, join tribe, search

## 9. Future Enhancements

* AI-based tribe recommendation using listening history (Spotify API)
* Advanced filters: activity level, regional tribes
* Tribe chat and notification system
* Analytics via Firebase Analytics

## 10. References

* [Flutter](https://flutter.dev)
* [Firebase Documentation](https://firebase.google.com/docs)
* [Spotify Web API](https://developer.spotify.com/documentation/web-api)
* [Apple Music API](https://developer.apple.com/documentation/applemusicapi)

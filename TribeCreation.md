# ToneTribe Technical Specification for Tribe Creation

## 1. Overview

ToneTribe is a web-based platform that enables users to form "tribes" to collaboratively curate playlists based on shared musical interests. These playlists are exported to external streaming services (Spotify, Apple Music) via their respective APIs. The platform focuses on tribe creation, playlist curation, and third-party integration, with no internal media playback or storage. This specification details the tribe creation process, system architecture, and data model.

## 2. System Architecture

The platform uses a microservices architecture deployed on AWS for scalability and reliability. Key components include:

* **Frontend**: React.js with Tailwind CSS for a responsive UI, hosted via AWS CloudFront CDN.
* **Backend**: Node.js with Express.js, handling API requests and business logic.
* **Database**: PostgreSQL for relational data (users, tribes, playlists).
* **Authentication**: OAuth 2.0 with JWT for secure user access, supporting Google, Spotify, and Apple Music login for seamless third-party integration.

### Third-Party APIs:

* **Spotify API**: For playlist creation and track management (requires user OAuth authentication).

* **Apple Music API**: For playlist creation and track management (requires MusicKit authentication).

* **API Gateway**: AWS API Gateway for routing, rate-limiting, and securing API calls.

* **Real-Time Features**: WebSocket (via Socket.io) for live collaboration on playlist curation within tribes.

### Architecture Diagram

**Diagram: System Architecture**

* **User Device**: Browser running React app, communicates with API Gateway.
* **API Gateway**: Routes requests to microservices (User Service, Tribe Service, Playlist Service).
* **User Service**: Manages user profiles, authentication (connects to PostgreSQL).
* **Tribe Service**: Handles tribe creation, membership, and settings (connects to PostgreSQL).
* **Playlist Service**: Manages playlist curation and export to Spotify/Apple Music (connects to PostgreSQL and third-party APIs).
* **WebSocket Service**: Enables real-time playlist collaboration and notifications.
* **Database (PostgreSQL)**: Stores user, tribe, and playlist metadata.
* **External Services**: Spotify API and Apple Music API for playlist publishing.
* **Cloud Infrastructure (AWS)**: Hosts all services with auto-scaling for load balancing.

## 3. Tribe Creation

Tribes are groups of users (5–100 members) who collaborate to curate playlists based on a shared musical theme (e.g., "Indie Rock Vibes"). Tribes have a creator (Tribe Lead), members, and settings for privacy and platform integration.

### Tribe Creation Process

1. **User Initiation**: A logged-in user selects "Create Tribe" from the dashboard.

2. **Configuration**: User defines:

   * Tribe name (unique, max 50 characters).
   * Description (mission or theme, max 500 characters).
   * Tags (e.g., "Rock", "Electronic") for discoverability.
   * Privacy settings: Public (discoverable), Private (invite-only), or Restricted (requires approval).
   * Preferred platforms: Spotify, Apple Music, or both for playlist export.

3. **Authentication Check**: User must have linked Spotify and/or Apple Music accounts (via OAuth) if exporting to those platforms.

4. **Validation**: Backend validates inputs (unique name, valid tags, authenticated accounts).

5. **Creation**: Tribe is saved to the database, and the creator is assigned as Tribe Lead.

6. **Initialization**: A default playlist is created in the tribe, linked to the selected platforms.

7. **Joining**: Users can discover public tribes via search, request to join restricted tribes, or be invited to private tribes.

8. **Management**: Tribe Lead can approve members, manage settings, and initiate playlist exports.

### Flowchart: Tribe Creation

**Diagram: Tribe Creation Flowchart**

* **Start**: User clicks "Create Tribe".
* **Step 1**: Input tribe details (name, description, tags, privacy, platforms).
* **Decision 1**: Are Spotify/Apple Music accounts linked for selected platforms?

  * No: Prompt user to authenticate via OAuth.
  * Yes: Proceed.
* **Decision 2**: Are inputs valid? (Backend checks for duplicates, format).

  * Yes: Save tribe to database, assign user as Tribe Lead, create default playlist.
  * No: Return error message to user.
* **Step 2**: Tribe created, user redirected to tribe dashboard.
* **End**: Tribe is live, users can join and collaborate on playlists.

## 4. Data Model

The database schema supports tribe creation, membership, and playlist management.

### Diagram: Entity-Relationship Diagram (ERD)

* **User**: (`user_id` \[PK], `email`, `username`, `password_hash`, `spotify_token`, `apple_music_token`, `created_at`)
* **Tribe**: (`tribe_id` \[PK], `name`, `description`, `creator_id` \[FK: User], `privacy` \[public/private/restricted], `platforms` \[spotify/apple\_music/both], `created_at`)
* **Tribe\_Membership**: (`user_id` \[FK: User], `tribe_id` \[FK: Tribe], `role` \[Lead/Member], `status` \[pending/approved], `joined_at`)
* **Playlist**: (`playlist_id` \[PK], `tribe_id` \[FK: Tribe], `name`, `spotify_playlist_id`, `apple_music_playlist_id`, `created_at`)
* **Playlist\_Track**: (`track_id` \[PK], `playlist_id` \[FK: Playlist], `spotify_track_id`, `apple_music_track_id`, `added_by` \[FK: User], `added_at`)

## 5. Technical Requirements

* **Scalability**: AWS ECS for backend services, RDS for PostgreSQL with read replicas.
* **Security**: HTTPS, encrypted tokens (stored in database), and JWT for authentication.
* **Performance**: API response time < 200ms, playlist export time < 2s.
* **Compatibility**: Supports modern browsers (Chrome, Firefox, Safari) and mobile devices.
* **API Rate Limits**: Handle Spotify (10 requests/second) and Apple Music (varies) rate limits with queuing.

## 6. API Endpoints

Key endpoints for tribe creation and management:

* `POST /api/tribes`: Create a new tribe (requires authentication, linked Spotify/Apple Music accounts).

  * **Payload**: `{ name, description, tags, privacy, platforms }`
  * **Response**: `{ tribe_id, name, description, created_at }`

* `GET /api/tribes`: List public tribes or user’s tribes.

* `POST /api/tribes/:id/join`: Request to join a tribe (public or with invite).

* `POST /api/tribes/:id/playlists`: Create a new playlist in a tribe.

* `POST /api/playlists/:id/export`: Export playlist to Spotify/Apple Music.

## 7. Third-Party Integration

### Spotify API:

* **Authentication**: OAuth 2.0, user authorizes ToneTribe to create playlists.
* **Endpoints Used**: `/playlists` (create), `/playlists/{id}/tracks` (add tracks).
* **Storage**: Store `spotify_playlist_id` and `spotify_track_id` in database.

### Apple Music API:

* **Authentication**: MusicKit JWT, user authorizes ToneTribe.
* **Endpoints Used**: `/playlists` (create), `/playlists/{id}/tracks` (add tracks).
* **Storage**: Store `apple_music_playlist_id` and `apple_music_track_id` in database.

### Error Handling:

* Handle token expiration, rate limits, and API errors with retries and user notifications.

## 8. Implementation Notes

* **Frontend**: React components for tribe creation form, platform authentication prompts, and tribe dashboard.
* **Backend**: Implement services as Docker containers, use async queues for API calls to Spotify/Apple Music.
* **Testing**: Unit tests for API endpoints, integration tests for tribe creation and playlist export.
* **Future Enhancements**: Add playlist analytics (e.g., track popularity), support for more platforms (e.g., YouTube Music).

## 9. References

* [Spotify Web API](https://developer.spotify.com/documentation/web-api)
* [Apple Music API](https://developer.apple.com/documentation/applemusicapi)
* [Microservices Architecture: AWS Best Practices](https://aws.amazon.com/microservices/)

ToneTribe Technical Specification for Homescreen and Tribe Search Feature
1. Overview
ToneTribe is a web-based platform for creating and managing tribes that collaboratively curate playlists for export to Spotify and Apple Music. The homescreen is the primary entry point, providing users with personalized tribe recommendations, quick access to their tribes, and navigation to key features. The tribe search feature enables users to discover public tribes or search for tribes by name, tags, or themes. This specification details the UI/UX, backend logic, API endpoints, and data model for these features.
2. System Architecture
The homescreen and tribe search feature leverage ToneTribe’s existing microservices architecture on AWS:

Frontend: React.js with Tailwind CSS for responsive UI, hosted via AWS CloudFront CDN.
Backend: Node.js with Express.js for API requests and business logic.
Database: PostgreSQL for storing user, tribe, and playlist metadata.
Authentication: OAuth 2.0 with JWT, supporting Google, Spotify, and Apple Music login.
API Gateway: AWS API Gateway for routing and securing API calls.
Caching: Redis for caching search results and homescreen recommendations to reduce database load.
Third-Party APIs: Spotify and Apple Music APIs for user authentication and playlist integration (used indirectly for homescreen if tribes display linked playlists).

Architecture Diagram
Diagram: System Architecture for Homescreen and Search

User Device: Browser running React app, communicates with API Gateway.
API Gateway: Routes requests to User Service, Tribe Service, and Search Service.
User Service: Fetches user profile and linked accounts (PostgreSQL).
Tribe Service: Retrieves user’s tribes and recommendations (PostgreSQL).
Search Service: Handles tribe search queries, caches results (Redis, PostgreSQL).
Database (PostgreSQL): Stores user, tribe, and metadata.
Cache (Redis): Stores frequently accessed search results and recommendations.
External Services: Spotify/Apple Music APIs for authentication (if users link accounts on homescreen).
Cloud Infrastructure (AWS): Hosts services with auto-scaling.

3. Homescreen
The homescreen is the user’s dashboard after login, designed to engage users and provide quick access to tribes and features.
UI/UX Requirements

Layout:
Header: Logo, navigation bar (Homescreen, My Tribes, Create Tribe, Profile, Logout).
Hero Section: Welcome message with user’s username (e.g., "Welcome, Alex!") and a call-to-action (e.g., "Create a Tribe" button).
Recommended Tribes: Carousel of 3–5 public tribes based on user’s tags or activity (if available).
My Tribes: Grid of user’s joined tribes (name, description, member count), with links to tribe dashboards.
Quick Actions: Buttons for "Search Tribes", "Join a Tribe", and "View Playlists".
Footer: Links to About, Terms, and Contact pages.


Responsive Design: Optimized for desktop and mobile (flexbox/grid with Tailwind CSS).
Accessibility: ARIA labels, keyboard navigation, and high-contrast mode support.
Personalization: Display tribes based on user’s previous interactions or linked Spotify/Apple Music preferences (if authenticated).

Functionality

User Data Fetch: On load, fetch user’s profile, joined tribes, and recommended tribes via API.
Dynamic Rendering: Use React components to render tribe cards and carousels, with lazy loading for performance.
Authentication Check: Prompt users to link Spotify/Apple Music accounts if not connected (for playlist export functionality).
Error Handling: Display fallback UI (e.g., "No tribes found") if API calls fail.

Homescreen Flowchart
Diagram: Homescreen Loading Flow

Start: User navigates to homescreen (post-login).
Step 1: Frontend sends API requests for user profile, joined tribes, and recommendations.
Decision: Are API responses successful?
Yes: Render hero, tribe grid, and carousel.
No: Display error message or fallback UI.


Step 2: Check for linked Spotify/Apple Music accounts.
If not linked: Show prompt to connect accounts.


End: Homescreen fully loaded, user can interact.

4. Tribe Search Feature
The tribe search feature allows users to find public tribes or request access to restricted tribes by searching via keywords, tags, or filters.
UI/UX Requirements

Search Interface:
Search Bar: Text input with placeholder (e.g., "Search tribes by name or genre").
Filters: Dropdowns for tags (e.g., "Rock", "Jazz"), privacy (public/restricted), and platform (Spotify/Apple Music).
Results Display: Grid of tribe cards (name, description, tags, member count, platform icons).
Pagination: Load 10 results per page, with "Load More" button or infinite scroll.
Join Button: Each tribe card has a "Join" or "Request to Join" button (based on privacy).


Real-Time Feedback: Autocomplete suggestions for tags as user types.
Responsive Design: Mobile-friendly grid with collapsible filters.
Accessibility: Screen reader support, focus management for search inputs.

Functionality

Search Query: Send search term and filters to backend via API, retrieve matching tribes.
Caching: Store recent search results in Redis for 5 minutes to reduce database queries.
Autocomplete: Fetch tag suggestions from backend as user types (debounced to limit API calls).
Join Action: For public tribes, add user to tribe immediately; for restricted tribes, create a pending membership request.
Sorting: Default sort by relevance (keyword match); optional sort by member count or creation date.

Tribe Search Flowchart
Diagram: Tribe Search Flow

Start: User enters search term or selects filters.
Step 1: Frontend sends API request with query and filters.
Decision 1: Are results cached in Redis?
Yes: Return cached results.
No: Query PostgreSQL, cache results.


Step 2: Render tribe cards with join buttons.
Decision 2: User clicks "Join"?
Public Tribe: Add user to tribe (API call).
Restricted Tribe: Create pending request (API call).


End: Update UI with join status or results.

5. Data Model
The homescreen and search feature rely on the existing ToneTribe data model, with additions for recommendations and tags.
Diagram: Entity-Relationship Diagram (ERD)

User: (user_id [PK], email, username, password_hash, spotify_token, apple_music_token, created_at)
Tribe: (tribe_id [PK], name, description, creator_id [FK: User], privacy [public/private/restricted], platforms [spotify/apple_music/both], created_at)
Tribe_Membership: (user_id [FK: User], tribe_id [FK: Tribe], role [Lead/Member], status [pending/approved], joined_at)
Tag: (tag_id [PK], name [e.g., "Rock", "Jazz"])
Tribe_Tag: (tribe_id [FK: Tribe], tag_id [FK: Tag])
Recommendation: (user_id [FK: User], tribe_id [FK: Tribe], score [float], created_at)

6. API Endpoints
Homescreen

GET /api/user/profile: Fetch user profile (username, linked accounts).
Response: { user_id, username, spotify_linked, apple_music_linked }


GET /api/user/tribes: Fetch user’s joined tribes.
Response: [{ tribe_id, name, description, member_count, platforms }]


GET /api/tribes/recommended: Fetch recommended tribes (based on tags or activity).
Response: [{ tribe_id, name, description, tags, member_count, platforms }]



Tribe Search

GET /api/tribes/search: Search tribes by query and filters.
Query Params: q (search term), tags (array), privacy, platforms, sort, page, limit
Response: [{ tribe_id, name, description, tags, member_count, platforms, privacy }]


GET /api/tags/autocomplete: Fetch tag suggestions for search.
Query Params: q (partial tag name)
Response: [{ tag_id, name }]


POST /api/tribes/:id/join: Join a tribe or request access.
Payload: { user_id }
Response: { status: "joined" | "pending" }



7. Technical Requirements

Scalability: AWS ECS for backend, RDS for PostgreSQL, Redis for caching.
Security: HTTPS, JWT authentication, sanitized search inputs to prevent SQL injection.
Performance: API response time < 200ms, search latency < 300ms with caching.
Compatibility: Supports modern browsers (Chrome, Firefox, Safari) and mobile devices.
Caching TTL: 5 minutes for search results, 10 minutes for recommendations.

8. Implementation Notes

Frontend:
Use React hooks (useState, useEffect) for state management and API calls.
Implement debouncing for search input (300ms delay).
Use react-infinite-scroll-component for pagination.


Backend:
Use Sequelize ORM for PostgreSQL queries.
Implement full-text search with PostgreSQL tsvector for efficient keyword matching.
Cache search results with Redis SETEX command.


Testing:
Unit tests for API endpoints (search, join).
Integration tests for homescreen rendering and search flow.


Future Enhancements:
Add AI-based tribe recommendations using user listening history (via Spotify API).
Support advanced filters (e.g., tribe activity level).



9. References

Spotify Web API: https://developer.spotify.com/documentation/web-api
Apple Music API: https://developer.apple.com/documentation/applemusicapi
PostgreSQL Full-Text Search: https://www.postgresql.org/docs/current/textsearch.html
React Documentation: https://react.dev


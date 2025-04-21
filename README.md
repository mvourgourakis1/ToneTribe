# ToneTribe: A Community-Driven Music Streaming Platform

**ToneTribe** is a music streaming app designed to connect people through shared musical tastes, fostering vibrant communities called Tribes. By blending music discovery with social interaction, ToneTribe empowers users to explore genres, make friends, and curate playlists together in a dynamic, engaging way.

## 1. Problem Definition and User Research

### Problem
Music streaming apps often prioritize individual listening or algorithm-driven recommendations, leaving users craving deeper social connections over shared musical passions. Existing platforms lack spaces where fans can bond over specific vibes, collaborate on playlists, or feel part of a community that evolves with their tastes.

### Solution
ToneTribe solves this by centering the experience around Tribes—communities where users connect, discover music, and co-create playlists based on shared vibes. It’s engaging because it taps into the human desire for belonging and creative expression through music.

### Target Audience
- **Primary**: Music enthusiasts aged 18–35 who love discovering new music, sharing tastes, and connecting with others (e.g., Gen Z and Millennials active on social platforms).
- **Secondary**: Casual listeners seeking community-driven music experiences beyond solo streaming.
- **Why it’s engaging/useful**: ToneTribe offers a sense of belonging, encourages social discovery, and makes music listening interactive through collaborative playlists and democratic leadership.

### User Persona (Optional)
- **Name**: Mia, 24, college student
- **Background**: Loves indie pop and K-hip-hop, active on social media, attends local gigs.
- **Goals**: Find new music that fits her vibe, connect with fans who share her tastes, and co-create playlists.
- **Pain Points**: Feels isolated on algorithm-heavy apps; wants a community to discuss and share music.

## 2. Conceptualization and Design

### Main Features
- **Official Tribes**: 10 genre-based Tribes (e.g., Pop, Jazz, EDM) at launch, moderated by ToneTribe admins, open to unlimited members.
- **User-Created Tribes**: Groups of 5+ users can form Tribes around specific vibes (e.g., "Late-Night Lo-Fi"). Join via search, VibeMatch recommendations, or invites.
- **TribeList Playlist**: Each Tribe has a collaborative playlist (max 200 tracks/month), curated by elected leaders.
- **VibeMatch**: Algorithm suggesting Tribes based on listening habits and user profiles.
- **Leadership Voting**: Monthly Tribe-wide votes to select playlist leaders, with an activity leaderboard showcasing engagement.
- **Archiving**: Users can save favorite TribeList versions for personal use.
- **Social Features**: Friend connections, taste comparisons, and in-app messaging within Tribes.

### Sketches/Details
- **Homepage**: Displays user’s Tribes, recommended Tribes via VibeMatch, and friend activity.
- **Tribe Hub**: Shows TribeList, leaderboard, chat, and voting interface.
- **Search UI**: Filters for Tribes by genre, vibe, or size.
- *(Note: Wireframes can be added to the repo’s `/sketches` folder if required.)*

### User Flow
1. **Onboarding**: User signs up, selects favorite genres, and joins 1–2 official Tribes.
2. **Exploration**: Browses official Tribes, connects with users, and discovers music via TribeLists.
3. **Tribe Creation**: After befriending 5+ users, creates a Tribe with a custom vibe and invites others.
4. **Engagement**: Listens to TribeList, chats, votes for leaders, and checks leaderboard.
5. **Curation**: If elected leader, collaborates to update the TribeList (add/remove tracks).
6. **Archiving**: Saves a TribeList version to revisit later.

## 3. Behaviors

### Key Behaviors
- **Community Building**: Users join Tribes to connect with like-minded fans, fostering friendships and discussions around music.
- **Collaboration**: Co-creating TribeLists encourages active participation and creativity.
- **Competition**: Monthly leadership votes and leaderboards gamify engagement, rewarding active users with influence.
- **Discovery**: VibeMatch and Tribe exploration expose users to new music and communities, keeping them hooked.

### Mechanisms for Engagement
- **Social Incentives**: Seeing friends’ tastes and leaderboard rankings motivates participation.
- **Democratic Control**: Voting for leaders gives users agency, making Tribes feel personal and dynamic.
- **Vibe-Driven Design**: Custom Tribes let users express identity, driving emotional investment.

## 4. Deployment and Maintenance 

### Deployment
- **Platform**: ToneTribe will launch as a mobile app on iOS and Android, with a web version for broader access.
- **Rollout**: Beta test with 1,000 users to refine VibeMatch and Tribe moderation, followed by a public launch with the 10 official Tribes.
- **Infrastructure**: Cloud-based servers (e.g., AWS) for streaming, with a database for user profiles and playlists.

### Maintenance
- **Updates**: Monthly patches for bugs and UI tweaks; quarterly feature additions (e.g., live listening parties).
- **Moderation**: Admins oversee official Tribes; user Tribes have report systems for content violations.
- **Scalability**: Monitor server load as Tribes grow, optimizing for large communities (10,000+ members).

## 5. Documentation and Presentation

### GitHub Repository
- This README outlines the full product design.
- `/sketches`: Placeholder for wireframes or UI mockups (to be added if required).
- `/slides`: Contains two pitch slides (to be uploaded separately).
- Code snippets or prototypes can be added for future development.

### Pitch Slides
- **Slide Link**: Introduces ToneTribe’s mission: “Connect through music, vibe by vibe.” Highlights Tribes and social discovery.

## Next Steps
ToneTribe aims to redefine music streaming by prioritizing community and creativity. Future iterations could include live events, artist partnerships, or gamified rewards for active Tribes.

##Community Engagement
###REQUESTING: A non-leader can create requests/suggestions for song additions in any tribe's playlist.
	DAILY CAP: There should be a daily cap on how many requests someone can make in 1 tribe's playlist (~5/day? --> to avoid clutter/spams for the leader)
	APPROVAL: You get participation/activity points for every song that's approved
	REJECTION: No penalties for having your request rejected.
	FEEDBACK: When the leader either approves or rejects a request, they can send feedback to the requester for (a very small amount of) activity points.
		- Kind of like Scoir (if you add a college, it asks you why you added it and gives you a bunch of options you can select from + you can select multiple)
		- MAYBE: small 
SCOIR'S LAYOUT (this would be what the leader's POV looks like when writing feedback)
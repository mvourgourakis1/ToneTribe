# Music Stats Integration System

This system allows users to connect their Spotify or Apple Music accounts and fetch listening statistics such as top songs, artists, and albums.

---

## 📡 Connect Listening Platform

### Class: `ConnectListeningPlatform`

- **Attribute**
  - `UsersListeningPlatform: String` — Indicates the user's selected platform (e.g., "Spotify" or "Apple Music").

- **Methods**
  - `connectAppleMusic(id: String): type` — Connects a user to Apple Music using a given ID.
  - `connectSpotifyMusic(id: String): type` — Connects a user to Spotify using a given ID.

---

## 🎧 Spotify / Apple Music Integration

### Class: `Apple Music / Spotify`

- **Attributes**
  - `Songs: arraylist`
  - `Artists: arraylist`
  - `Albums: arraylist`

- **Methods**
  - `GetTopSongs(String time length): arraylist` — Fetches the top songs for a given time period.
  - `GetTopAlbums(String time length): type` — Fetches the top albums.
  - `GetTopArtists(String time length): arraylist` — Fetches the top artists.

---

## 📊 Fetching User Stats

### Class: `FetchDetails`

- **Methods**
  - `fetchSong: song` — Fetches a specific song's data.
  - `fetchArtist: String` — Fetches data for a specific artist.
  - `fetchAlbums: list` — Retrieves a list of albums.
  - `fetchHistory: type` — Gets a user's listening history.

---

## 🎼 Song Metadata

### Class: `Songs`

- **Attributes**
  - `trackid: string`
  - `artist: string`
  - `album: genre`
  - `field: type`

- **Methods**
  - `getSong(String): string`
  - `getArtist(String): string`
  - `getAlbum(String): String`
  - `getGenre(String): String`

---

## 🔄 Workflow Summary

1. **User connects** their listening platform using `ConnectListeningPlatform`.
2. Platform-specific data is fetched through `Apple Music / Spotify` methods.
3. Detailed statistics are retrieved using `FetchDetails`.
4. Metadata and playback history are structured using the `Songs` class.

---

This system is useful for aggregating listening behavior across platforms, providing users with unified music insights.

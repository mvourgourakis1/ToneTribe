# TrackManager.md

# 🎧 TrackManager System - Technical Specification

## Overview

The TrackManager System is designed to manage a user's top songs by fetching data through an API and organizing it via song objects. The architecture consists of four main classes:

- `TrackManager`
- `Song`
- `APIFetcher`
- `Key` (legend only, not a functional class)

---

## 🧩 Class Structure

### **1. `TrackManager`**

Handles user-specific song management, particularly identifying and storing top songs.

### **Attributes**

| Name | Type | Description |
| --- | --- | --- |
| `User` | hash | Unique identifier for the user |
| `TopSongs` | Song[] | Array of top `Song` objects |

### **Methods**

| Name | Return Type | Description |
| --- | --- | --- |
| `FillTopSongs()` | bool | Primary method to populate `TopSongs` via `APIFetcher` |
| `Fetch()` | Song | Returns one of the user's top songs |

---

### **2. `Song`**

Represents a single song with associated metadata and helper methods.

### **Attributes**

| Name | Type | Description |
| --- | --- | --- |
| `TrackName` | String | Name of the song |
| `TrackID` | hash | Unique identifier for the track |
| `AlbumName` | String | Name of the album |
| `ArtistName` | String | Name of the artist |
| `TrackLength` | double | Duration of the track in seconds |

### **Methods**

| Name | Return Type | Description |
| --- | --- | --- |
| `getName()` | String | Returns the name of the song |
| `generateID()` | bool | Primary method to create a unique track ID |
| `getArtist()` | String | Returns the name of the artist |
| `getID()` | hash | Returns the track's ID |

---

### **3. `APIFetcher`**

Interfaces with an external service to retrieve a user's top songs.

### **Attributes**

| Name | Type | Description |
| --- | --- | --- |
| `Service` | String | Name of the API service (e.g., Spotify) |
| `APIKey` | hash | Key used for authenticating with the API |

### **Methods**

| Name | Return Type | Description |
| --- | --- | --- |
| `getTop()` | Song[] | Primary method to fetch top songs via the API |

---

## 🗝️ Key (Legend)

| Color | Description |
| --- | --- |
| Blue | Primary Functions (Implement First) |
| Green | Secondary Functions |

---

## 🔄 Class Relationships

- `TrackManager` interacts with `Song` for storage and retrieval.
- `TrackManager` uses `APIFetcher` to fill `TopSongs`.
- `APIFetcher` returns `Song[]` objects to `TrackManager`.
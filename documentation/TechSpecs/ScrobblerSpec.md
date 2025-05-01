# ScrobblerSpec.md

# 🎵 Scrobbler System - Technical Specification

## Overview

The Scrobbler System is designed to log and track user interactions with songs and fetch notifications from external services. It consists of four primary classes:

- `Scrobbler`
- `Song`
- `NotificationFetcher`

---

## 🧩 Class Structure

### **1. `Scrobbler`**

Logs songs played by a user and manages song history.

### **Attributes**

| Name | Type | Description |
| --- | --- | --- |
| `User` | hash | Unique identifier for a user |
| `SongLog` | stack | Stack to keep a history of songs |

### **Methods**

| Name | Return Type | Description |
| --- | --- | --- |
| `Scrobble()` | void | Primary method to log the current song |
| `Fetch()` | Song | Secondary method to retrieve the latest song |

---

### **2. `Song`**

Represents a music track with metadata.

### **Attributes**

| Name | Type | Description |
| --- | --- | --- |
| `TrackName` | String | Name of the track |
| `AlbumName` | String | Name of the album |
| `TrackID` | hash | Unique identifier for the track |
| `ArtistName` | String | Artist's name |
| `TrackLength` | double | Duration of the track (seconds) |

### **Methods**

| Name | Return Type | Description |
| --- | --- | --- |
| `getName()` | String | Returns the name of the track |
| `getID()` | hash | Returns the track’s ID |
| `getArtist()` | String | Returns the artist’s name |

---

### **3. `NotificationFetcher`**

Fetches song data from device notifications

### **Attributes**

| Name | Type | Description |
| --- | --- | --- |
| `Service` | String | Name of music service provider |
| `APIKey` | hash | Key used to authenticate with the API |

### **Methods**

| Name | Return Type | Description |
| --- | --- | --- |
| `setSong()` | void | Uses the data from notifications to set the current Song object |
| `watchNotification()` | bool | check if the music provider is active on device notifications |

---

## 🗝️ Key (Legend)

| Color | Description |
| --- | --- |
| Blue | Primary Functions (Implement First) |
| Green | Secondary Functions |

---

## 🔄 Class Relationships

- The SongLog within the `Scrobbler` class is a stack of `Song` objects.
- `NotificationFetcher` **sets the current** `Song` object via setSong().
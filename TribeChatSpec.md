# Tribe Chat — Feature Specification

## Overview
The chat feature in ToneTribe enables real-time, music-focused communication among users within designated Channels (Tribes). Users can send messages, share song suggestions, and participate in music discussions. Moderation tools are included to maintain respectful and relevant interactions.

## Core Classes & Relationships

### 1. Message
Represents a single message sent in a Channel. Each message may optionally contain a song suggestion.

- **Attributes:**
  - `sender: User` – The user who sent the message.
  - `content: string` – The textual content of the message.
  - `sentDate: float` – Timestamp of when the message was sent.
  - `attachedSongSuggestion: Song` – (Optional) A song object suggested by the sender.

- **Methods:**
  - `editContent(): void` – Allows the sender to modify message content.
  - `attachSongSuggestion(Song): void` – Attaches a song to the message.
  - `deleteMessage(): void` – Deletes the message from the channel.

### 2. Channel
A subgroup under a Tribe where users can chat and share music.

- **Attributes:**
  - `messageStream: Message[]` – List of all messages in the channel.
  - `channelName: String` – The name of the channel.
  - `allowedUsers: User[]` – Users who are members of the channel.

- **Methods:**
  - `addUserToChannel(User): void` – Adds a user to the channel.
  - `kickUserFromChannel(User): void` – Removes a user from the channel.
  - `removeMessage(Message): void` – Removes a message from the channel.
  - `reportMessageToModerator(Message): void` – Flags a message for moderation.

### 3. Moderator
Moderators oversee content and behavior in assigned channels.

- **Attributes:**
  - `assignedChannels: Channel[]` – Channels the moderator is responsible for.
  - `reportsReceived: Message[]` – Messages reported for review.

- **Methods:**
  - `kickUserInChannel(Channel): void` – Removes disruptive users from a channel.
  - `removeMessageInChannel(Channel): void` – Deletes inappropriate messages from a channel.

## Functional Requirements

### User Messaging
- Users in a channel can post messages.
- Messages can optionally contain a song recommendation.
- Messages are timestamped.

### Song Suggestions
- Song suggestions are attached to messages using `attachSongSuggestion(Song)`.
- Songs are displayed alongside user messages in the UI.

### Channel Management
- Channels are identified by a unique `channelName`.
- Users must be listed in `allowedUsers` to post or view messages.
- Admins can manage membership via `addUserToChannel` and `kickUserFromChannel`.

### Moderation Tools
- Users can report messages using `reportMessageToModerator(Message)`.
- Moderators can:
  - View all reported messages (`reportsReceived`).
  - Remove inappropriate messages.
  - Kick offending users from channels they manage.

## Data Flow Example

1. A user sends a message in a channel → `Message` object is created and pushed to `messageStream`.
2. User attaches a song → `attachSongSuggestion(Song)` is called.
3. Another user finds the message inappropriate → invokes `reportMessageToModerator`.
4. Moderator reviews `reportsReceived`, deletes if necessary using `removeMessageInChannel`.

## Permissions

- Only `allowedUsers` can read/write in a `Channel`.
- Only `Moderators` can delete or manage messages across channels.
- Only the `sender` can edit or delete their own messages.

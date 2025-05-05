# Tribe Chat System Design

## User

### Vars
- **content**: The message that will be sent
- **Chat ID**
- **User ID**
- **Username**

## Functions
- **Send a message**: Records the timestamp
- **Listen to incoming messages**
- **Display messages**: Ranked by timestamp
- **Edit messages**

---

## Chat Flow

When a user is in a tribe chat:
- Their profile contains the `tribe chat ID` and their own `user ID`.
- The user enters a message, which is sent to the backend.
- Each user is listening for changes in the backend's message store.
- When a new message is detected, the UI is updated accordingly.

---

## Backend Chat Storage

- **Censorship List**:  
  A list of inappropriate words/phrases to censor.

- **Message Store**:  
  ```text
  HashMap <timestamp, Tuple(userID, content)>

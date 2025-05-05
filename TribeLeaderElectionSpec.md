# Tribe Leader Election — Feature Specification

## Overview
Every month, each Tribe in **ToneTribe** conducts a democratic election to select 2–3 **Tribe Leaders** who will collaboratively manage the TribeList (shared playlist) for the next month. Leadership is community-driven, incentivizing engagement and rotating influence to keep the musical vibe fresh and inclusive.

---

## Data Structures & Attributes

### `Election` Class

- `candidates: User[]`  
  List of users running for leadership this cycle.

- `eligibleVoters: User[]`  
  Tribe members eligible to cast a vote (likely based on membership and activity thresholds).

- `votesForCandidates: Map<User, int>`  
  Tallies total weighted votes received by each candidate.

- `vibeStatementsForCandidates: Map<User, string>`  
  Maps each candidate to their submitted “Vibe Statement” — a description of their music style, goals, and recent favorites.

---

### `Tribe Leader` Class

- `servedTimeInCurTerm: float`  
  Tracks the amount of time (e.g., in days) the user has actively served as leader during the current term.

- `isTermCoolDown: bool`  
  Indicates whether a leader is ineligible this cycle due to having served two consecutive terms.

- `numberOfTerms: int`  
  Tracks the number of terms served historically by the user.

- `maxDurationOfTerm: static int`  
  Constant defining the number of days a leadership term lasts (e.g., 30 days).

- `maxConsecutiveTerms: static int`  
  Constant defining the maximum number of back-to-back terms allowed (default: 2).

---

## Voting Logic

### Candidate Registration

- `runForLeader(User): void`  
  Allows a user to self-nominate for candidacy.

- `endorseCandidate(User): void`  
  Enables peer endorsement for candidates, enhancing visibility during voting.

- `vibeStatementsForCandidates`  
  Populated upon candidacy registration for each candidate.

---

### Weighted Voting System

- `voteFor(User, float): void`  
  Allows a user to cast a vote for a candidate. The optional `float` represents the vote's weight, computed from activity metrics.

- `getVoteWeight(User): float`  
  Determines the vote weight of a user based on recent activity (e.g., listening time, interactions, participation). Returns a float ≥ 1.

---

### Election Finalization

- `getTop3Winners(Map<User, int>): User[]`  
  Returns the top 2 or 3 candidates based on vote count (depending on Tribe size).

- `assignTribeLeaders(User[]): void`  
  Applies leadership privileges (e.g., playlist editing) to elected users and resets cooldown eligibility where applicable.

---

## 🛠️ Tribe Leader Powers

Granted to the users returned by `getTop3Winners(...)` and assigned via `assignTribeLeaders(...)`.

- `addTribeSong(Song): void`  
- `removeTribeSong(Song): void`  
- `reOrderTribeSong(int): void`  
  Enables editing of the TribeList playlist.

- `timeOutMember(User): void`  
  Temporarily removes disruptive members from Tribe interaction spaces.

- `kickMember(User): void`  
  Fully removes disruptive members from Tribe interaction spaces.

- `vetoRequest(Song): void`  
  Blocks song additions via community requests if deemed inappropriate by majority of leaders.

---

## Cooldown & Rotation Handling

After serving two consecutive terms:

- `isTermCoolDown` is set to `true`.
- Candidate is excluded from `candidates` array unless a full cycle has passed.

If `candidates` is empty:

- System invokes default rotation using leaderboard activity to select members with highest recent contributions.

---

## User Experience Integration

- Push notifications prompt voters when `runForLeader` period opens and again when voting begins.
- Inside the **Tribe Hub**, the voting interface displays:
  - Profiles from `candidates`
  - Vibe statements from `vibeStatementsForCandidates`
  - Community endorsements
  - Contribution history (auto-populated)

---

## Constraints & Safeguards

- Voting is **anonymous**.
- Low-activity members retain **full voting rights** (minimum weight = 1) to prevent elitism.
- Elected leaders' terms are tracked via `servedTimeInCurTerm`, `numberOfTerms`, and validated against `maxConsecutiveTerms`.

---

## 🔄 Monthly Lifecycle

1. Candidates register: `runForLeader(...)`  
2. Endorsements/vibe statements submitted  
3. Voting opens (3-day window): `voteFor(...)`  
4. Votes counted: `votesForCandidates`, `getTop3Winners(...)`  
5. Leaders assigned: `assignTribeLeaders(...)`  
6. Cooldown + eligibility updated  
7. New term begins

# CookLoop

CookLoop is an iOS social cooking platform where users can publish recipes, discover new dishes, engage with other cooks, and compete through a gamified leaderboard system.

This README documents the implemented functionality across the app in detail.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Authentication and Session Flows](#authentication-and-session-flows)
4. [Main App Navigation](#main-app-navigation)
5. [Feature Details by Screen](#feature-details-by-screen)
6. [Recipe Lifecycle (End to End)](#recipe-lifecycle-end-to-end)
7. [Social Features](#social-features)
8. [Gamification and Leaderboard](#gamification-and-leaderboard)
9. [Admin Panel and Moderation](#admin-panel-and-moderation)
10. [Data Models](#data-models)
11. [Firestore Data Layout](#firestore-data-layout)
12. [Service Layer Responsibilities](#service-layer-responsibilities)
13. [ViewModel Responsibilities](#viewmodel-responsibilities)
14. [External APIs and Integrations](#external-apis-and-integrations)
15. [Theme System](#theme-system)
16. [Current Constraints and Known Limitations](#current-constraints-and-known-limitations)
17. [Run and Build Notes](#run-and-build-notes)

## Project Overview

CookLoop is built with SwiftUI using an MVVM structure.

Core capabilities:
- Account creation and login with Firebase Authentication.
- User-generated recipes with image, ingredients, steps, difficulty, time, and tags.
- Global and following feeds with filtering and sorting.
- Likes, comments, replies, reposts, bookmarks, and follows.
- Profile management, recipe editing/deletion, and password change.
- In-app activity notifications.
- Weekly leaderboard with engagement scoring.
- Admin dashboard for user, recipe, and report moderation.
- External recipe discovery via TheMealDB API.

## Architecture

The codebase is organized into these layers:

- `Views`: Screen-level SwiftUI views.
- `Components`: Reusable UI pieces (cards, image picker, remote image renderer, profile header, admin panel components).
- `ViewModels`: Feature logic, asynchronous operations, state management, and Firestore listeners.
- `Models`: Codable entities and Firestore mapping utilities.
- `Services`: Infrastructure and domain services for Firebase setup, notifications, and gamification.

Runtime flow:
- App launch initializes Firebase in `FirebaseManager`.
- `AuthViewModel` resolves auth session and current user document.
- If authenticated user is admin, app routes to Admin Panel.
- Otherwise app routes to the 5-tab user app experience.

## Authentication and Session Flows

### Signup

Implemented in `SignupView` + `AuthViewModel.signup(...)`:
- Collects name, email, password.
- Creates Firebase Auth account.
- Creates Firestore user profile under `/users/{uid}` with default gamification fields:
  - `xp = 0`
  - `level = "Beginner Cook"`
  - `badges = []`
  - counters initialized to zero (`totalRecipesPosted`, `totalLikesReceived`, `totalComments`, `totalBookmarks`).
- Stores session in `userSession` and loads `currentUser`.

### Login

Implemented in `LoginView` + `AuthViewModel.login(...)`:
- Authenticates with Firebase Auth email/password.
- Loads user profile document (`fetchUser`).
- Enforces ban policy:
  - If `isBanned == true`, user is forcibly logged out and shown an access error.
- Triggers weekly gamification recalculation check.

### Logout

Implemented in `AuthViewModel.signOut()`:
- Signs out through Firebase Auth.
- Clears in-memory user/session state.
- Routes back to login screen.

### Session Persistence

- Session comes from `auth.currentUser` on app start.
- Profile document is fetched to hydrate app state.
- Legacy fallback is supported when user docs have missing/empty `id` by using document ID/UID.

## Main App Navigation

Standard users are routed to a tabbed experience:

1. Feed
2. Discover
3. Upload (floating action button behavior)
4. Profile
5. Activity

Additional navigation:
- Global recipe/user search sheet is available from primary surfaces.
- Recipe cards navigate to detailed recipe view.
- User names/profile actions navigate to user profiles.

Admin users bypass tabs and are routed to the admin dashboard.

## Feature Details by Screen

### 1) Login Screen

- Email/password input.
- Sign-in action with loading and error state feedback.
- Opens sign-up sheet.
- Access to global search overlay entry points.

### 2) Signup Screen

- Name/email/password registration form.
- Account creation with Firestore bootstrap of profile and game stats.
- Automatic post-signup login/session initialization.

### 3) Feed Screen

Primary features:
- Feed mode switch:
  - `For You`: global feed.
  - `Following`: only users that current user follows.
- Filter controls:
  - Difficulty filter (including easy recipes).
  - Cooking time filter (quick recipes).
  - Bookmark-focused filtering.
- Sort options:
  - Newest first.
  - Oldest first.
  - Most liked.
- Real-time updates from Firestore listeners.

Recipe card interactions:
- Like/unlike recipe.
- Bookmark/unbookmark recipe.
- Repost recipe.
- Quote repost (repost with comment text).
- View creator profile.
- Navigate to recipe detail.
- Show unread indicators (`New`, `New comment`) where applicable.

### 4) Discover Screen

- Curated collection tiles based on cooking themes/tags.
- Tag-specific discovery view for community recipes.
- External API recipe browsing (`Classic Recipes`).
- API cards show image/title/category/region and navigate to API detail view.

Curated categories implemented include:
- Cozy Breakfasts
- Spicy Dinners
- Sweet Treats
- Quick Fixes
- Healthy Bowls

### 5) API Detail Screen

- Displays read-only details for external recipe:
  - Hero image
  - Recipe name
  - Category
  - Region/area
  - Full instructions

### 6) Upload Screen

Recipe creation form supports:
- Title.
- Image input:
  - Device image picker.
  - Optional remote URL path.
- Dynamic ingredient list (add/remove rows).
- Dynamic step list (add/remove rows).
- Cooking time selector.
- Difficulty selector:
  - Easy
  - Intermediate
  - Hard
- Multi-select tags.

Submit behavior:
- Validates required fields.
- Persists recipe to Firestore.
- Awards gamification points for posting.
- Updates profile-level posting counters.

### 7) Recipe Detail Screen

Full recipe experience includes:
- Hero image and primary metadata.
- Creator name with navigation to creator profile.
- Time, difficulty, tags.
- Like button and total like count.
- Structured ingredients section.
- Step-by-step cooking instructions.
- Contextual visual tips in long instructions sections.
- Comment system with reply support.
- Comment composer for current user.
- CTA to start cooking flow.

### 8) Profile Screen

For current user:
- Profile header with avatar, name, bio.
- XP level and badge display.
- Theme selector.
- Edit profile action.
- Logout action.
- Two content tabs:
  - My Recipes
  - Saved Recipes
- Recipe management from grid:
  - Edit recipe
  - Delete recipe

For other users:
- Same identity and stats display.
- Follow/unfollow action.
- Their posted recipes.

Profile management features:
- Update name, bio, and profile image.
- Change password with re-authentication.

### 9) Activity Screen

Two major modes:

Notifications mode:
- Real-time stream of user activities:
  - likes
  - comments
  - follows
  - reposts
- Per-notification iconography and relative timestamps.
- Optional attached text for relevant events.

Leaderboard mode:
- Weekly top users ranking.
- Ordered by engagement score and consistency.
- Shows top entries and current user rank context.

### 10) Admin Panel

Dashboard metrics:
- Total users
- Total recipes
- Total reports
- Pending reports

Management surfaces:

Users management:
- Search/filter users.
- See account summary (email, content counts, admin/banned state).
- Ban/unban actions.

Recipes management:
- Browse uploaded recipes.
- Review metadata and engagement.
- Delete problematic recipes.

Reports management:
- View report queue and status.
- Resolve report.
- Delete target content depending on report type.
- Ban user for user-targeted reports.

## Recipe Lifecycle (End to End)

1. Creation:
- User builds recipe in Upload screen and submits.
- Firestore document is created with metadata and timestamps.

2. Distribution:
- Recipe appears in global feed listeners.
- Can appear in tag-based discovery views.
- Can be reposted by other users.

3. Engagement:
- Others can like, bookmark, comment, and reply.
- Notifications are sent to owner for key actions.
- Owner receives gamification points based on interactions.

4. Persistence and retrieval:
- Recipe supports detail view, feed cards, profile lists, and saved lists.

5. Maintenance:
- Owner can edit or delete from profile.
- Admin can remove recipe from admin panel.

## Social Features

### Follow System

- Implemented via reciprocal subcollections:
  - `/users/{me}/following/{target}`
  - `/users/{target}/followers/{me}`
- Supports follow/unfollow toggle.
- Tracks follower/following counts.
- Sends follow notification to target user.

### Likes

- Like presence tracked in `/recipes/{recipeId}/likes/{uid}`.
- Aggregate count mirrored in recipe `likes` field.
- Uses transactions/batches for consistency.
- Like action can trigger owner XP award.

### Bookmarks

- Stored in `/users/{uid}/savedRecipes/{recipeId}` with `savedAt` timestamp.
- Profile Saved Recipes tab reconstructs recipe list by IDs.
- Bookmark actions can award user XP.

### Comments and Replies

- Top-level comments in `/recipes/{recipeId}/comments/{commentId}`.
- Replies nested under comment `replies` subcollection.
- Real-time listener updates comment tree.
- Comment and reply creation can award XP and send notifications.

### Reposts

- Repost documents in `/reposts/{repostId}`.
- Supports plain repost and quote repost.
- Feed view merges repost activity with recipe content.
- Repost sends notification to original creator.

## Gamification and Leaderboard

Gamification events tracked for actions:
- Recipe posted
- Like received
- Comment added
- Bookmark action

XP and levels:
- XP accumulates over user actions.
- Level resolves from XP thresholds:
  - Beginner Cook
  - Home Chef
  - Pro Chef
  - Master Chef

Badges currently awarded include:
- Recipe Creator
- Top Contributor
- Trending Chef
- Community Helper
- Loved Chef

Weekly stats:
- Stored under `/weeklyStats/{weekId}/users/{userId}`.
- Engagement score and active-day consistency are updated.
- Leaderboard ranks users weekly from this dataset.

## Admin Panel and Moderation

Admin-only access is enforced through `currentUser.isAdmin` routing at app launch.

Moderation capabilities:
- User bans (`isBanned`).
- Recipe deletion.
- Report triage and resolution.
- Target-content deletion by report type (user/recipe/comment).

Real-time admin listeners keep dashboard lists current for users, recipes, and reports.

## Data Models

### User

Core fields:
- `id`
- `name`
- `email`
- `profileImage`
- `bio`
- `isAdmin`
- `isBanned`
- `xp`
- `level`
- `badges`

Supplementary analytics fields in Firestore:
- `totalRecipesPosted`
- `totalLikesReceived`
- `totalComments`
- `totalBookmarks`

### Recipe

Core fields:
- `id`
- `userId`
- `title`
- `imageUrl`
- `legacyImageData`
- `ingredients`
- `steps`
- `likes`
- `createdAt`
- `cookingTimeMinutes`
- `difficulty`
- `tags`

### Comment and Reply

Comment:
- `id`
- `userId`
- `username`
- `text`
- `createdAt`
- `replies`

Reply:
- `id`
- `userId`
- `username`
- `text`
- `createdAt`
- `parentCommentId`

### Activity Notification

Fields:
- `id`
- `actorUserId`
- `actorName`
- `recipientUserId`
- `type` (`like`, `comment`, `follow`, `repost`)
- `recipeId` (optional)
- `text` (optional)
- `createdAt`

### APIRecipe (External)

Fields from TheMealDB payload:
- `idMeal`
- `strMeal`
- `strMealThumb`
- `strInstructions`
- `strCategory`
- `strArea`

## Firestore Data Layout

Primary collections used:

- `/users/{uid}`
  - profile fields and gamification counters
  - `/following/{targetUid}`
  - `/followers/{followerUid}`
  - `/savedRecipes/{recipeId}`
  - `/notifications/{notificationId}`
  - `/gamificationEvents/{eventId}`

- `/recipes/{recipeId}`
  - recipe document fields
  - `/likes/{userId}`
  - `/comments/{commentId}`
    - `/replies/{replyId}`

- `/reposts/{repostId}`

- `/weeklyStats/{weekId}/users/{uid}`

- `/reports/{reportId}`

## Service Layer Responsibilities

### FirebaseManager
- Initializes Firebase app once.
- Exposes shared `Auth` and `Firestore` instances.

### AuthService (GamificationService)
- Applies XP deltas for user actions.
- Resolves and updates levels.
- Awards badges based on thresholds and weekly performance.
- Writes gamification event history.
- Maintains weekly leaderboard stats.

### NotificationService
- Creates activity notifications in recipient user document space.
- Enforces guard rails (no self-notification, invalid payload checks).

## ViewModel Responsibilities

### AuthViewModel
- Login, signup, logout.
- Current session/current user loading.
- Ban-state enforcement and auth error handling.

### RecipeViewModel
- Upload recipes.
- Real-time feed listeners (global/following).
- Like handling, repost creation, seen-state tracking.
- Firestore-to-model conversion helpers.

### DiscoverViewModel
- Fetches and decodes TheMealDB search results.
- Exposes loading and error state.

### BookmarkViewModel
- Real-time saved recipe tracking.
- Add/remove bookmarks.
- Resolve saved IDs into recipe objects.

### CommentsViewModel
- Real-time comments/replies observation.
- Create comments/replies.
- Manage submission state and listener lifecycle.

### ProfileViewModel
- User profile fetch/update.
- Password change.
- User recipes query.
- Recipe update/delete for owner.
- Follow/unfollow and follow stats.

### ActivityViewModel
- Real-time notifications feed listener.
- Maps Firestore docs into activity UI state.

### AdminViewModel
- Real-time users/recipes/reports listeners.
- Ban users, delete recipes, resolve reports.
- Delete report targets by report type.
- Computes dashboard summary counts.

### RecipeDetailViewModel
- Loads recipe creator metadata.
- Loads and toggles like state.
- Sends notifications and triggers rewards on interactions.

## External APIs and Integrations

### Firebase
- Authentication: email/password identity and session.
- Firestore: primary persistence for users, recipes, social graph, notifications, reports, weekly stats.

### TheMealDB
- Endpoint used: `https://www.themealdb.com/api/json/v1/1/search.php?s={term}`
- Provides external read-only recipe discovery content shown in Discover and API detail screens.

## Theme System

User-selectable themes are persisted locally and impact app-wide visual styling.

Current themes:
- Warm Classic
- Mint Garden
- Ocean Breeze

## Current Constraints and Known Limitations

- Deployment target is iOS 14.5; avoids iOS 15-only APIs.
- Firebase Storage is not integrated; image handling relies on URL/base64 data strings.
- Legacy user docs may have missing `id`; code handles fallback to auth UID.
- Legacy image fallback field exists (`legacyImageData`) indicating migration-era compatibility.
- Feed has a page limit and no explicit infinite pagination implementation.
- Some moderation/report paths rely on specific target ID formatting.
- Badge and level thresholds are currently hardcoded.

## Run and Build Notes

- Open the Xcode project workspace and run the iOS target.
- Ensure Firebase configuration is present and valid for your environment.
- New Swift files must be registered in project build phases/references in Xcode project metadata.

---

If you want, this README can be expanded further with:
- setup-by-step local environment instructions,
- Firestore security rules examples,
- API contract tables for every collection field,
- screenshots and user journeys by role (user/admin).

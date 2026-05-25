# Coach

Coach allows you to improve customer work by supporting you with engagements and workshops. It serves as a digital companion for facilitators and innovation consultants.

## Goal

Provide a comprehensive tool for planning, facilitating, and managing innovation workshops and customer engagements, including a library of proven methods and real-time collaboration features.

## Stitch Instructions

Get the images and code for the following Stitch project's screens:

## Project
Title: Coach App
ID: 3384684444966255399

## Screens:
1. Design System
    ID: asset-stub-assets-7048684483472313359-1773916583321


## Functional Requirements

### 1. Homescreen
- **Dashboard:** Overview of upcoming activities and quick access to start a new session.
- **Visual Motivation:** Modern UI with "Ready to Innovate?" messaging to inspire users.

### 2. Innovation Method Library
- **Content:** Content is maintained in a remote Wagtail CMS, and pulled through an Wagtail API at https://pramari.de/cms/api/v2
- **Categorization:** Methods organized by innovation phases: `Warmup`, `Empathize`, `Define`, `Ideate`, `Prototype`.
- **Method Details:** For each method, provide:
  - **Why:** The purpose and rationale.
  - **How:** Step-by-step instructions.
  - **Benefit:** Value proposition of the method.
  - **Input/Output:** Required materials and expected results.
  - **Constraints:** Minimum/maximum people and time.
- **Favorites:** Ability to mark methods as favorites for quick access.
- **Search & Filter:** Find methods by category or title.

### 3. Workshop Management
- **Tracking:** Maintain a list of workshops with statuses: `PLANNED` and `DELIVERED`.
- **Metadata:** Capture workshop details:
  - Title and Workshop Type (e.g., Design Thinking).
  - Location Mode: `VIRTUAL`, `ON-SITE`, or `HYBRID`.
  - Schedule: Date and time.
  - Duration: Numeric value and unit (Minutes, Hours, Days).
  - Participant Count: Track the number of people attending.
- **Details:** View and edit specific workshop parameters.

### 4. Contact & Participant Management
- **Contact List:** Manage a personal directory of professional contacts.
- **Google Sync:** Import and sync contacts from Google.
- **Workshop Assignment:** Easily add contacts to specific workshops as participants.
- **Search:** Search contacts by name or email.

### 5. Collaboration (Sauna Chat)
- **Matrix Integration:** Real-time chat functionality using the Matrix protocol.
- **Room Support:** Connect to a dedicated "#sauna" room for collaboration.
- **Timeline:** View message history and send messages within the app.
- **Username:** Maintain the Username from the App and IP Provider in the Matrix chat.
- **Events:** 

### 6. User Profile & Preferences
- **Multi-language Support:** Interface available in English (en) and German (de).
- **Personalization:**
  - Set confidence level.
  - Configure workshop default settings.
  - Visual preferences (themes).
- **Feedback Management:** Track user feedback on methods (Thumbs Up/Down).

## Technical Requirements

### Infrastructure & Persistence
- **Local/Remote Storage:** Persist User Profile, Favorite Methods, Workshops, and Participant data.
- **Authentication:** Secure login and access to the backend API.
- **Theming:** Clean, modern design system based on the "Inter" font and primary color `#25aff4`.

### Platforms
- Cross-platform support (Android, iOS, Web, Linux, macOS, Windows) via Flutter.

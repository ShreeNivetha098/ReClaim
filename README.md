# ReClaim --- Smart Lost & Found for PSG Tech

ReClaim gives a college campus one place to report lost and found
items, find likely matches between them, and return items to their
owners after an ownership check. One Flutter codebase builds two apps:

| App | Who uses it | Platform |
|---|---|---|
| **ReClaim** | Students and staff: report, search, match, claim | iOS, and the web at <https://reclaim-app.web.app> |
| **ReClaim Admin** | Administrators: users, reports, claims, statistics | Web at <https://reclaim-c4695.web.app> |

Each build only serves its own screens: the admin web build opens on the
admin login and refuses non-admin accounts, and the iOS app and the user
web build have no admin screens. The project runs entirely on the **free Firebase Spark plan**. No feature in this project requires a paid
Firebase plan or a paid Apple Developer account.

## Features

### Working now
-   **Sign-up and login** with Firebase Authentication (email and
    password).
-   **PSG Tech email check**: only addresses ending in `@psgtech.ac.in`
    can register or log in.
-   **Lost and found reports** stored in Cloud Firestore.
-   **Smart matching** that scores lost reports against found reports
    by category, name/description keywords, brand, colour, location and
    date. Matching runs on the phone.
-   **Matching in both directions**: a new found report is checked
    against open lost reports, and a new lost report against existing
    found reports.
-   **Match notifications** go only to the owner of the lost report
    (never the finder), once per lost/found pair, for matches scoring
    60% or more. They appear as an iOS banner (while the app is open or
    when the user returns to it) and in the Notifications screen;
    tapping either opens the found item.
-   **Potential-match banner** on the home screen for the user's own
    lost reports, with a screen listing candidate matches.
-   **Claims**: a user claims a found item by answering ownership
    questions; an admin approves or rejects the claim, and approval
    marks both items as claimed.
-   **Manage your own reports**: from an item's details screen the
    person who reported it can edit it, mark it as recovered
    (lost) or returned (found), or delete it with its photo.
-   **Claim decisions** are sent to the claimant as a notification and
    iOS banner, saying where to collect the item if approved.
-   **College ID verification**: at sign-up or later from Profile, a
    user can upload a photo of their college ID card. An admin compares
    it with the user's name and roll number on the web dashboard and
    verifies or rejects it; either way the photo is deleted in the same
    step, so no ID images are kept. Verified users get a badge, and the
    admin Claims table shows whether a claimant is verified. Government
    IDs (Aadhaar, PAN) are deliberately not collected.
-   **Recovery analytics** on the web dashboard: recovery rate, average
    time from report to recovery, reports per month (lost vs found),
    recovery rate by category, places where items are most often lost,
    claim outcomes and the share of verified users.
-   **Web admin dashboard**: users, lost and found reports, claims, items
    unclaimed after 30 days, activity log and statistics.
-   **Item photos** saved in Firestore: photos are shrunk to at most
    1024 px on the phone and stored in the `itemImages` collection (see
    [Free-plan design](#free-plan-design)).

### In progress
See [Roadmap](#roadmap) for details.
-   In-app chat between owner and finder.
-   Moving the 30-day "unclaimed" check off users' phones.

## Tech Stack

-   **Apps:** Flutter and Dart; iOS for users, web for admins
-   **State management:** Riverpod
-   **Navigation:** go_router
-   **Backend:** Firebase Authentication and Cloud Firestore (Spark plan)

## Design

A soft, friendly look shared by the iOS app and the web admin:

-   **Colours** (`lib/core/constants/app_colors.dart`): indigo-violet
    brand gradient, coral for lost items, teal for found items, amber
    for matches, on a warm lavender-white background.
-   **Type:** Plus Jakarta Sans.
-   **Shared widgets** (`lib/shared/widgets/`): gradient buttons and
    soft-shadow cards that shrink slightly when pressed
    (`animations.dart`), item cards, status pills, category icons
    (`category_style.dart`) and form parts (`form_parts.dart`).
-   **Motion:** lists fade and slide in, the match score animates, and
    taps give light haptic feedback.

## Free-plan design

Because the project must stay on the free Firebase Spark plan and must
not need a paid Apple Developer account, some features are designed
differently from a typical production app:

| Need | Usual approach | ReClaim's free approach |
|---|---|---|
| Item photos | Firebase Storage | Compressed photos (about 100 KB) saved in Firestore. Since February 2026, Firebase Storage needs the paid Blaze plan. |
| Match alerts | Remote push (FCM + APNs) | Firestore real-time listeners plus local notifications. Remote push on iOS needs a paid Apple Developer account and a server. |
| Matching | Cloud Functions | Runs on the phone. Cloud Functions need the Blaze plan. |
| Testing on iPhone | TestFlight | iOS Simulator, or a personal iPhone signed with a free Apple ID. |
| Admin website | Paid web hosting | Firebase Hosting, free on the Spark plan. |

**Known limits of this design:**
-   Alerts reach a user only while the app is open or recently in the
    background, not when it has been fully closed.
-   Apps installed on a real iPhone with a free Apple ID stop opening
    after 7 days and must be reinstalled from Xcode.

## Run Locally

### Requirements
-   macOS with **Xcode** (the project was last built with Xcode 26.2)
-   **Flutter SDK** (stable channel); check with `flutter doctor`
-   A Firebase project with an iOS app registered for the bundle ID
    `com.reclaim.app.reclaim`

### Firebase setup
1.  In the Firebase console, add an iOS app with bundle ID
    `com.reclaim.app.reclaim`.
2.  Download `GoogleService-Info.plist` and place it at
    `ios/GoogleService-Info.plist`. This file is in `.gitignore` and is
    never committed.
3.  Enable **Email/Password** sign-in under Authentication.
4.  Create a Cloud Firestore database.
5.  Deploy the security rules with the Firebase CLI (free on the Spark
    plan):
    ``` bash
    brew install firebase-cli
    firebase login
    firebase deploy --only firestore:rules --project <your-project-id>
    ```
    Photo uploads are refused until these rules are deployed.
6.  For the admin website, add a **Web** app in the Firebase console,
    copy `firebase_web.example.json` to `firebase_web.json` and fill in
    the values from the web app's config. `firebase_web.json` is in
    `.gitignore`.
7.  Give an account admin access by setting `role` to `Admin` on its
    document in the Firestore `users` collection. The app never lets a
    user make themselves an admin.

### Build and run
``` bash
flutter pub get
flutter analyze
flutter test
open -a Simulator
flutter run
```

> **Keep the project folder out of iCloud Drive.** If `~/Documents` or
> `~/Desktop` syncs to iCloud, iOS builds fail with *"resource fork,
> Finder information, or similar detritus not allowed"*. Keep the
> project in a folder that iCloud doesn't sync, such as `~/Developer`.

### Websites
The same code builds two sites on Firebase Hosting. A web build is the
admin dashboard unless it is made with `--dart-define=APP=user`.

``` bash
# Run locally in Chrome (add --dart-define=APP=user for the user app)
flutter run -d chrome --dart-define-from-file=firebase_web.json

# Build and publish the admin dashboard
tool/build_web.sh admin
firebase deploy --only hosting:admin --project reclaim-c4695

# Build and publish the student and staff app
tool/build_web.sh app
firebase deploy --only hosting:app --project reclaim-c4695
```

The live admin dashboard is at <https://reclaim-c4695.web.app> and the
user app at <https://reclaim-app.web.app>. In a browser, photos are
chosen as files and there are no iOS banners; the Alerts tab still
updates in real time.

**Use Chrome for the admin site.** Known issue: in Safari, signing in
with a valid admin account shows "Access denied". Not yet fixed.

Always pass `--dart-define-from-file=firebase_web.json`. Without it the
site cannot reach Firebase, and the admin login says so.

To try the admin site against local emulators instead of live data, add
`--dart-define=USE_FIREBASE_EMULATORS=true` and start
`firebase emulators:start --only auth,firestore`.

To run on your own iPhone, open `ios/Runner.xcworkspace` in Xcode,
choose your Apple ID team under *Signing & Capabilities*, connect the
phone, and run `flutter run`.

## Project Structure

``` text
lib/
├── core/
│   ├── constants/    app-wide constants, colours, strings
│   ├── providers/    Riverpod providers
│   ├── routes/       go_router configuration
│   ├── services/     Firebase, repository and matching logic
│   └── theme/
├── features/
│   ├── admin/            web admin dashboard
│   ├── authentication/   login, register, password reset
│   ├── claims/           ownership verification
│   ├── found_items/      report a found item
│   ├── home/
│   ├── item_details/
│   ├── lost_items/       report a lost item
│   ├── matching/         potential matches
│   ├── notifications/
│   ├── profile/          profile and "My Reports"
│   └── search/
└── shared/
    ├── models/
    └── widgets/
```

## How Smart Matching Works

`lib/core/services/matching_service.dart` gives each lost/found pair a
score out of 100:

| Attribute | Weight |
|---|---|
| Category | 25 |
| Item name and description keywords | 25 |
| Brand | 15 |
| Location | 15 |
| Colour | 10 |
| Date proximity | 10 |

Pairs that score at or above the threshold appear as potential matches.

## Testing

### Screenshot tour
`tool/screen_tour.py` fills the Firebase emulators with sample data,
walks through every main screen of the iOS app on a simulator and saves
a screenshot of each, which is useful for reviewing UI changes. It never
touches the live project.

``` bash
open -a Simulator
firebase emulators:exec --project reclaim-c4695 --only auth,firestore \
  "python3 tool/screen_tour.py <simulator-id> /tmp/reclaim-tour"
```

### Unit and widget tests

``` bash
flutter analyze
flutter test
```

Latest run: **62 tests passing** and **no analyzer issues**.

### Security-rule tests
`firestore-tests/` checks `firestore.rules` against the local Firestore
emulator (needs Node.js and Java; free, no real project is touched):

``` bash
npm --prefix firestore-tests install
firebase emulators:exec --project demo-reclaim --only firestore "npm --prefix firestore-tests test"
```

Latest run: **40 rule tests passing**.

## Roadmap

Planned work, all within the free Firebase plan:

1.  **Done:** iOS-only cleanup (Android, web and remote-push code
    removed; photo-library permission added).
2.  **Done:** Move item photos from Firebase Storage into Firestore.
3.  **Done:** Fix Firestore security rules (chat messages,
    notifications, chat creation, activity log) and remove the demo
    role-switch button; rules are covered by emulator tests.
4.  **Done:** Match in both directions and notify only the lost
    report's owner with an iOS banner; notify claimants of claim
    decisions.
5.  **Done:** Edit, delete and "mark as recovered" for a user's own
    reports. Still to do: let the finder record a hidden detail for
    ownership checks.
6.  **Done:** Add automated tests for matching.
7.  Decide on in-app chat (Firestore-based) and on-device image
    analysis, or keep them as future work.

## Security Notes

-   `GoogleService-Info.plist`, `.env` files and signing keys are in
    `.gitignore`; never commit them.
-   The PSG Tech email check in the app is for convenience; access
    control is enforced by `firestore.rules`.
-   Users cannot give themselves the Admin role, edit others' reports,
    send others arbitrary notifications, or read chats they are not
    part of. Chat messages live under `chats/{chatId}/messages`.
-   College ID photos live in `idPhotos/{uid}`, readable only by that
    user and admins. Users cannot mark themselves verified; only an
    admin can, and verifying or rejecting deletes the photo.

## License

No license has been specified. All rights remain with the copyright
holder, and reuse is not granted by default.

# ReClaim --- Lost & Found App

ReClaim is a Flutter-based lost-and-found application designed to help
people report missing belongings and discover potentially matching found
items. It uses Firebase for authentication and cloud storage, with
client-side matching to surface potential matches in the app.

## Features

-   **User authentication** with Firebase Authentication.
-   **PSG Tech email validation**: registration and login validate
    institutional email addresses ending in `@psgtech.ac.in`.
-   **Lost-item reports** stored in Cloud Firestore.
-   **Found-item reports** stored in Cloud Firestore.
-   **Smart matching** that compares report details such as category,
    title/description, brand, colour, location, and date.
-   **Home-feed match cards** that update as report data changes.
-   **In-app new-match alerts** with a **View Match** action when a new
    potential match is detected during the active app session.
-   **Potential-match screens** for inspecting candidate matches.
-   **Firebase Cloud Messaging groundwork** for push notifications;
    end-to-end background push delivery is not yet confirmed.

## Tech Stack

-   **Frontend:** Flutter, Dart
-   **State management:** Riverpod
-   **Backend services:** Firebase Authentication, Cloud Firestore,
    Firebase Cloud Messaging (notification setup in progress)
-   **Platforms:** Flutter web and Android development targets

## How Smart Matching Works

ReClaim calculates a match score by comparing details from lost and
found reports. The matching service considers fields such as:

-   Item category
-   Item name and description
-   Brand
-   Colour
-   Location
-   Date

Reports that meet the configured match threshold can appear as potential
matches in the app. Matching is currently performed on the client using
the existing Dart matching service.

## In-App Match Alerts

When a newly detected potential match appears while ReClaim is open, the
app can display an in-app snackbar with a **View Match** action. The
alert logic tracks match pairs during the session to avoid repeatedly
alerting for the same match and to avoid alerting on matches already
present during initial setup.

This is an **in-app alert**, not a guarantee of a system-level browser
or mobile push notification. Background push delivery requires a
functioning message-sending backend and complete platform configuration;
this has not been verified end to end.

## Firebase Setup

To run your own instance, create a Firebase project and configure the
Flutter app for it.

1.  Install the Flutter SDK and verify your setup with `flutter doctor`.
2.  Configure Firebase for the platforms you intend to run.
3.  Add the platform-specific Firebase configuration files using the
    official FlutterFire setup process.
4.  Enable **Email/Password** authentication in Firebase Authentication.
5.  Create a Cloud Firestore database and configure security rules
    appropriate for your application.
6.  Confirm that the app's institutional email validation matches your
    intended domain.

> **Security note:** Never commit private keys, service-account JSON
> files, access tokens, or other secrets to GitHub. Review Firebase
> security rules before using real user data. Client-side email
> validation is a user-experience check and should not replace
> appropriate security rules or trusted backend validation.

## Run Locally

Clone the repository and enter the project directory:

``` bash
git clone <YOUR_REPOSITORY_URL>
cd ReClaim
```

Install dependencies:

``` bash
flutter pub get
```

Run static analysis and tests:

``` bash
flutter analyze
flutter test
```

Run the web app in Chrome:

``` bash
flutter run -d chrome
```

For Android, start an emulator or connect a device and run:

``` bash
flutter devices
flutter run
```

Your local Firebase configuration must be in place before using
Firebase-backed features.

## Project Structure

The main application code is organized under `lib/`:

``` text
lib/
├── core/
│   ├── constants/
│   ├── providers/
│   └── services/
├── features/
│   ├── home/
│   ├── item_details/
│   └── matching/
└── shared/
    └── models/
```

-   `core/services/` contains application services, including matching,
    repository, and notification logic.
-   `core/providers/` contains Riverpod providers used to expose
    reactive application data.
-   `features/` contains feature-specific screens and presentation
    logic.
-   `shared/models/` contains data models used across features.

## Testing

Run the complete Flutter test suite with:

``` bash
flutter test
```

Run static analysis with:

``` bash
flutter analyze
```

The latest development run reported **44 passing tests** and no Flutter
analyzer issues after the in-app match-alert changes. Results may differ
as the project evolves.

## Current Status

-   Lost/found report matching and home-feed match cards: implemented.
-   In-app alerts for newly detected matches while the app is open:
    implemented and manually tested.
-   Firebase Authentication and Firestore integration: implemented for
    the app's current scope.
-   Browser/mobile background push notifications: configuration and
    delivery still require further verification.
-   Cloud Functions deployment: not performed.

## Contributing

Suggestions and bug reports are welcome. Before submitting changes, run:

``` bash
flutter analyze
flutter test
```

## License

No license has been specified yet. Unless a license is added to this
repository, all rights remain with the copyright holder and reuse is not
automatically granted.

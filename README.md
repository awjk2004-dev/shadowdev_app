# ShadowDev

An Arabic Flutter app for a personal growth system, with a right-to-left interface and a feature-based project structure.

## Project structure

```text
lib/
├── core/
│   ├── network/
│   │   └── api_client.dart
│   └── theme/
│       └── app_theme.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   └── screens/
│   │       ├── splash_screen.dart
│   │       ├── login_screen.dart
│   │       └── register_screen.dart
│   ├── home/
│   │   └── screens/
│   │       └── home_screen.dart
│   ├── tasks/
│   ├── skills/
│   └── body/
└── main.dart
```

- `core/`: Shared services and styling, including the API client, theme, and colors.
- `features/`: Feature-specific files for authentication, tasks, skills, ranks, and body tracking.
- `main.dart`: The app entry point. It checks for a saved access token to choose the initial screen.

## Implemented features

### Navigation and authentication

- The splash screen displays the message “You have been chosen as a Player” and a “Begin Awakening” button that opens the login screen.
- The login screen accepts a username and password and sends the request through `ApiClient`.
- After a successful login, the access token is stored securely and the app navigates to the home screen.
- The login screen includes a link to create an account.
- The registration screen is currently a UI prototype only. It does not submit registration requests because the backend registration contract and required fields have not been confirmed.

### Design and assets

- The app uses a dark holographic interface with a `#0A0A0F` background, slate surfaces, and a consistent cyan neon accent (`#00F0FF`), without purple accents.
- Panels, fields, and buttons use chamfered borders. Inactive states use gray dashed borders. The interface avoids blur and heavy shadows.
- The home screen displays player status, an attribute chart, level experience, and the daily streak, with navigation to tasks, skills, ranks, and body tracking.
- The skill tree loads its nodes and unlock state from the authenticated backend. The server validates prerequisites, deducts SP, and persists unlocks; the client displays connected, pannable and zoomable nodes. The rank screen displays ranks from E to S, and tasks support categorization, completion, and swipe-based editing.
- The interface is Arabic and right-to-left, with concise technical system labels. Android launcher icons are generated from `assets/images/logo.png`.

### Reminders and Android home widget

- Users can enable a local daily reminder and choose its time from the profile screen. Notification permission is requested only when reminders are enabled, and scheduled reminders are restored after the device restarts.
- The Android home widget displays the player's streak and weekdays. It refreshes after the app fetches player data, and its **Refresh** button triggers a background fetch without opening the app. Add it from the phone launcher's Widgets menu after installing and opening the app at least once.
- Android may defer background work while the device is idle or offline. The widget shows an error status if the refresh request fails; open the app to refresh through the normal foreground flow.
- Persisting task difficulty and rewards requires the backend to accept `difficulty` (`easy`, `medium`, `hard`) and `xp_reward` (`10`, `25`, `50`) when creating and updating tasks. The backend source code is not part of this repository, so compatibility with this contract cannot be verified here.

### Backend connection

- The backend seeds the skill-tree catalog through its Alembic migration. Existing players receive 10 starting SP plus one SP per level already reached; future level-ups award one SP. Resetting the tree on the server re-locks skills and restores all earned SP.
- Apply backend migrations before using the connected skill tree. The skill tree requires `GET /api/v1/skills/me`, `POST /api/v1/skills/me/{skill_id}/unlock`, `POST /api/v1/skills/me/reset`, and `GET /api/v1/player/me` with `skill_points`.

- `lib/core/network/api_client.dart` uses the following development API URL by default:

  ```text
  http://10.94.11.66:8000/api/v1
  ```

- Override the URL at build/run time without changing the source:

  ```bash
  flutter run --dart-define=API_URL=http://<HOST_IP>:8000/api/v1
  ```

- Android internet permission is enabled, and cleartext HTTP is allowed for the local development server.
- The phone and computer must be on the same network, and the backend must be listening on port `8000`. The address `10.94.11.66` is a private address and may change; update it or pass the current address through `API_URL`.
- When the phone is connected over USB, an alternative is to run `adb reverse tcp:8000 tcp:8000` and use `http://localhost:8000/api/v1`.
- Before releasing the app, configure a production API URL, use HTTPS, and remove the broad cleartext HTTP allowance.

## Design and implementation notes

- **Interface:** Lightweight vector components and drawn borders are used instead of background images and blur effects to reduce rendering cost on the phone.
- **App icon:** Android `mipmap` files provide the launcher icon and do not update automatically when the Flutter image changes. After updating `assets/images/logo.png`, regenerate the icons with `dart run flutter_launcher_icons`.
- **Server URL:** A computer's local network address is used because the app runs on a physical phone while the backend runs on the computer. On the phone, `localhost` refers to the phone itself, not the computer. `10.0.2.2` is generally intended for the Android emulator. A USB tunnel such as `adb reverse` can be used when needed.
- **Login:** The login endpoint uses URL-encoded form data as required by the backend's OAuth2-style login contract. The backend remains responsible for validating credentials and issuing tokens.

## Validation and running

- `flutter analyze` has been run on the login and splash screens after the changes, with no analysis issues reported at that time.
- The app was built and installed on a connected Android phone, then restarted.
- The login endpoint was confirmed to respond from the development computer. A real login with an account was not performed, and account registration was not tested.

To run the app on a connected phone:

```bash
flutter devices
flutter run -d <device-id>
```

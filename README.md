# Exness Rewards Flutter App

Flutter version of the Exness Rewards mobile application, converted from React Native.

## Project Structure

```
lib/
├── config/          # Configuration files (API endpoints, etc.)
├── models/          # Data models (Venue, User, Event, etc.)
├── providers/       # State management (Auth, Theme, Location, Favorites)
├── screens/         # UI screens
├── services/        # API service layer
├── utils/           # Utility functions (geo calculations, icons, etc.)
├── widgets/         # Reusable widgets
└── main.dart        # App entry point
```

## Setup

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. The app talks to the VPS API at `http://217.217.227.183/api` by default.
   Override for local development:
```bash
flutter run --dart-define=API_URL=http://localhost:8000
```

3. **Configure Google Maps API Key (Required for iOS):**
   
   ⚠️ **Security Best Practice**: Never commit API keys to version control!
   
   a. Get a Google Maps API key:
   - Go to [Google Cloud Console](https://console.cloud.google.com/google/maps-apis)
   - Create a new project or select an existing one
   - Enable "Maps SDK for iOS"
   - Create credentials (API Key)
   - **IMPORTANT**: Restrict the key to your iOS bundle ID (e.g., `com.exness.rewardFlutter`)
   - Set usage quotas to prevent abuse
   
   b. Add the API key securely:
   
   **Recommended (Most Secure):**
   ```bash
   # Copy the example file
   cp ios/Runner/Secrets.swift.example ios/Runner/Secrets.swift
   
   # Edit Secrets.swift and add your actual API key
   # This file is gitignored and won't be committed
   ```
   
   **Alternative (Less Secure):**
   - Add to `ios/Runner/Info.plist` (can be extracted from IPA)
   - Or use environment variable: `GOOGLE_MAPS_API_KEY`
   
   **Why Secrets.swift?**
   - It's gitignored (won't be committed to version control)
   - More secure than Info.plist (which is bundled in the app)
   - Still extractable from IPA, but API key restrictions protect you

4. Run the app:
```bash
flutter run
```

Local web:

```bash
flutter run -d chrome
```

## Deploy the web app

`flutter build web` produces a static site in `build/web/`. Serve that folder with nginx, Caddy, or any static host. The default API URL is already `http://217.217.227.183/api`; override only if the backend is elsewhere.

### Build

Root of the site (`/`):

```bash
cd reward_flutter
flutter pub get
flutter build web --release
```

On the shared VPS the CMS already occupies `/`, so build with a subpath:

```bash
flutter build web --release --base-href /app/
```

`--base-href` must match the public URL path and end with `/`.

To point at another API:

```bash
flutter build web --release --base-href /app/ --dart-define=API_URL=https://your.domain/api
```

### Host on the shared VPS (`/app/`)

Copy `build/web/` to `/var/www/reward_flutter/` on `217.217.227.183`. restk nginx serves it from the drop-in `/etc/nginx/conf.d/exness-reward.conf`:

```nginx
location /app/ {
    alias /var/www/reward_flutter/;
    index index.html;
}
```

Reload nginx after installing or changing the drop-in. Do not overwrite the CMS `dist`.

- CMS: `http://217.217.227.183/`
- Flutter app: `http://217.217.227.183/app/`

The app uses hash routes (`#/map`, `#/login`), so nginx does not need SPA `try_files`.

Example upload:

```bash
scp -r build/web/* user@217.217.227.183:/var/www/reward_flutter/
```

After each deploy, hard-refresh the browser so `main.dart.js` is not served from cache.

### Google Maps (web)

Web uses the Maps **JavaScript** API, not the iOS/Android SDKs. The script tag lives in `web/index.html`.

1. Enable **Maps JavaScript API** on the key.
2. If the key is HTTP-referrer restricted, allow `http://217.217.227.183/*` and `http://localhost:*`.
3. Rebuild after changing `web/index.html` (hot reload does not update it).

### HTTPS and geolocation

The bundle currently calls `http://217.217.227.183/api`. A site served over HTTPS will block that (mixed content). Keep web and API on HTTP, or put both on HTTPS and rebuild with `--dart-define=API_URL=https://your.domain/api`.

Browser geolocation also requires a [secure context](https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts): `localhost` or HTTPS. It will not work on plain `http://217.217.227.183`.

## Features

- ✅ Authentication (Login/Register)
- ✅ Venue listing and details
- ✅ Map view with markers
- ✅ Events calendar
- ✅ Favorites management
- ✅ Dark/Light theme
- ✅ Location services

## Dependencies

- `provider` - State management
- `go_router` - Navigation
- `http` - API calls
- `google_maps_flutter` - Maps
- `geolocator` - Location services
- `shared_preferences` - Local storage
- `cached_network_image` - Image loading
- `google_fonts` - Custom fonts

## Screens to Implement

The following screens need to be created (structure is ready in main.dart):

- [x] WelcomeScreen
- [ ] LoginScreen
- [ ] RegisterScreen
- [ ] VenueListScreen
- [ ] MapScreen
- [ ] EventsScreen
- [ ] ProfileScreen
- [ ] VenueDetailScreen
- [ ] SavedPlacesScreen
- [ ] EventDetailScreen

## Notes

- The app uses Provider for state management (equivalent to React Context)
- Navigation is handled by go_router
- API service is centralized in `lib/services/api_service.dart`
- All models are in `lib/models/`

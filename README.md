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

2. Configure API endpoint in `lib/config/api_config.dart`:
```dart
static const String baseUrl = 'http://34.42.207.250:8000';
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

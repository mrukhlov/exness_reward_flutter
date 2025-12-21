import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/location_provider.dart';
import 'providers/favorites_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/venue_list_screen.dart';
import 'screens/map_screen.dart';
import 'screens/events_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/venue_detail_screen.dart';
import 'screens/saved_places_screen.dart';
import 'screens/event_detail_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (context) => FavoritesProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, authProvider, previous) =>
              previous ?? FavoritesProvider(authProvider),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'Exness Rewards',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFFD00B),
                brightness: Brightness.light,
              ),
              textTheme: GoogleFonts.manropeTextTheme(),
              appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFFD00B),
                brightness: Brightness.dark,
              ),
              textTheme: GoogleFonts.manropeTextTheme(
                ThemeData.dark().textTheme,
              ),
              appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
            ),
            themeMode: themeProvider.themeMode,
            routerConfig: _createRouter(context),
          );
        },
      ),
    );
  }
}

GoRouter _createRouter(BuildContext context) {
  return GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainTabScaffold(child: child),
        routes: [
          GoRoute(
            path: '/discover',
            builder: (context, state) => const VenueListScreen(),
          ),
          GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
          GoRoute(
            path: '/events',
            builder: (context, state) => const EventsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/venue/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VenueDetailScreen(venueId: id);
        },
      ),
      GoRoute(
        path: '/saved-places',
        builder: (context, state) => const SavedPlacesScreen(),
      ),
      GoRoute(
        path: '/event/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EventDetailScreen(eventId: id);
        },
      ),
    ],
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      final isAuthRoute =
          state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (authProvider.isLoading) {
        return null; // Still loading, don't redirect
      }

      if (!isAuthenticated && !isAuthRoute) {
        return '/welcome';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/discover';
      }

      return null;
    },
  );
}

class MainTabScaffold extends StatelessWidget {
  final Widget child;

  const MainTabScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onTabTapped(context, index),
        backgroundColor: isDark ? Colors.black : Colors.white,
        selectedItemColor: const Color(0xFFFFD00B),
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'DISCOVER'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'MAP'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'EVENTS'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
        ],
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/discover') return 0;
    if (location == '/map') return 1;
    if (location == '/events') return 2;
    if (location == '/profile') return 3;
    return 0;
  }

  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/discover');
        break;
      case 1:
        context.go('/map');
        break;
      case 2:
        context.go('/events');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}

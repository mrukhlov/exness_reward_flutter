import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/location_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/venues_provider.dart';
import 'providers/events_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/invite_screen.dart';
import 'screens/venue_list_screen.dart';
import 'screens/map_screen.dart';
import 'screens/events_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/venue_detail_screen.dart';
import 'screens/saved_places_screen.dart';
import 'screens/event_detail_screen.dart';

GoRouter? _router;

GoRouter _getRouter(BuildContext context) {
  _router ??= _createRouter(context);
  return _router!;
}

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
        ChangeNotifierProvider(create: (_) => VenuesProvider()),
        ChangeNotifierProvider(create: (_) => EventsProvider()),
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (context) => FavoritesProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, authProvider, previous) =>
              previous ?? FavoritesProvider(authProvider),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Get or create router once and reuse it
          final router = _getRouter(context);
          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return MaterialApp.router(
                key: ValueKey(
                  themeProvider.themeMode,
                ), // Key to force rebuild on theme change
                title: 'Exness Rewards',
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.light,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFFFFD00B),
                    brightness: Brightness.light,
                  ),
                  fontFamily: 'Manrope',
                  textTheme: const TextTheme().apply(fontFamily: 'Manrope'),
                  appBarTheme: const AppBarTheme(
                    centerTitle: false,
                    elevation: 0,
                  ),
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.dark,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFFFFD00B),
                    brightness: Brightness.dark,
                  ),
                  fontFamily: 'Manrope',
                  textTheme: ThemeData.dark().textTheme.apply(
                    fontFamily: 'Manrope',
                  ),
                  appBarTheme: const AppBarTheme(
                    centerTitle: false,
                    elevation: 0,
                  ),
                ),
                themeMode: themeProvider.themeMode,
                routerConfig: router,
              );
            },
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
      GoRoute(
        path: '/invite',
        builder: (context, state) => const InviteScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainTabScaffold(child: child),
        routes: [
          GoRoute(
            path: '/discover',
            builder: (context, state) => const VenueListScreen(),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) {
              final venueId = state.uri.queryParameters['venueId'];
              return MapScreen(selectedVenueId: venueId);
            },
          ),
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
      final matchedLocation = state.matchedLocation;

      // Auth routes that should redirect authenticated users to /discover
      final isAuthRoute =
          matchedLocation == '/welcome' ||
          matchedLocation == '/login' ||
          matchedLocation == '/register';

      // /invite is accessible to authenticated users, so don't treat it as auth route

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
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BottomNavItem(
              icon: Icons.explore,
              label: 'DISCOVER',
              isSelected: currentIndex == 0,
              isDark: isDark,
              onTap: () => context.go('/discover'),
            ),
            _BottomNavItem(
              icon: Icons.map,
              label: 'MAP',
              isSelected: currentIndex == 1,
              isDark: isDark,
              onTap: () => context.go('/map'),
            ),
            _BottomNavItem(
              icon: Icons.event,
              label: 'EVENTS',
              isSelected: currentIndex == 2,
              isDark: isDark,
              onTap: () {
                final eventsProvider = Provider.of<EventsProvider>(
                  context,
                  listen: false,
                );
                if (eventsProvider.hasBeenVisited &&
                    eventsProvider.lastSelectedDate != null) {
                  final selectedDateStr = DateFormat(
                    'yyyy-MM-dd',
                  ).format(eventsProvider.lastSelectedDate!);
                  context.go('/events?selectedDate=$selectedDateStr');
                } else {
                  context.go('/events');
                }
              },
            ),
            _BottomNavItem(
              icon: Icons.person,
              label: 'PROFILE',
              isSelected: currentIndex == 3,
              isDark: isDark,
              onTap: () => context.go('/profile'),
            ),
          ],
        ),
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
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? (isDark ? const Color(0xFFFFD00B) : Colors.black)
        : const Color(0xFF9CA3AF);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

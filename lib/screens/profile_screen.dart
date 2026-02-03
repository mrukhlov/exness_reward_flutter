import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/profile_id_card.dart';
import '../widgets/profile/profile_stats.dart';
import '../widgets/profile/profile_menu_item.dart';
import '../widgets/profile/profile_map_style_toggle.dart';
import '../widgets/profile/profile_logout_button.dart';
import '../widgets/profile/profile_qr_modal.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showQR = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.user;

    final qrCodeUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${user?.id ?? 'EXNESS_REWARDS_MEMBER'}';

    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
          body: SafeArea(
            child: Column(
              children: [
                ProfileHeader(isDark: isDark),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 100,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        ProfileIdCard(
                          user: user,
                          qrCodeUrl: qrCodeUrl,
                          isDark: isDark,
                          onQrTap: () => setState(() => _showQR = true),
                        ),
                        const SizedBox(height: 24),
                        ProfileStats(
                          savedVenuesCount: favoritesProvider.favorites.length,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 32),
                        // Activity Section
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'My Activity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.normal,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF121212)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: ProfileMenuItem(
                            icon: Icons.favorite,
                            title: 'Saved Places',
                            subtitle: 'View your favorite spots',
                            onTap: () => context.go('/saved-places'),
                            isLast: true,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // App Settings
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'App Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.normal,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF121212)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            children: [
                              ProfileMapStyleToggle(
                                isDark: isDark,
                                useCustomMapStyle:
                                    themeProvider.useCustomMapStyle,
                                onToggle: () => themeProvider.toggleMapStyle(),
                              ),
                              ProfileMenuItem(
                                icon: Icons.help,
                                title: 'Help & Support',
                                iconRight: Icons.open_in_new,
                                isLast: true,
                                isDark: isDark,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ProfileLogoutButton(
                          isDark: isDark,
                          onTap: () {
                            authProvider.logout();
                            context.go('/welcome');
                          },
                        ),
                        const SizedBox(height: 16),
                        // Version
                        Center(
                          child: Text(
                            'Version 1.0.2',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // QR Modal
        if (_showQR)
          ProfileQrModal(
            qrCodeUrl: qrCodeUrl,
            user: user,
            isDark: isDark,
            onClose: () => setState(() => _showQR = false),
          ),
      ],
    );
  }
}

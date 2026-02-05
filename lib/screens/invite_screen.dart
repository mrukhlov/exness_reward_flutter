import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/auth/auth_widgets.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      return 'Please enter an email address';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    final error = _validateEmail();
    if (error != null) {
      _showSnackBar(error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      await apiService.sendInvite(_emailController.text.trim());
      if (mounted) {
        _showSnackBar('Invitation sent successfully!', isSuccess: true);
        _emailController.clear();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const yellowColor = Color(0xFFFFD00B);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    // Logo and brand name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.change_history,
                          size: 36,
                          color: yellowColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'exness',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Title and subtitle
                    Column(
                      children: [
                        const Text(
                          'Invite Partner',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send an invitation to join the rewards program',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    AuthTextField(
                      label: 'Partner Email',
                      controller: _emailController,
                      icon: Icons.mail,
                      hintText: 'partner@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textCapitalization: TextCapitalization.none,
                    ),
                    const SizedBox(height: 32),
                    // Button with yellow background
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: yellowColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              )
                            : const Text(
                                'Send Invitation',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            // Back button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/profile');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

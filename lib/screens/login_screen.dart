import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateForm() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      return 'Please enter both email and password';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    final error = _validateForm();
    if (error != null) {
      _showSnackBar(error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.login(_emailController.text, _passwordController.text);
      if (mounted) context.go('/discover');
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleOktaLogin() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.loginWithOkta();
      if (mounted) context.go('/discover');
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                    // Logo and brand name in yellow
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
                    // Title and subtitle in yellow
                    Column(
                      children: [
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to access your rewards',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    AuthTextField(
                      label: 'Email',
                      controller: _emailController,
                      icon: Icons.mail,
                      hintText: 'name@exness.com',
                      keyboardType: TextInputType.emailAddress,
                      textCapitalization: TextCapitalization.none,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'Password',
                      controller: _passwordController,
                      icon: Icons.lock,
                      obscureText: true,
                      hintText: '••••••••',
                    ),
                    const SizedBox(height: 16),
                    // Forgot Password in yellow
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password flow
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: yellowColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                                'Log In',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // OR Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Okta Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleOktaLogin,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          Icons.login,
                          size: 24,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        label: Text(
                          'Log in with Exness Okta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Footer link with yellow
                    // Padding(
                    //   padding: const EdgeInsets.only(bottom: 40),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.center,
                    //     children: [
                    //       Text(
                    //         "Don't have an account? ",
                    //         style: TextStyle(
                    //           fontSize: 14,
                    //           color: isDark
                    //               ? Colors.grey.shade400
                    //               : Colors.grey.shade600,
                    //         ),
                    //       ),
                    //       TextButton(
                    //         onPressed: () => context.go('/register'),
                    //         child: const Text(
                    //           'Sign Up',
                    //           style: TextStyle(
                    //             color: yellowColor,
                    //             fontWeight: FontWeight.bold,
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
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
                    context.go('/welcome');
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

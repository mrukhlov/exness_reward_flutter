import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateForm() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      return 'Please fill in all fields';
    }
    if (_passwordController.text.length < 6) {
      return 'Password must be at least 6 characters';
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
      await authProvider.register(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
      );
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

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                const AuthHeader(),
                const SizedBox(height: 32),
                const AuthTitleSection(
                  title: 'Create Account',
                  subtitle: 'Join the rewards program',
                ),
                const SizedBox(height: 32),
                AuthTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  icon: Icons.person,
                  hintText: 'John Doe',
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 32),
                AuthPrimaryButton(
                  label: 'Sign Up',
                  onPressed: _handleSubmit,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 40),
                AuthFooterLink(
                  promptText: 'Already have an account? ',
                  linkLabel: 'Log In',
                  onTap: () => context.go('/login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

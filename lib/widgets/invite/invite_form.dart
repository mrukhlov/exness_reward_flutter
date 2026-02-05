import 'package:flutter/material.dart';
import '../auth/auth_widgets.dart';

class InviteForm extends StatelessWidget {
  final TextEditingController emailController;
  final bool isLoading;
  final bool isLimitReached;
  final VoidCallback onSubmit;

  const InviteForm({
    super.key,
    required this.emailController,
    required this.isLoading,
    required this.isLimitReached,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    const yellowColor = Color(0xFFFFD00B);

    return Column(
      children: [
        AuthTextField(
          label: 'Partner Email',
          controller: emailController,
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
            onPressed: (isLoading || isLimitReached) ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: yellowColor,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(
                    isLimitReached
                        ? 'Limit Reached (2 invites)'
                        : 'Send Invitation',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

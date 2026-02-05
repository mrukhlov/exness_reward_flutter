import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../widgets/auth/auth_widgets.dart';
import '../models/invite.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingInvites = false;
  List<Invite> _invites = [];
  final Set<String> _revokingInviteIds = {};

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadInvites() async {
    setState(() => _isLoadingInvites = true);
    try {
      final apiService = ApiService();
      final invites = await apiService.getMyInvites();
      if (mounted) {
        setState(() {
          _invites = invites;
        });
      }
    } catch (e) {
      // Log error for debugging
      print('[InviteScreen] Error loading invites: $e');
      if (mounted) {
        setState(() {
          _invites = [];
        });
        // Show error message to user
        _showSnackBar(
          'Failed to load invites: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingInvites = false);
      }
    }
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
        // Refresh invites list
        _loadInvites();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeInvite(Invite invite) async {
    if (invite.used || invite.isExpired || invite.revoked) return;

    setState(() => _revokingInviteIds.add(invite.id));

    try {
      final apiService = ApiService();
      await apiService.revokeInvite(invite.id);
      if (mounted) {
        _showSnackBar('Invite revoked successfully', isSuccess: true);
        // Refresh invites list
        _loadInvites();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _revokingInviteIds.remove(invite.id));
      }
    }
  }

  Future<void> _copyInviteUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      _showSnackBar('Invite link copied to clipboard!', isSuccess: true);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const yellowColor = Color(0xFFFFD00B);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header matching saved places style
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/profile');
                      }
                    },
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Invite Partner',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
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
                      const SizedBox(height: 8),
                      // Check if user has reached the limit of 2 invites (pending + accepted)
                      Builder(
                        builder: (context) {
                          // Count only non-revoked invites
                          final pendingInvitesCount = _invites
                              .where((invite) => invite.isPending)
                              .length;
                          final acceptedInvitesCount = _invites
                              .where((invite) => invite.used && !invite.revoked)
                              .length;
                          final totalActiveInvitesCount =
                              pendingInvitesCount + acceptedInvitesCount;
                          final isLimitReached = totalActiveInvitesCount >= 2;

                          return Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Invites: $totalActiveInvitesCount/2',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: totalActiveInvitesCount >= 2
                                        ? Colors.orange
                                        : isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              if (isLimitReached) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'You have reached the limit of 2 invites. Please revoke a pending invite to send a new invitation.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
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
                                  onPressed: (_isLoading || isLimitReached)
                                      ? null
                                      : _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: yellowColor,
                                    foregroundColor: Colors.black,
                                    disabledBackgroundColor:
                                        Colors.grey.shade300,
                                    disabledForegroundColor:
                                        Colors.grey.shade600,
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
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.black,
                                                ),
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
                        },
                      ),
                      const SizedBox(height: 32),
                      // Invites List Section
                      if (_invites.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'My Invites',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._invites.map(
                          (invite) => _buildInviteCard(invite, isDark),
                        ),
                      ],
                      if (_isLoadingInvites) ...[
                        const SizedBox(height: 16),
                        const Center(child: CircularProgressIndicator()),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCard(Invite invite, bool isDark) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    const yellowColor = Color(0xFFFFD00B);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (invite.revoked) {
      statusColor = Colors.red;
      statusText = 'Revoked';
      statusIcon = Icons.cancel;
    } else if (invite.used) {
      statusColor = Colors.green;
      statusText = 'Accepted';
      statusIcon = Icons.check_circle;
    } else if (invite.isExpired) {
      statusColor = Colors.grey;
      statusText = 'Expired';
      statusIcon = Icons.cancel;
    } else {
      statusColor = yellowColor;
      statusText = 'Pending';
      statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.email,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Expires: ${dateFormat.format(invite.expiresAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    if (invite.used && invite.usedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Accepted on ${dateFormat.format(invite.usedAt!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Action buttons column
              Column(
                children: [
                  // Revoke button for pending invites (not used, not expired, not already revoked)
                  if (!invite.used && !invite.isExpired && !invite.revoked)
                    IconButton(
                      icon: _revokingInviteIds.contains(invite.id)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.red,
                                ),
                              ),
                            )
                          : const Icon(Icons.close, color: Colors.red),
                      onPressed: _revokingInviteIds.contains(invite.id)
                          ? null
                          : () => _revokeInvite(invite),
                      tooltip: 'Revoke invite',
                    ),
                ],
              ),
            ],
          ),
          // Invite URL display section
          if (!invite.revoked) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      invite.inviteUrl,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: Colors.blue),
                    onPressed: () => _copyInviteUrl(invite.inviteUrl),
                    tooltip: 'Copy link',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

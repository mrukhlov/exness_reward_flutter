import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../services/api_service.dart';
import '../models/invite.dart';
import '../widgets/invite/invite_card.dart';
import '../widgets/invite/invite_stats.dart';
import '../widgets/invite/invite_form.dart';

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
                    'Invite Spouse',
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
                      // Stats and Form Section
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
                              InviteStats(
                                pendingCount: pendingInvitesCount,
                                acceptedCount: acceptedInvitesCount,
                                isDark: isDark,
                              ),
                              InviteForm(
                                emailController: _emailController,
                                isLoading: _isLoading,
                                isLimitReached: isLimitReached,
                                onSubmit: _handleSubmit,
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
                          (invite) => InviteCard(
                            invite: invite,
                            isDark: isDark,
                            isRevoking: _revokingInviteIds.contains(invite.id),
                            onRevoke: () => _revokeInvite(invite),
                            onCopyUrl: () => _copyInviteUrl(invite.inviteUrl),
                          ),
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
}

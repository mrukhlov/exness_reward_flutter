import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/invite.dart';

class InviteCard extends StatelessWidget {
  final Invite invite;
  final bool isDark;
  final bool isRevoking;
  final VoidCallback? onRevoke;
  final VoidCallback? onCopyUrl;

  const InviteCard({
    super.key,
    required this.invite,
    required this.isDark,
    this.isRevoking = false,
    this.onRevoke,
    this.onCopyUrl,
  });

  @override
  Widget build(BuildContext context) {
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
                      icon: isRevoking
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
                      onPressed: isRevoking ? null : onRevoke,
                      tooltip: 'Revoke invite',
                    ),
                  // Copy URL button (show for all invites except revoked)
                  // if (!invite.revoked)
                  //   IconButton(e
                  //     icon: const Icon(Icons.copy, color: Colors.blue),
                  //     onPressed: onCopyUrl,
                  //     tooltip: 'Copy invite link',
                  //   ),
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
                    onPressed: onCopyUrl,
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

class Invite {
  final String id;
  final String email;
  final String token;
  final bool used;
  final bool revoked;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? usedAt;
  final DateTime? revokedAt;
  final String inviteUrl;

  Invite({
    required this.id,
    required this.email,
    required this.token,
    required this.used,
    required this.revoked,
    required this.expiresAt,
    required this.createdAt,
    required this.inviteUrl,
    this.usedAt,
    this.revokedAt,
  });

  factory Invite.fromJson(Map<String, dynamic> json) {
    return Invite(
      id: json['id'] as String,
      email: json['email'] as String,
      token: json['token'] as String,
      used: json['used'] as bool,
      revoked: json['revoked'] as bool? ?? false,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      inviteUrl: json['invite_url'] as String,
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'] as String)
          : null,
      revokedAt: json['revoked_at'] != null
          ? DateTime.parse(json['revoked_at'] as String)
          : null,
    );
  }

  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get isPending => !used && !revoked && !isExpired;
}

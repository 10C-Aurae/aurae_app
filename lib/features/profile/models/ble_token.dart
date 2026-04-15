class BleToken {
  final String token;
  final String expiresAt;

  BleToken({required this.token, required this.expiresAt});

  factory BleToken.fromJson(Map<String, dynamic> json) {
    return BleToken(
      token: json['token'] ?? '',
      expiresAt: json['expires_at'] ?? '',
    );
  }
}

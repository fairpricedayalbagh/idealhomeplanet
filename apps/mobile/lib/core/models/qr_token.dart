class QrToken {
  final String id;
  final String token;
  final DateTime date;
  final DateTime expiresAt;
  final String? qrImage; // base64 data URL

  QrToken({
    required this.id,
    required this.token,
    required this.date,
    required this.expiresAt,
    this.qrImage,
  });

  factory QrToken.fromJson(Map<String, dynamic> json) {
    return QrToken(
      id: json['id'] as String,
      token: json['token'] as String,
      date: DateTime.parse(json['date'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      qrImage: json['qrImage'] as String?,
    );
  }
}

import 'dart:convert';

class NetMessage {
  final String type;
  final Map<String, dynamic> payload;
  final DateTime receivedAt;

  NetMessage({required this.type, required this.payload})
    : receivedAt = DateTime.now();

  factory NetMessage.fromJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return NetMessage(
      type: map['type'] as String,
      payload: Map<String, dynamic>.from(map['payload'] as Map? ?? {}),
    );
  }

  String toJson() => jsonEncode({'type': type, 'payload': payload});

  @override
  String toString() => '[${type.toUpperCase()}] $payload';
}

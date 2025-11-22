class Message {
  final String id;
  final String role;
  final String text;
  final DateTime timestamp;
  final bool isUser;

  Message({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    required this.isUser,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final role = (json['role'] ?? 'assistant').toString();
    return Message(
      id: (json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
      role: role,
      text: (json['text'] ?? '').toString(),
      timestamp: DateTime.now(),
      isUser: role == 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'text': text,
      'isUser': isUser,
    };
  }
}
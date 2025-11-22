import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/message_model.dart';

class ChatbotApi {
  static const String baseUrl = 'https://mitran-chatbot.onrender.com';

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> createSession() async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/sessions'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create session');
  }

  Future<List<Message>> getHistory(String sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/v1/chat/history?session_id=$sessionId'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final messages = data['messages'] as List? ?? [];
      return messages.map((m) => Message.fromJson(m)).toList();
    }
    if (response.statusCode == 404) {
      // Session not found — return empty history
      return [];
    }
    throw Exception('Failed to get history');
  }

  Future<String> sendMessage(String sessionId, String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/chat/send'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'session_id': sessionId, 'text': text}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _extractReply(data);
    }
    if (response.statusCode == 404) {
      return 'Session not found. Please create a new session.';
    }
    if (response.statusCode == 429) {
      return 'Too many requests. Please wait and try again.';
    }
    throw Exception('Failed to send message');
  }

  String _extractReply(Map<String, dynamic> data) {
    if (data.containsKey('text') && data['text'] is String) return data['text'];
    if (data.containsKey('delta') && data['delta'] is String) return data['delta'];
    if (data.containsKey('content') && data['content'] is String) return data['content'];
    final msgs = data['messages'];
    if (msgs is List && msgs.isNotEmpty) {
      final last = msgs.last;
      if (last is Map && last['content'] is String) return last['content'] as String;
    }
    return '';
  }
}
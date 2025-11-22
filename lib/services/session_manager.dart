import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;

class SessionManager {
  static const String _sessionKey = 'chatbot_session_id';
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _authTokenKey = 'auth:token';
  static const String _detectSessionKey = 'detect:sessionId';
  static const String _detectLastJobKey = 'detect:lastJobId';
  static const String _uiCameraKey = 'ui:cameraPermissionGranted';
  
  Future<String?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString(_sessionKey);
    if (sid == null || sid.isEmpty) {
      debugPrint('chatbot: no session id stored');
    } else {
      debugPrint('chatbot: session id found: $sid');
    }
    return sid;
  }
  // Aliases used by web spec
  Future<String?> getSessionId() => getSession();
  
  // Save session
  Future<void> saveSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, sessionId);
    debugPrint('chatbot: session id stored: $sessionId');
  }
  Future<void> saveSessionId(String sessionId) => saveSession(sessionId);
  
  // Clear session
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    debugPrint('chatbot: session id cleared');
  }
  Future<void> clearSessionId() => clearSession();
  
  // Check if user has seen onboarding
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }
  
  // Mark onboarding as seen
  Future<void> markOnboardingAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
  
  // Clear all data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
  }

  Future<void> saveChatHistory(String sessionId, List<Map<String, dynamic>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat:history:$sessionId', jsonEncode(messages));
  }

  Future<List<Map<String, dynamic>>> getChatHistory(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('chat:history:$sessionId');
    if (str == null || str.isEmpty) return [];
    final data = jsonDecode(str);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<void> saveDetectSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_detectSessionKey, sessionId);
  }

  Future<String?> getDetectSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_detectSessionKey);
  }

  Future<void> saveLastJobId(String jobId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_detectLastJobKey, jobId);
  }

  Future<String?> getLastJobId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_detectLastJobKey);
  }

  Future<void> setCameraPermissionGranted(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_uiCameraKey, granted);
  }

  Future<bool> getCameraPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_uiCameraKey) ?? false;
  }
}
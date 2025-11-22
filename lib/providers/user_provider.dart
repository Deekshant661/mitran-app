import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

// User Profile Provider
final userProfileProvider = StreamProvider.family<UserModel, String>((ref, userId) {
  final user = ref.watch(authProvider).value;
  if (user == null) {
    return const Stream.empty();
  }
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) => UserModel.fromFirestore(doc));
});
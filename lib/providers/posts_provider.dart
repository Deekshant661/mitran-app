import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import 'auth_provider.dart';

// Posts Feed Provider
final postsProvider = StreamProvider<List<PostModel>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) {
    return const Stream.empty();
  }
  return FirebaseFirestore.instance
      .collection('posts')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList());
});
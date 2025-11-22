import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dog_model.dart';
import 'auth_provider.dart';

// Dogs Directory Provider
final dogsProvider = StreamProvider<List<DogModel>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) {
    return const Stream.empty();
  }
  return FirebaseFirestore.instance
      .collection('dogs')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => DogModel.fromFirestore(doc))
          .toList());
});

// Single Dog Provider
final dogProvider = StreamProvider.family<DogModel, String>((ref, dogId) {
  return FirebaseFirestore.instance
    .collection('dogs')
    .doc(dogId)
    .snapshots()
    .map((doc) => DogModel.fromFirestore(doc));
});
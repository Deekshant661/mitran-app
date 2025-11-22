import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/dog_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create user profile
  Future<void> createUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.userId).set(user.toMap());
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('users').doc(userId).update(updates);
  }

  // Check username uniqueness
  Future<bool> isUsernameAvailable(String username) async {
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  // Create post
  Future<String> createPost(PostModel post, String userId) async {
    final postRef = await _db.collection('posts').add(post.toMap());
    
    await _db.collection('users').doc(userId).update({
      'postIds': FieldValue.arrayUnion([postRef.id]),
    });
    
    return postRef.id;
  }

  // Delete post
  Future<void> deletePost(String postId, String userId) async {
    await _db.collection('posts').doc(postId).delete();
    
    await _db.collection('users').doc(userId).update({
      'postIds': FieldValue.arrayRemove([postId]),
    });
  }

  // Create dog record
  Future<String> createDogRecord(DogModel dog, String userId) async {
    final dogRef = await _db.collection('dogs').add(dog.toMap());
    
    await _db.collection('users').doc(userId).update({
      'dogIds': FieldValue.arrayUnion([dogRef.id]),
    });
    
    return dogRef.id;
  }

  // Update dog record
  Future<void> updateDogRecord(String dogId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('dogs').doc(dogId).update(updates);
  }

  // Delete dog record
  Future<void> deleteDogRecord(String dogId, String userId) async {
    await _db.collection('dogs').doc(dogId).delete();
    
    await _db.collection('users').doc(userId).update({
      'dogIds': FieldValue.arrayRemove([dogId]),
    });
  }
}
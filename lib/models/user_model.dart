import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String email;
  final String username;
  final String profilePictureUrl;
  final ContactInfo contactInfo;
  final String city;
  final String area;
  final String userType;
  final List<String> postIds;
  final List<String> dogIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.userId,
    required this.email,
    required this.username,
    required this.profilePictureUrl,
    required this.contactInfo,
    required this.city,
    required this.area,
    required this.userType,
    required this.postIds,
    required this.dogIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      profilePictureUrl: data['profilePictureUrl'] ?? '',
      contactInfo: ContactInfo.fromMap(data['contactInfo'] ?? {}),
      city: data['city'] ?? '',
      area: data['area'] ?? '',
      userType: data['userType'] ?? '',
      postIds: List<String>.from(data['postIds'] ?? []),
      dogIds: List<String>.from(data['dogIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'profilePictureUrl': profilePictureUrl,
      'contactInfo': contactInfo.toMap(),
      'city': city,
      'area': area,
      'userType': userType,
      'postIds': postIds,
      'dogIds': dogIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? email,
    String? username,
    String? profilePictureUrl,
    ContactInfo? contactInfo,
    String? city,
    String? area,
    String? userType,
    List<String>? postIds,
    List<String>? dogIds,
    DateTime? updatedAt,
  }) {
    return UserModel(
      userId: userId,
      email: email ?? this.email,
      username: username ?? this.username,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      contactInfo: contactInfo ?? this.contactInfo,
      city: city ?? this.city,
      area: area ?? this.area,
      userType: userType ?? this.userType,
      postIds: postIds ?? this.postIds,
      dogIds: dogIds ?? this.dogIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class ContactInfo {
  final String phone;
  final String email;

  ContactInfo({
    required this.phone,
    required this.email,
  });

  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    return ContactInfo(
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'email': email,
    };
  }
}
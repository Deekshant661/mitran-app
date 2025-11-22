import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class DogModel {
  final String dogId;
  final String? qrCodeId;
  final String name;
  final List<String> photos;
  final String mainPhotoUrl;
  final String area;
  final String city;
  final bool vaccinationStatus;
  final bool sterilizationStatus;
  final bool readyForAdoption;
  final String temperament;
  final String healthNotes;
  final DogAddedBy addedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  DogModel({
    required this.dogId,
    this.qrCodeId,
    required this.name,
    required this.photos,
    required this.mainPhotoUrl,
    required this.area,
    required this.city,
    required this.vaccinationStatus,
    required this.sterilizationStatus,
    required this.readyForAdoption,
    required this.temperament,
    required this.healthNotes,
    required this.addedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DogModel(
      dogId: doc.id,
      qrCodeId: data['qrCodeId'],
      name: data['name'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      mainPhotoUrl: data['mainPhotoUrl'] ?? '',
      area: data['area'] ?? '',
      city: data['city'] ?? '',
      vaccinationStatus: data['vaccinationStatus'] ?? false,
      sterilizationStatus: data['sterilizationStatus'] ?? false,
      readyForAdoption: data['readyForAdoption'] ?? false,
      temperament: data['temperament'] ?? '',
      healthNotes: data['healthNotes'] ?? '',
      addedBy: DogAddedBy.fromMap(data['addedBy'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'qrCodeId': qrCodeId,
      'name': name,
      'photos': photos,
      'mainPhotoUrl': mainPhotoUrl,
      'area': area,
      'city': city,
      'vaccinationStatus': vaccinationStatus,
      'sterilizationStatus': sterilizationStatus,
      'readyForAdoption': readyForAdoption,
      'temperament': temperament,
      'healthNotes': healthNotes,
      'addedBy': addedBy.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  DogModel copyWith({
    String? qrCodeId,
    String? name,
    List<String>? photos,
    String? mainPhotoUrl,
    String? area,
    String? city,
    bool? vaccinationStatus,
    bool? sterilizationStatus,
    bool? readyForAdoption,
    String? temperament,
    String? healthNotes,
    DateTime? updatedAt,
  }) {
    return DogModel(
      dogId: dogId,
      qrCodeId: qrCodeId ?? this.qrCodeId,
      name: name ?? this.name,
      photos: photos ?? this.photos,
      mainPhotoUrl: mainPhotoUrl ?? this.mainPhotoUrl,
      area: area ?? this.area,
      city: city ?? this.city,
      vaccinationStatus: vaccinationStatus ?? this.vaccinationStatus,
      sterilizationStatus: sterilizationStatus ?? this.sterilizationStatus,
      readyForAdoption: readyForAdoption ?? this.readyForAdoption,
      temperament: temperament ?? this.temperament,
      healthNotes: healthNotes ?? this.healthNotes,
      addedBy: addedBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class DogAddedBy {
  final String userId;
  final String username;
  final ContactInfo contactInfo;

  DogAddedBy({
    required this.userId,
    required this.username,
    required this.contactInfo,
  });

  factory DogAddedBy.fromMap(Map<String, dynamic> map) {
    return DogAddedBy(
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      contactInfo: ContactInfo.fromMap(map['contactInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'contactInfo': contactInfo.toMap(),
    };
  }
}
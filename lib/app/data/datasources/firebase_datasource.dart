import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_model.dart';
import '../models/user_profile_model.dart';

class FirebaseDatasource {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> createOrUpdateUserProfile({
    required String userId,
    required String email,
    required String role,
  }) async {
    await firestore.collection("users").doc(userId).set({
      "email": email,
      "role": role,
      "updatedAt": FieldValue.serverTimestamp(),
      "createdAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> getUserRole(String userId) async {
    final snapshot = await firestore.collection("users").doc(userId).get();
    final data = snapshot.data();
    if (data == null) return "user";
    return (data["role"] ?? "user").toString();
  }

  Stream<List<UserProfileModel>> streamAllUsers() {
    return firestore.collection("users").snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserProfileModel.fromMap(
                userId: doc.id,
                map: doc.data(),
              ))
          .toList();
    });
  }

  Stream<List<LocationModel>> streamUserLocations(String userId) {
    return firestore
        .collection("users")
        .doc(userId)
        .collection("location_logs")
        .orderBy("serverTimestamp", descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final clientTimestamp = data["clientTimestamp"];
        return LocationModel(
          userId: (data["userId"] ?? userId).toString(),
          latitude: (data["latitude"] as num?)?.toDouble() ?? 0,
          longitude: (data["longitude"] as num?)?.toDouble() ?? 0,
          timestamp: clientTimestamp is String
              ? (DateTime.tryParse(clientTimestamp) ?? DateTime.now())
              : DateTime.now(),
        );
      }).toList();
    });
  }

  Future<void> saveLocation(LocationModel location) async {
    await firestore
        .collection("users")
        .doc(location.userId)
        .collection("location_logs")
        .doc("current_location")
        .set({
      ...location.toMap(),
      "serverTimestamp": FieldValue.serverTimestamp(),
      "geoPoint": GeoPoint(location.latitude, location.longitude),
    }, SetOptions(merge: true));
  }
}

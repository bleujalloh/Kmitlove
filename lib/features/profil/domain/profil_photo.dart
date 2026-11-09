import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilPhoto {
  const ProfilPhoto({
    required this.id,
    required this.storagePath,
    required this.status,
    required this.uploadedAt,
  });

  final String id;
  final String storagePath;
  final String status; // pending | approved | rejected
  final DateTime? uploadedAt;

  factory ProfilPhoto.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ProfilPhoto(
      id: doc.id,
      storagePath: data['storagePath'] as String,
      status: data['status'] as String,
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate(),
    );
  }
}

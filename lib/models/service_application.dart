import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceApplication {
  final String id;
  final String serviceId;
  final String serviceTitle;
  final String providerId;
  final String providerName;
  final String requesterId;
  final String requesterName;
  final String status;      // 'pending' | 'accepted' | 'declined'
  final DateTime createdAt;

  ServiceApplication({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.providerId,
    required this.providerName,
    required this.requesterId,
    required this.requesterName,
    required this.status,
    required this.createdAt,
  });

  factory ServiceApplication.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ServiceApplication(
      id: doc.id,
      serviceId: data['serviceId'] ?? '',
      serviceTitle: data['serviceTitle'] ?? '',
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? '',
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

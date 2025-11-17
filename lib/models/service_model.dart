import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String serviceTitle;
  final String serviceDescription;
  final String providerName;
  final String providerId;
  final String location;
  final String availableTiming;
  final int timeLimitDays;
  final int creditsPerHour;
  final String category;
  final String serviceStatus;
  final String requesterId;
  final DateTime createdDate;

  Service({
    required this.id,
    required this.serviceTitle,
    required this.serviceDescription,
    required this.providerName,
    required this.providerId,
    required this.location,
    required this.availableTiming,
    required this.timeLimitDays,
    required this.creditsPerHour,
    required this.category,
    required this.serviceStatus,
    required this.requesterId,
    required this.createdDate,
  });

  factory Service.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Service(
      id: doc.id,
      serviceTitle: data['serviceTitle'] ?? '',
      serviceDescription: data['serviceDescription'] ?? '',
      providerName: data['providerName'] ?? '',
      providerId: data['providerId'] ?? '',
      location: data['location'] ?? '',
      availableTiming: data['availableTiming'] ?? '',
      timeLimitDays: (data['timeLimitDays'] ?? 0) as int,
      creditsPerHour: (data['creditsPerHour'] ?? 0) as int,
      category: data['category'] ?? '',
      serviceStatus: data['serviceStatus'] ?? '',
      requesterId: data['requesterId'] ?? '',
      createdDate:
          (data['createdDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

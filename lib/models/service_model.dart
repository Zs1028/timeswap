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
  final String serviceType; // "need" or "offer"
  final DateTime createdDate;
  /// Timestamps for the transaction lifecycle
  /// acceptedDate  = when helper was accepted (serviceStatus -> inprogress)
  /// completedDate = when service was marked completed
  final DateTime? acceptedDate;
  final DateTime? completedDate;

  /// Roles for time-credit logic
  /// helperId = person who gives help (earns credits)
  /// helpeeId = person who receives help (spends credits)
  final String helperId;
  final String helpeeId;

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
    required this.serviceType,
    required this.createdDate,
    this.helperId = '',
    this.helpeeId = '',
    this.acceptedDate,
    this.completedDate,
  });

  factory Service.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
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
      serviceType: data['serviceType'] ?? 'need',
      createdDate:
          (data['createdDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      helperId: data['helperId'] ?? '',
      helpeeId: data['helpeeId'] ?? '',
      acceptedDate: (data['acceptedDate'] as Timestamp?)?.toDate(),
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
    );
  }
}

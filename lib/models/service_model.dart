import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String serviceTitle;
  final String serviceDescription;

  final String providerName;
  final String providerId;

  final String location;            // "Selangor - Subang Jaya"
  final String locationDetails;     // optional extra info
  final String locationState;       // e.g. "Kuala Lumpur"

  final String availableTiming;     // "8/12/2025, 9:00 AM – 11:00 AM"
  final String flexibleNotes;       // optional: "Every Saturday morning"

  final double creditsPerHour;       // 1.0, 1.5, 2.0, 3.0 etc
  final String category;

  final String serviceStatus;       // open, inprogress, completed
  final String requesterId;
  final String serviceType;         // "need" or "offer"
  final DateTime createdDate;

  // --- Lifecycle + participation ---
  final String helperId;            // person who gives help
  final String helpeeId;            // person who receives help
  final DateTime? acceptedDate;
  final DateTime? completedDate;

  Service({
    required this.id,
    required this.serviceTitle,
    required this.serviceDescription,
    required this.providerName,
    required this.providerId,
    required this.location,
    required this.availableTiming,
    required this.creditsPerHour,
    required this.category,
    required this.serviceStatus,
    required this.requesterId,
    required this.serviceType,
    required this.createdDate,
    this.locationDetails = '',
    this.locationState = '',
    this.flexibleNotes = '',
    this.helperId = '',
    this.helpeeId = '',
    this.acceptedDate,
    this.completedDate,
  });

  factory Service.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    // Normalize credits (can be int or double)
    final rawCredits = data['creditsPerHour'];
    final doubleCredits = rawCredits is int
        ? rawCredits.toDouble()
        : (rawCredits is num ? rawCredits.toDouble() : 0.0);

    return Service(
      id: doc.id,
      serviceTitle: data['serviceTitle'] ?? '',
      serviceDescription: data['serviceDescription'] ?? '',
      providerName: data['providerName'] ?? '',
      providerId: data['providerId'] ?? '',

      location: data['location'] ?? '',
      locationDetails: data['locationDetails'] ?? '',
      locationState: data['locationState'] ?? data['state'] ?? '',

      availableTiming: data['availableTiming'] ?? '',
      flexibleNotes: data['flexibleNotes'] ?? '',

      creditsPerHour: doubleCredits,
      category: data['category'] ?? '',

      serviceStatus: data['serviceStatus'] ?? 'open',
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

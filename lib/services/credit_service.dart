// lib/services/credit_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/service_model.dart';

class CreditService {
  static final _fs = FirebaseFirestore.instance;

  /// How many credits a brand-new user gets
  static const int defaultInitialCredits = 10;

  /// Called once after signup to create the user doc with initial balance
  static Future<void> createUserOnSignup({
    required User user,
    required String name,
    required String phone,
  }) async {
    final docRef = _fs.collection('users').doc(user.uid);
    final snap = await docRef.get();

    if (snap.exists) {
      // If user doc already there, just update basic info (don’t override balance)
      await docRef.update({
        'name': name,
        'phone': phone,
        'email': user.email,
      });
      return;
    }

    await docRef.set({
      'name': name,
      'phone': phone,
      'email': user.email,
      'timeCredits': defaultInitialCredits,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Simple helper: does this user have at least [requiredCredits]?
  static Future<bool> userHasEnoughCredits({
    required String userId,
    required int requiredCredits,
  }) async {
    final doc = await _fs.collection('users').doc(userId).get();
    final data = doc.data();
    final current = (data?['timeCredits'] ?? 0) as int;
    return current >= requiredCredits;
  }

  /// For use before accepting an application:
  /// checks if helpee can afford this service.
  static Future<void> ensureHelpeeHasCreditsForService({
    required String helpeeId,
    required Service service,
  }) async {
    final ok = await userHasEnoughCredits(
      userId: helpeeId,
      requiredCredits: service.creditsPerHour,
    );
    if (!ok) {
      throw Exception(
        'The user who will receive help does not have enough time credits.',
      );
    }
  }

  /// Called when service is marked as completed:
  ///  - deduct credits from helpee
  ///  - add credits to helper
  ///  - update serviceStatus to "completed" + completedDate
  ///  - create a record in "transactions"
  ///
  /// All inside a Firestore transaction 👉 atomic.
  static Future<void> completeServiceAndTransferCredits(
    Service service,
  ) async {
    final helperId = service.helperId;
    final helpeeId = service.helpeeId;
    final credits = service.creditsPerHour;

    if (helperId.isEmpty || helpeeId.isEmpty) {
      throw Exception('Helper or helpee not set for this service.');
    }

    await _fs.runTransaction((tx) async {
      final helperRef = _fs.collection('users').doc(helperId);
      final helpeeRef = _fs.collection('users').doc(helpeeId);
      final serviceRef = _fs.collection('services').doc(service.id);

      final helperSnap = await tx.get(helperRef);
      final helpeeSnap = await tx.get(helpeeRef);

      final helperBalance =
          (helperSnap.data()?['timeCredits'] ?? 0) as int;
      final helpeeBalance =
          (helpeeSnap.data()?['timeCredits'] ?? 0) as int;

      if (helpeeBalance < credits) {
        throw Exception(
          'Insufficient credits. The person receiving help does not have enough balance.',
        );
      }

      // 1) Update balances
      tx.update(helpeeRef, {'timeCredits': helpeeBalance - credits});
      tx.update(helperRef, {'timeCredits': helperBalance + credits});

      // 2) Mark service as completed + set completedDate
      tx.update(serviceRef, {
        'serviceStatus': 'completed',
        'completedDate': FieldValue.serverTimestamp(),
      });

      // 3) Log transaction for history
      final txnRef = _fs.collection('transactions').doc();

      tx.set(txnRef, {
        'serviceId': service.id,
        'serviceTitle': service.serviceTitle,
        'helperId': helperId,
        'helpeeId': helpeeId,
        'credits': credits,
        'serviceType': service.serviceType, // "need" / "offer"
        'status': 'completed',

        // Timeline fields for your FYP report
        'requestDate': Timestamp.fromDate(service.createdDate),
        'acceptedDate': service.acceptedDate != null
            ? Timestamp.fromDate(service.acceptedDate!)
            : FieldValue.serverTimestamp(), // fallback if not set
        'completedDate': FieldValue.serverTimestamp(),

        // optional meta
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

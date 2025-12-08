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
      // Firestore will treat this as a number (int/double)
      'timeCredits': defaultInitialCredits,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Does this user have at least [requiredCredits]?
  /// Supports fractional credits (double).
  static Future<bool> userHasEnoughCredits({
    required String userId,
    required double requiredCredits,
  }) async {
    final doc = await _fs.collection('users').doc(userId).get();
    final data = doc.data();

    final double current =
        (data?['timeCredits'] as num?)?.toDouble() ?? 0.0;

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
      requiredCredits: service.creditsPerHour, // double
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
  /// Everything is done inside a Firestore transaction.
  static Future<void> completeServiceAndTransferCredits(
    Service service,
  ) async {
    final helperId = service.helperId;
    final helpeeId = service.helpeeId;
    final double credits = service.creditsPerHour; // double

    if (helperId.isEmpty || helpeeId.isEmpty) {
      throw Exception('Helper or helpee not set for this service.');
    }

    await _fs.runTransaction((tx) async {
      final helperRef = _fs.collection('users').doc(helperId);
      final helpeeRef = _fs.collection('users').doc(helpeeId);
      final serviceRef = _fs.collection('services').doc(service.id);

      final helperSnap = await tx.get(helperRef);
      final helpeeSnap = await tx.get(helpeeRef);

      final helperData = helperSnap.data();
      final helpeeData = helpeeSnap.data();

      // balances as double (works for old int + new double)
      final double helperBalance =
          (helperData?['timeCredits'] as num?)?.toDouble() ?? 0.0;
      final double helpeeBalance =
          (helpeeData?['timeCredits'] as num?)?.toDouble() ?? 0.0;

      if (helpeeBalance < credits) {
        throw Exception(
          'Insufficient credits. The person receiving help does not have enough balance.',
        );
      }

      // Names for transaction history
      final String helperName =
          (helperData?['name'] as String?) ??
          (helperData?['email'] as String?) ??
          'TimeSwap user';

      final String helpeeName =
          (helpeeData?['name'] as String?) ??
          (helpeeData?['email'] as String?) ??
          'TimeSwap user';

      // 1) Update balances
      tx.update(helpeeRef, {'timeCredits': helpeeBalance - credits});
      tx.update(helperRef, {'timeCredits': helperBalance + credits});

      // 2) Mark service as completed + completedDate
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
        'helperName': helperName,
        'helpeeId': helpeeId,
        'helpeeName': helpeeName,

        'credits': credits, // can be 1.5, 2.0, etc.
        'serviceType': service.serviceType, // "need" / "offer"
        'status': 'completed',

        // Timeline fields
        'requestDate': Timestamp.fromDate(service.createdDate),
        'acceptedDate': service.acceptedDate != null
            ? Timestamp.fromDate(service.acceptedDate!)
            : FieldValue.serverTimestamp(),
        'completedDate': FieldValue.serverTimestamp(),

        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

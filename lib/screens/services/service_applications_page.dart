import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/service_model.dart';
import '../../models/service_application.dart';
import '../../services/credit_service.dart';

class ServiceApplicationsPage extends StatelessWidget {
  final Service service;

  const ServiceApplicationsPage({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final applicationsQuery = FirebaseFirestore.instance
        .collection('serviceRequests')
        .where('serviceId', isEqualTo: service.id)
        .orderBy('createdAt', descending: true)
        .withConverter<ServiceApplication>(
          fromFirestore: (snap, _) => ServiceApplication.fromFirestore(snap),
          toFirestore: (app, _) => {},
        );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF4D1),
        elevation: 0,
        title: Text(
          'Applications for ${service.serviceTitle}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<ServiceApplication>>(
        stream: applicationsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final apps =
              snapshot.data?.docs.map((d) => d.data()).toList() ?? [];

          if (apps.isEmpty) {
            return const Center(child: Text('No applications yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: apps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _ApplicationCard(
              service: service,
              application: apps[i],
            ),
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Service service;
  final ServiceApplication application;

  const _ApplicationCard({
    required this.service,
    required this.application,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF7ED9A2);
      case 'declined':
        return Colors.grey.shade300;
      case 'pending':
      default:
        return const Color(0xFFFBE1B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = application.status.toLowerCase() == 'pending';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: name + status chip
          Row(
            children: [
              Expanded(
                child: Text(
                  application.requesterName.isNotEmpty
                      ? application.requesterName
                      : application.requesterId,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(application.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  application.status,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Applied on: ${application.createdAt}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),

          if (isPending)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => _acceptApplication(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7ED9A2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => _declineApplication(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE74C3C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Future<void> _acceptApplication(BuildContext context) async {
    try {
      final fs = FirebaseFirestore.instance;

      // 1️⃣ Decide who is helper & helpee based on serviceType
      final bool isNeedService = service.serviceType == 'need';

      // - If serviceType == "need":
      //     requester (service.requesterId) = helpee
      //     this applicant (application.requesterId) = helper
      // - If serviceType == "offer":
      //     provider (service.providerId) = helper
      //     this applicant (application.requesterId) = helpee
      final String helperId = isNeedService
          ? application.requesterId
          : service.providerId;
      final String helpeeId = isNeedService
          ? service.requesterId
          : application.requesterId;

      // 2️⃣ Check that helpee has enough credits (before accept)
      await CreditService.ensureHelpeeHasCreditsForService(
        helpeeId: helpeeId,
        service: service,
      );

      // 3️⃣ Get all applications for this service
      final allSnap = await fs
          .collection('serviceRequests')
          .where('serviceId', isEqualTo: application.serviceId)
          .get();

      final batch = fs.batch();

      for (final doc in allSnap.docs) {
        if (doc.id == application.id) {
          batch.update(doc.reference, {'status': 'accepted'});
        } else {
          batch.update(doc.reference, {'status': 'declined'});
        }
      }

      // Decide providerName / providerId if needed
      String providerId = service.providerId;
      String providerName = service.providerName;

      if (isNeedService) {
        // For "need" service, helper becomes provider
        providerId = helperId;
        providerName = application.requesterName;
      }

      // 4️⃣ Update the service to inprogress + set helper/helpee IDs
      batch.update(
        fs.collection('services').doc(service.id),
        {
          'serviceStatus': 'inprogress',
          'providerId': providerId,
          'providerName': providerName,
          'helperId': helperId,
          'helpeeId': helpeeId,
        },
      );

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application accepted.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept: $e')),
      );
    }
  }

  Future<void> _declineApplication(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('serviceRequests')
          .doc(application.id)
          .update({'status': 'declined'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application declined.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline: $e')),
      );
    }
  }
}

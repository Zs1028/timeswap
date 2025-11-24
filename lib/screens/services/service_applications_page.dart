import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/service_model.dart';

class ServiceApplicationsPage extends StatelessWidget {
  final Service service;

  const ServiceApplicationsPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final applicationsQuery = FirebaseFirestore.instance
        .collection('serviceRequests')
        .where('serviceId', isEqualTo: service.id)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF4D1),
        elevation: 0,
        title: const Text(
          'Applications',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: applicationsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No applications yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              final requesterName =
                  data['requesterName'] ?? data['requesterId'] ?? 'Unknown';
              final status = (data['status'] ?? 'pending').toString();

              return _ApplicationCard(
                requestId: doc.id,
                requesterName: requesterName,
                status: status,
                onAccept: () =>
                    _acceptApplication(context, doc.id, requesterName),
                onDecline: () =>
                    _declineApplication(context, doc.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _acceptApplication(
    BuildContext context,
    String requestId,
    String requesterName,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1) Update the service -> inprogress + save chosen helper
      await firestore.collection('services').doc(service.id).update({
        'serviceStatus': 'inprogress',
        'providerId': 'TODO-helper-id', // later: from user profile
        'providerName': requesterName,
      });

      // 2) Mark this request as accepted
      await firestore.collection('serviceRequests').doc(requestId).update({
        'status': 'accepted',
      });

      // 3) Optionally decline others
      final othersSnap = await firestore
          .collection('serviceRequests')
          .where('serviceId', isEqualTo: service.id)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final d in othersSnap.docs) {
        if (d.id == requestId) continue;
        await d.reference.update({'status': 'declined'});
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application accepted.')),
        );
        Navigator.of(context).pop(); // back to Your Requests
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e')),
        );
      }
    }
  }

  Future<void> _declineApplication(
    BuildContext context,
    String requestId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('serviceRequests')
          .doc(requestId)
          .update({'status': 'declined'});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application declined.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline: $e')),
        );
      }
    }
  }
}

class _ApplicationCard extends StatelessWidget {
  final String requestId;
  final String requesterName;
  final String status;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _ApplicationCard({
    required this.requestId,
    required this.requesterName,
    required this.status,
    required this.onAccept,
    required this.onDecline,
  });

  Color _statusColor() {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFFBFE8C9);
      case 'declined':
        return const Color(0xFFF8B4B4);
      default:
        return const Color(0xFFFBE1B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = status.toLowerCase() == 'pending';

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
          Text(
            requesterName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (isPending) ...[
                TextButton(
                  onPressed: onDecline,
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF39C50),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

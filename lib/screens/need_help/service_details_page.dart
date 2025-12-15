import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/provider_profile_page.dart';

import '../../models/service_model.dart';

class ServiceDetailsPage extends StatelessWidget {
  final Service service;

  /// controls whether we show the action button at the bottom
  final bool showRequestButton;

  const ServiceDetailsPage({
    super.key,
    required this.service,
    this.showRequestButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = user?.uid ?? '';

    // ----- Duration & credits formatting -----
    final double credits = service.creditsPerHour;
    final String creditsValue = _formatNumber(credits);

    String durationText;
    if (credits <= 0) {
      durationText = 'Not specified';
    } else {
      durationText =
          '$creditsValue hour${credits == 1.0 ? '' : 's'} estimated';
    }

    final timeCreditsText = '$creditsValue credits';

    // ----- Button visibility & label -----
    final bool isMyService = service.requesterId == currentUserId;
    final bool isOpen = service.serviceStatus.toLowerCase() == 'open';

    // if I'm the owner OR status not open → hide
    final bool baseCanRequest = !isMyService && isOpen;
    final bool canShowButton = showRequestButton && baseCanRequest;

    // label depends on serviceType
    final bool isOfferListing = service.serviceType == 'offer';
    final String buttonLabel =
        isOfferListing ? 'Request this Service' : 'Offer this Service';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF4D1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Service Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Top card
                  _serviceInfoCard(
                    title: service.serviceType == 'offer'
                        ? 'Offer Help: ${service.serviceTitle}'
                        : 'Need Help: ${service.serviceTitle}',
                    description: service.serviceDescription,
                    category: service.category,
                    durationText: durationText,
                    timeCreditsText: timeCreditsText,
                  ),
                  const SizedBox(height: 16),

                  // Middle card (provider info)
                  _providerInfoCard(context),

                  const SizedBox(height: 16),

                  // Bottom card (availability + location)
                  _availabilityCard(),
                ],
              ),
            ),

            // Bottom action button
            if (canShowButton)
              _bottomActionButton(context, buttonLabel, isOfferListing),
          ],
        ),
      ),
    );
  }

  // ---------- Top card: Service info ----------
  Widget _serviceInfoCard({
    required String title,
    required String description,
    required String category,
    required String durationText,
    required String timeCreditsText,
  }) {
    return _roundedCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Service Title',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style:  TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _labelValueColumn('Category', category),
                _labelValueColumn('Duration', durationText),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Time Credits Required',
              style: TextStyle(
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hourglass_bottom, size: 16),
                const SizedBox(width: 4),
                Text(
                  timeCreditsText,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Middle card: Provider info ----------
  Widget _providerInfoCard(BuildContext context) {
  final isOffer = service.serviceType == 'offer';

  // Who are we showing in this card?
  final userId = isOffer ? service.providerId : service.requesterId;

  final headerText = isOffer ? 'Provider Information' : 'Requester Information';
  final buttonText = isOffer ? 'View Provider Profile' : 'View Requester Profile';

  Widget nameWidget;

  if (isOffer) {
    nameWidget = Text(
      service.providerName.isEmpty ? 'Unknown' : service.providerName,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  } else {
    nameWidget = StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Text(
            'Loading...',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          );
        }

        final data = snap.data?.data();
        final name = (data?['name'] ?? '') as String;

        return Text(
          name.isEmpty ? 'Unknown' : name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        );
      },
    );
  }

  return _roundedCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Center(
            child: Text(
              headerText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black.withOpacity(0.85),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.person, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 8),

          // ✅ Name (provider name or fetched requester name)
          nameWidget,

          const SizedBox(height: 12),

          // ✅ Ratings pulled from "ratings" collection
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('ratings')
                .where('revieweeId', isEqualTo: userId)
                .snapshots(),
            builder: (context, snapshot) {
              double avgRating = 0.0;
              int reviewCount = 0;

              if (snapshot.hasData) {
                final docs = snapshot.data!.docs;
                reviewCount = docs.length;
                if (reviewCount > 0) {
                  num total = 0;
                  for (final d in docs) {
                    final r = d.data()['rating'];
                    if (r is int) {
                      total += r;
                    } else if (r is num) {
                      total += r;
                    }
                  }
                  avgRating = total / reviewCount;
                }
              }

              final ratingText =
                  reviewCount == 0 ? 'No ratings yet' : '${avgRating.toStringAsFixed(1)}/5';

              final reviewsText = '$reviewCount review${reviewCount == 1 ? '' : 's'}';

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Overall Ratings',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ratingText,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'Number of Reviews',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reviewsText,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 14),
          SizedBox(
            width: 170,
            height: 32,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderProfilePage(providerId: userId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF52A8FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  // ---------- Bottom card: Availability & Location ----------
  Widget _availabilityCard() {
    // Prefer: locationState if available, else fall back to location
    final String mainLocation = service.locationState.isNotEmpty
        ? service.locationState
        : service.location;

    final String details =
        service.locationDetails.isNotEmpty ? service.locationDetails : '-';

    final String flexibility =
        service.flexibleNotes.isNotEmpty ? service.flexibleNotes : '-';

    return _roundedCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              textAlign: TextAlign.center,
              'Availability & Location',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _infoPill(
                    label: 'Available Date & Time',
                    value: service.availableTiming,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _infoPill(
                    label: 'Location',
                    value: mainLocation,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _infoPill(
                    label: 'Flexibility',
                    value: flexibility,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _infoPill(
                    label: 'Location details',
                    value: details,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Bottom button ----------
  Widget _bottomActionButton(
      BuildContext context, String label, bool isOfferListing) {
    return Container(
      color: const Color(0xFFFFF4D1),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showConfirmDialog(context, isOfferListing),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF39C50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ---------- Dialogs (with Firestore write) ----------
void _showConfirmDialog(BuildContext context, bool isOfferListing) {
  final String titleText = isOfferListing
      ? 'Confirm Requesting this Service?'
      : 'Confirm Offering this Service?';

  final String subtitleText = isOfferListing
      ? 'You will send a request to the provider.'
      : 'You will offer to provide this service.';

  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.25),
    builder: (_) {
      return Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.78,
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF7ED9A2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  subtitleText,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Please log in to continue.'),
                                ),
                              );
                              return;
                            }

                            try {
                              // 🔎 get nice display name from users collection
                              final userDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .get();

                              final requesterName =
                                  (userDoc.data()?['name'] as String?) ??
                                  user.email ??
                                  'TimeSwap User';

                              await FirebaseFirestore.instance
                                  .collection('serviceRequests')
                                  .add({
                                'serviceId': service.id,
                                'serviceTitle': service.serviceTitle,
                                'providerId': service.providerId,
                                'providerName': service.providerName,

                                'requesterId': user.uid,
                                'requesterName': requesterName,
                                'requesterEmail': user.email ?? '',

                                // optional: so you know if this was
                                // "request this service" vs "offer this service"
                                'requestType':
                                    isOfferListing ? 'request' : 'offer',

                                'status': 'pending',
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                              if (context.mounted) {
                                Navigator.of(context).pop(); // close confirm
                                _showSuccessDialog(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to send request: $e',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA64C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Confirm'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE74C3C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (_) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.78,
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF7ED9A2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Request sent to ${service.providerName.isEmpty ? "provider" : service.providerName}!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 36,
                    width: 90,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // close success
                        Navigator.of(context).pop(); // back to list
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF3CB371),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- Helpers ----------

  // small soft grey card to match new design
  Widget _roundedCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6), // slightly grey
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 4),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _labelValueColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, // ✅ same weight
          ),
        ),
      ],
    );
  }

  Widget _infoPill({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// format 2.0 → "2", 1.5 → "1.5"
  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

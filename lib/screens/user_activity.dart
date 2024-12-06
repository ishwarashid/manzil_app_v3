import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manzil_app_v3/providers/current_user_provider.dart';
import 'package:intl/intl.dart';
import 'package:manzil_app_v3/providers/user_ride_providers.dart';

class UserActivityScreen extends ConsumerStatefulWidget {
  const UserActivityScreen({super.key});

  @override
  ConsumerState<UserActivityScreen> createState() => _UserActivityScreenState();
}

class _UserActivityScreenState extends ConsumerState<UserActivityScreen> {
  String? _processingRideId;

  Future<void> _updateRideStatus(String rideId, String newStatus) async {
    print(newStatus);
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('rides').doc(rideId).update({
      'status': newStatus,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> _cancelRide(String rideId) async {
    if (_processingRideId != null) return;

    try {
      setState(() => _processingRideId = rideId);
      await _updateRideStatus(rideId, 'cancelled');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel ride: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingRideId = null);
      }
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }

  Widget _buildRideCard(BuildContext context, Map<String, dynamic> ride, bool isDriver) {
    final status = ride['status'] as String;
    final isAccepted = status == 'accepted' || status == 'picked' || status == 'paying';
    final isPending = status == 'pending';
    final rideId = ride['id'] as String;
    final isProcessing = _processingRideId == rideId;
    final paymentMethod = ride['paymentMethod'] as String? ?? 'cash';
    final formattedPaymentMethod = paymentMethod[0].toUpperCase() + paymentMethod.substring(1);

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isAccepted
                        ? "Ride booked ${_formatTimestamp(ride['acceptedAt'])}"
                        : "Ride booked ${_formatTimestamp(ride['createdAt'])}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color.fromRGBO(30, 60, 87, 1),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAccepted
                        ? Colors.green.withOpacity(0.1)
                        : const Color.fromARGB(255, 255, 170, 42).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.capitalize(),
                    style: TextStyle(
                      fontSize: 12,
                      color: isAccepted
                          ? Colors.green
                          : const Color.fromARGB(255, 255, 170, 42),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color.fromARGB(255, 255, 107, 74),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ride["pickupLocation"] as String,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.navigation,
                        color: Color.fromARGB(255, 255, 170, 42),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ride["destination"] as String,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Icon(
                  isDriver ? Icons.person : Icons.drive_eta_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isDriver
                        ? (ride['passengerName'] ?? 'Unknown Passenger')
                        : (ride['selectedDriverName'] ?? 'Yet to be confirmed'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${ride['calculatedFare'] ?? ride['offeredFare']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color.fromRGBO(30, 60, 87, 1),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          paymentMethod == 'cash'
                              ? Icons.money
                              : paymentMethod == 'jazzcash'
                              ? Icons.phone_android
                              : Icons.account_balance_wallet,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedPaymentMethod,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            if (!isDriver && isPending) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : () => _cancelRide(rideId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    "Cancel Ride",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser['uid'] as String;
    final userRideStatus = ref.watch(userRideStatusProvider(userId));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your Current Activity",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color.fromRGBO(30, 60, 87, 1),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 165,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(30, 60, 87, 1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: userRideStatus.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (status) {
                final rides = status.activeRides;

                if (rides.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 300,
                          child: Image.asset(
                            'assets/images/no_activity_illustration.png',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Activity Yet',
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: const Color.fromRGBO(30, 60, 87, 1),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: rides.length,
                  itemBuilder: (context, index) => _buildRideCard(
                    context,
                    rides[index],
                    status.isDriver,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
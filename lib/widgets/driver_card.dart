import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v3/providers/current_user_provider.dart';
import 'package:manzil_app_v3/screens/chats_screen.dart';
import 'package:manzil_app_v3/screens/user_chat_screen.dart';

class DriverCard extends ConsumerWidget {
  final Map<String, dynamic> driverInfo;
  final VoidCallback onAccept;
  final bool isAccepting;

  const DriverCard({
    required this.driverInfo,
    required this.onAccept,
    this.isAccepting = false,
    super.key,
  });

  String _getEstimatedTime(double distanceInMeters) {
    const averageSpeedInMetersPerSecond = 8.33;
    final timeInSeconds = distanceInMeters / averageSpeedInMetersPerSecond;
    final minutes = timeInSeconds / 60;

    if (minutes < 1) {
      return "Less than a minute away";
    } else if (minutes < 60) {
      final roundedMinutes = minutes.round();
      return "$roundedMinutes ${roundedMinutes == 1 ? 'minute' : 'minutes'} away";
    } else {
      final hours = minutes / 60;
      final roundedHours = hours.round();
      return "$roundedHours ${roundedHours == 1 ? 'hour' : 'hours'} away";
    }
  }

  Widget _buildRatingBadge() {
    if (driverInfo['driverRatings'] == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'New Driver',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    final rating = (driverInfo['driverRatings'] as num).toDouble();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 170, 42).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 16,
            color: Color.fromARGB(255, 255, 170, 42),
          ),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(255, 255, 170, 42),
                // color: Colors.grey[600]
            ),
          ),
        ],
      ),
    );
  }

  IconData _getVehicleIcon(String category) {
    switch (category.toLowerCase()) {
      case 'car':
        return Icons.directions_car;
      case 'bike':
        return Icons.two_wheeler;
      case 'rickshaw':
        return Icons.electric_rickshaw;
      default:
        return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(currentUserProvider);
    final distance = driverInfo["distanceFromPassenger"] as double;
    final estimatedTime = _getEstimatedTime(distance);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            driverInfo["driverName"] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRatingBadge(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            estimatedTime,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Add vehicle icon based on category
                          Icon(
                            _getVehicleIcon(driverInfo["vehicleCategory"] as String),
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            driverInfo["vehicleCategory"] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Rs. ${driverInfo["calculatedFare"]}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    // color: Color.fromRGBO(30, 60, 87, 1),
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatsScreen(),
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserChatScreen(
                              currentUser: currentUser,
                              fullName: driverInfo["driverName"] as String,
                              receiverId: driverInfo["driverId"],
                              receiverNumber: driverInfo["driverNumber"],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.message_outlined,
                        color: Color.fromARGB(255, 255, 170, 42),
                        size: 18,
                      ),
                      label: const Text("Message"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color.fromARGB(255, 255, 170, 42),
                        side: const BorderSide(
                          color:Color.fromARGB(255, 255, 170, 42),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isAccepting ? null : onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: isAccepting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        "Book",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
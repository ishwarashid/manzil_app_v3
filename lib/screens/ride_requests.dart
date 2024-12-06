import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v3/providers/current_user_provider.dart';
import 'package:manzil_app_v3/providers/rides_filter_provider.dart';
import 'package:manzil_app_v3/screens/chats_screen.dart';
import 'package:manzil_app_v3/screens/ride_location_map.dart';
import 'package:manzil_app_v3/screens/setup_driver_screen.dart';
import 'package:manzil_app_v3/screens/update_driver_documents.dart';
import 'package:manzil_app_v3/screens/user_chat_screen.dart';
import 'package:manzil_app_v3/services/ride/ride_services.dart';
import 'package:manzil_app_v3/widgets/destination_alert_dialog.dart';

class RideRequestsScreen extends ConsumerStatefulWidget {
  const RideRequestsScreen({super.key});

  @override
  RideRequestsScreenState createState() => RideRequestsScreenState();
}

class RideRequestsScreenState extends ConsumerState<RideRequestsScreen> {
  final _ridesService = RidesService();
  String? _processingRideId;

  void _showDestinationInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => const DestinationAlertDialog(),
    );
  }

  @override
  void initState() {
    super.initState();
    final enteredDestination =
        ref.read(ridesFilterProvider)["destination"] as String ?? '';
    if (enteredDestination.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDestinationInputDialog();
      });
    }
  }

  Future<void> _initiateChat(Map<String, dynamic> request) async {
    final currentUser = ref.read(currentUserProvider);
    final receiverId = request["passengerID"];
    final receiverNumber = request["passengerNumber"];

    // await _chatService.createChatRoom(currentUser, receiverId as String);

    if (!mounted) return;

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
          fullName: request["passengerName"] as String,
          receiverId: receiverId,
          receiverNumber: receiverNumber,
        ),
      ),
    );
  }

  // Future<void> _acceptRide(String rideId) async {
  //   if (_isProcessing) return;
  //
  //   try {
  //     setState(() {
  //       _isProcessing = true;
  //     });
  //
  //     final currentUser = ref.read(currentUserProvider);
  //     await _ridesService.acceptRide(rideId, currentUser);
  //
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Ride request accepted successfully')),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Failed to accept ride: $e')),
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isProcessing = false;
  //       });
  //     }
  //   }
  // }

  Future<void> _acceptRide(String rideId) async {
    if (_processingRideId != null) return;

    try {
      setState(() {
        _processingRideId = rideId; // here i am storing the ID of the ride being processed so only that rides button start loading after click
      });

      final currentUser = ref.read(currentUserProvider);

      try {
        await _ridesService.acceptRide(rideId, currentUser);

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride request accepted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // print(e);
        if (e is Map && e.containsKey('needsSetup')) {
          print("hii");
          if (e['needsSetup'] == true) {
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SetupDriverScreen()),
              );
            }
          } else {
            // Handle expired documents
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UpdateDriverDocuments(
                    isCnicExpired: e['cnicExpired'],
                    isLicenseExpired: e['licenseExpired'],
                    currentData: e['currentData'],
                  ),
                ),
              );
            }
          }
        } else {
          String errorMessage = e.toString();
          if (errorMessage.contains('Exception: ')) {
            errorMessage = errorMessage.replaceAll('Exception: ', '');
          }

          if (errorMessage.contains('RangeError')){
            errorMessage = "Something went wrong. Please check your internet connection.";
          }

          if (mounted) {
            print(errorMessage);
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }

        }
        // rethrow;
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingRideId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final enteredDestination =
        ref.watch(ridesFilterProvider)["destination"] as String? ?? '';

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
                      "Ride Requests Near You",
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
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(30, 60, 87, 1).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showDestinationInputDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: const ImageIcon(
                        ResizeImage(
                          AssetImage('assets/icons/filter_rides_icon.png'),
                          width: 48,
                          height: 48,
                        ),
                        size: 22,
                        color: Color.fromRGBO(30, 60, 87, 1),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (enteredDestination.isEmpty)
            const EmptyStateWidget(
              identifier: 'setDes',
              message: "Please set a destination to view requests.",
            )
          else
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _ridesService.getRides(currentUser['uid']),
                builder: (context, snapshot) {
                  // if (snapshot.connectionState == ConnectionState.waiting) {
                  //   return const Center(child: CircularProgressIndicator()); // when i press on accept i start to see this progress bar
                  // }
                  // if (snapshot.connectionState == ConnectionState.waiting && _processingRideId == null) {
                  //   return const Center(child: CircularProgressIndicator());
                  // }
                  if (!snapshot.hasData && _processingRideId == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    // return Center(
                    //   child: Text(
                    //     'Error: ${snapshot.error}',
                    //     textAlign: TextAlign.center,
                    //   ),
                    // );
                    return const Center(
                      child: Text(
                        'Something went wrong. Please try again later.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final requests = snapshot.data ?? [];
                  final filteredRequests = requests.where((ride) {
                    final destination = ride['destination'] as String;
                    return destination
                        .toLowerCase()
                        .contains(enteredDestination.trim().toLowerCase());
                  }).toList();

                  if (filteredRequests.isEmpty) {
                    return const EmptyStateWidget(
                      identifier: 'changeFilter',
                      message:
                          "No ride requests found\nTry changing the filter",
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredRequests.length,
                    itemBuilder: (context, index) => RideRequestCard(
                      request: filteredRequests[index],
                      onAccept: () =>
                          _acceptRide(filteredRequests[index]['id']),
                      onChat: () => _initiateChat(filteredRequests[index]),
                      isProcessing: _processingRideId ==
                          filteredRequests[index]['id'],
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

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String identifier;

  const EmptyStateWidget({
    required this.message,
    required this.identifier,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (identifier == 'setDes') {
      return Padding(
        padding: const EdgeInsets.only(top: 240),
        child: Center(
          child: Text(
            message,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: const Color.fromRGBO(30, 60, 87, 1),
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: const Color.fromRGBO(30, 60, 87, 1),
              fontWeight: FontWeight.w500,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class RideRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;
  final VoidCallback onChat;
  final bool isProcessing;

  const RideRequestCard({
    required this.request,
    required this.onAccept,
    required this.onChat,
    required this.isProcessing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    print("Request");
    print(request);
    final createdAt = request['createdAt'] as Timestamp;
    final timeAgo = DateTime.now().difference(createdAt.toDate());
    String timeAgoStr;
    if (timeAgo.inMinutes < 60) {
      timeAgoStr = '${timeAgo.inMinutes}m ago';
    } else if (timeAgo.inHours < 24) {
      timeAgoStr = '${timeAgo.inHours}h ago';
    } else {
      timeAgoStr = '${timeAgo.inDays}d ago';
    }

    final isPrivate = request['isPrivate'] as bool? ?? false;
    print(isPrivate);
    final paymentMethod = request['paymentMethod'] as String? ?? 'cash';
    final formattedPaymentMethod =
        paymentMethod[0].toUpperCase() + paymentMethod.substring(1);

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
                  child: Row(
                    children: [
                      Text(
                        request["passengerName"] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color.fromRGBO(30, 60, 87, 1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgoStr,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.message,
                    color: Color.fromARGB(255, 255, 170, 42),
                  ),
                  onPressed: onChat,
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
              child: GestureDetector(
                onLongPress: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RideLocationsMap(
                        pickupCoordinates: request["pickupCoordinates"] as List,
                        destinationCoordinates: request["destinationCoordinates"] as List,
                        pickupLocation: request["pickupLocation"] as String,
                        destination: request["destination"] as String,
                      ),
                    ),
                  );
                },
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
                            request["pickupLocation"] as String,
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
                            request["destination"] as String,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPrivate
                        ? const Color.fromARGB(255, 255, 170, 42)
                        : const Color.fromARGB(255, 255, 107, 74),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPrivate ? 'Private' : 'Public',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${request["seats"]} seats',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const Spacer(),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${request["offeredFare"]}',
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

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text("Accept"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

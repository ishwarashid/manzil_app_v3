import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v3/providers/current_user_provider.dart';
import 'package:manzil_app_v3/widgets/input_destination.dart';
import 'package:manzil_app_v3/widgets/input_fare.dart';
import 'package:manzil_app_v3/widgets/input_pickup.dart';
import '../providers/booking_inputs_provider.dart';
import '../widgets/input_seats.dart';

class RideInputs extends ConsumerStatefulWidget {
  const RideInputs({super.key, required this.onFindDrivers});
  final Function() onFindDrivers;

  @override
  ConsumerState<RideInputs> createState() => _RideInputsState();
}

class _RideInputsState extends ConsumerState<RideInputs> {
  bool _isProcessing = false;

  @override
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final currentUser = ref.read(currentUserProvider);
      final bookingInputs = ref.read(bookingInputsProvider);

      if ((bookingInputs['pickup'] as String? ?? '').isEmpty) {
        final locationText = currentUser['location_text'] as String?;
        final coordinates = currentUser['coordinates'] as List?;

        if (locationText != null && locationText.isNotEmpty &&
            coordinates != null && coordinates.isNotEmpty) {
          final List<double> typedCoordinates = coordinates.map((e) =>
              (e as num).toDouble()).toList();

          ref.read(bookingInputsProvider.notifier)
            ..setPickup(locationText)
            ..setPickupCoordinates(typedCoordinates);
        }
      }
    });
  }

  // void _setInitialPickupLocation() {
  //   final currentUser = ref.read(currentUserProvider);
  //   final bookingInputs = ref.read(bookingInputsProvider);
  //
  //   // Only set if pickup is empty (not manually set)
  //   if ((bookingInputs['pickup'] as String? ?? '').isEmpty) {
  //     final locationText = currentUser['location_text'] as String?;
  //     final coordinates = currentUser['coordinates'] as List?;
  //
  //     if (locationText != null && locationText.isNotEmpty &&
  //         coordinates != null && coordinates.isNotEmpty) {
  //
  //       final List<double> typedCoordinates = coordinates.map((e) => (e as num).toDouble()).toList();
  //
  //       ref.read(bookingInputsProvider.notifier)
  //         ..setPickup(locationText)
  //         ..setPickupCoordinates(typedCoordinates);
  //     }
  //   }
  // }

  void _openSeatsModalOverlay() {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      context: context,
      builder: (ctx) => const InputSeats(),
    );
  }

  void _openPickupModalOverlay() {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      context: context,
      builder: (ctx) => const InputPickup(),
    );
  }

  void _openDestinationModalOverlay() {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      context: context,
      builder: (ctx) => const InputDestination(),
    );
  }

  void _openFareModalOverlay() {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      context: context,
      builder: (ctx) => const InputFare(),
    );
  }

  Future<void> _bookRide() async {
    final bookingInputs = ref.read(bookingInputsProvider);
    final currentUser = ref.read(currentUserProvider);

    setState(() {
      _isProcessing = true;
    });

    try {
      final activePassengerRides = await FirebaseFirestore.instance
          .collection('rides')
          .where('passengerID', isEqualTo: currentUser['uid'])
          .where('status', whereIn: ['picked', 'accepted', 'paying'])
          .get();

      if (activePassengerRides.docs.isNotEmpty) {
        setState(() {
          _isProcessing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You already have an active ride as a passenger. Please complete or cancel it first."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final activeDriverRides = await FirebaseFirestore.instance
          .collection('rides')
          .where('selectedDriverId', isEqualTo: currentUser['uid'])
          .where('status', whereIn: ['accepted', 'picked', 'paying'])
          .get();

      if (activeDriverRides.docs.isNotEmpty) {
        setState(() {
          _isProcessing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You have active rides as a driver. Please complete them before booking a ride."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final pickupCoordinates = (bookingInputs['pickupCoordinates'] as List?)?.isNotEmpty == true
          ? bookingInputs['pickupCoordinates']
          : currentUser['coordinates'];

      final batch = FirebaseFirestore.instance.batch();

      final pendingRidesQuery = await FirebaseFirestore.instance
          .collection('rides')
          .where('passengerID', isEqualTo: currentUser['uid'])
          .where('status', isEqualTo: 'pending')
          .get();

      if (pendingRidesQuery.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cancelling your previous pending ride requests..."),
              duration: Duration(seconds: 2),
            ),
          );
        }

        for (var doc in pendingRidesQuery.docs) {
          batch.update(doc.reference, {
            'status': 'cancelled',
            'cancelledAt': Timestamp.now(),
            'cancelReason': 'New ride requested',
          });
        }
      }

      final newRideRef = FirebaseFirestore.instance.collection('rides').doc();
      batch.set(newRideRef, {
        'passengerName': '${currentUser['first_name']} ${currentUser['last_name']}',
        'passengerID': currentUser['uid'],
        'passengerNumber': currentUser['phone_number'],
        'pickupLocation': bookingInputs['pickup'],
        'pickupCoordinates': pickupCoordinates,
        'destination': bookingInputs['destination'],
        'destinationCoordinates': bookingInputs['destinationCoordinates'],
        'seats': bookingInputs['seats'],
        'offeredFare': bookingInputs['fare'],
        'paymentMethod': bookingInputs['paymentMethod'],
        'isPrivate': bookingInputs['private'],
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ride requested successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      ref.read(bookingInputsProvider.notifier).resetBookingInputs();
      setState(() {
        _isProcessing = false;
      });

      widget.onFindDrivers();
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingInputs = ref.watch(bookingInputsProvider);
    final bookingInputsNotifier = ref.read(bookingInputsProvider.notifier);
    final currentUser = ref.watch(currentUserProvider);

    bool areAllFieldsFilled = bookingInputsNotifier.areAllFieldsFilled();

    String pickup = (bookingInputs['pickup'] as String? ?? '').isNotEmpty
        ? bookingInputs['pickup'] as String
        : currentUser['location_text'] as String? ?? "No Pickup Location Specified";

    final destination = bookingInputs['destination'] as String? ?? "To";
    final seats = bookingInputs['seats'] as int? ?? 0;
    final fare = bookingInputs['fare'] as int? ?? 0;
    final isPrivate = bookingInputs['private'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.only(top: 30, bottom: 60, right: 30, left: 30),
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _openPickupModalOverlay,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color.fromARGB(255, 255, 107, 74),
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          pickup,
                          style: const TextStyle(fontSize: 18),
                          softWrap: true,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openDestinationModalOverlay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: destination.isNotEmpty
                          ? const Color.fromARGB(255, 76, 175, 64)
                          : Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 30,
                        ),
                        const SizedBox(
                          width: 25,
                        ),
                        Expanded(
                          child: Text(
                            destination.isNotEmpty ? destination : "To",
                            style: TextStyle(
                                color: destination.isNotEmpty
                                    ? const Color.fromARGB(255, 255, 255, 255)
                                    : const Color.fromARGB(160, 255, 255, 255),
                                fontSize: 20),
                            softWrap: true,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openSeatsModalOverlay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: seats > 0
                          ? const Color.fromARGB(255, 76, 175, 64)
                          : Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.airline_seat_recline_extra_sharp,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 30,
                        ),
                        const SizedBox(
                          width: 25,
                        ),
                        Text(
                          seats > 0 ? '$seats Seats' : "Number of Seats",
                          style: TextStyle(
                              color: seats > 0
                                  ? const Color.fromARGB(255, 255, 255, 255)
                                  : const Color.fromARGB(160, 255, 255, 255),
                              fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openFareModalOverlay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: fare > 0
                          ? const Color.fromARGB(255, 76, 175, 64)
                          : Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "PKR",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        Text(
                          fare > 0 ? '$fare' : "Offer Your Fare",
                          style: TextStyle(
                              color: fare > 0
                                  ? const Color.fromARGB(255, 255, 255, 255)
                                  : const Color.fromARGB(160, 255, 255, 255),
                              fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                SwitchListTile(
                  value: isPrivate,
                  onChanged: (isChecked) {
                    ref
                        .read(bookingInputsProvider.notifier)
                        .setPrivate(isChecked);
                  },
                  title: const Text('Private Ride',
                      style: TextStyle(
                        fontSize: 18,
                      )),
                  subtitle: const Text('You can have driver all to yourself.',
                      style: TextStyle(fontSize: 12)),
                  activeColor: Theme.of(context).colorScheme.primary,
                  contentPadding: const EdgeInsets.all(0),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed:
                  (!_isProcessing && areAllFieldsFilled) ? _bookRide : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 107, 74),
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                textStyle:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text("Find a driver"),
            ),
          )
        ],
      ),
    );
  }
}

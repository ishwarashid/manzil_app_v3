import 'package:flutter/material.dart';
import 'package:manzil_app_v3/screens/chats_screen.dart';
import 'package:manzil_app_v3/screens/find_drivers.dart';
import 'package:manzil_app_v3/widgets/driver_tracking.dart';
import 'package:manzil_app_v3/widgets/passenger_tracking.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen(this.isDriver, {super.key});

  final bool isDriver;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {

  void _setScreen(String identifier, {bool? isDriver}) async {
    Navigator.of(context).pop();
    if (identifier == 'chats') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const ChatsScreen(),
        ),
      );
    } else if (identifier == 'foundDrivers') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const FindDrivers(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    Widget screen = const PassengerTracking();
    if (widget.isDriver) {
      screen = const DriverTracking();
    }
    return screen;
  }
}

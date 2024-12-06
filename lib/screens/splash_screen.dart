import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:manzil_app_v3/screens/home_screen.dart';
import 'package:manzil_app_v3/screens/start_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    String? phoneNumber = box.read('phoneNumber');
    if (phoneNumber == null || phoneNumber.isEmpty) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StartScreen()),
        );
      });
    } else {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
    }

    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/light_logo.png', width: 180,),
              const SizedBox(height: 20,),
              Text(
                "Making Miles Matter, Sharing the Road",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8)),
              )
            ],
          ),
        ));
  }
}

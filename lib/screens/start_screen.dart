import 'package:flutter/material.dart';
import 'package:manzil_app_v3/screens/phone_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(children: [
          Container(
            margin: const EdgeInsets.fromLTRB(0, 100, 0, 50),
            width: 180,
            child: Image.asset(
              'assets/images/dark_logo.png',
              cacheWidth: 360,
              cacheHeight: 170,
            ),
          ),

          Container(
            // margin: const EdgeInsets.all(100),
            width: 280,
            child: Image.asset(
              'assets/images/start_screen_illustration.png',
              cacheWidth: 560,
              cacheHeight: 504,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  const Text(
                    "Welcome!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 45, 45, 45),
                    ),
                  ),
                  const Text(
                    "Have a better sharing experience",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 160, 160, 160),
                    ),
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        textStyle: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => const PhoneScreen(),
                          ),
                        );
                      },
                      child: const Text("Continue with phone number"),
                    ),
                  )
                ],
              ),
            ),
          )
        ]),
      ),
    );
  }
}

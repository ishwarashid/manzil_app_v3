import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:manzil_app_v3/screens/get_started_screen.dart';
import 'package:otp_timer_button/otp_timer_button.dart';
import 'package:pinput/pinput.dart';

import '../main.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _pinController = TextEditingController();
  final OtpTimerButtonController _otpController = OtpTimerButtonController();
  bool _isProcessing = false;

  final String baseUrl = "https://shrimp-select-vertically.ngrok-free.app";

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  String getPhoneNumber() {
    return widget.phoneNumber;
  }

  Future<int> _sendCode() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sendotp'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'phone': getPhoneNumber()}),
      );
      return response.statusCode;
    } catch (e) {
      debugPrint("Error sending OTP: $e");
      return 500;
    }
  }

  Future<int> _signIn() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verifyotp'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body:
            jsonEncode({'phone': getPhoneNumber(), 'otp': _pinController.text}),
      );
      return response.statusCode;
    } catch (e) {
      debugPrint("Error verifying OTP: $e");
      return 500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Color.fromRGBO(30, 60, 87, 1),
      ),
      decoration: BoxDecoration(
        // color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
    );

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Phone verification",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 45, 45, 45),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              const Text(
                "Enter your OTP code",
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 160, 160, 160),
                ),
              ),
              const SizedBox(
                height: 32,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Pinput(
                  length: 6,
                  controller: _pinController,
                  defaultPinTheme: defaultPinTheme,
                ),
              ),
              const SizedBox(
                height: 60,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      textStyle: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            setState(() {
                              _isProcessing = true;
                            });

                            final statusCode = await _signIn();

                            setState(() {
                              _isProcessing = false;
                            });

                            if (statusCode == 200) {
                              final box = GetStorage();
                              box.write('phoneNumber', getPhoneNumber());
                              try {
                                final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
                                    .collection('users')
                                    .where('phone_number', isEqualTo: getPhoneNumber())
                                    .limit(1)
                                    .get();

                                // print(querySnapshot.docs.first.data());

                                if (querySnapshot.docs.isNotEmpty) {
                                  print("Existing user found");
                                  print(querySnapshot.docs.first.data());

                                  if (!mounted) return;
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => const MyApp(),
                                    ),
                                  );
                                } else {
                                  print("New user");
                                  if (!mounted) return;
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => GetStartedScreen(phoneNumber: getPhoneNumber(),),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    statusCode == 400
                                        ? "Failed to verify OTP. Please enter valid OTP."
                                        : "Failed to verify OTP. Please try again.",
                                  ),
                                ),
                              );
                            }
                          },
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white)),
                          )
                        : const Text("Verify"),
                  ),
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              OtpTimerButton(
                controller: _otpController,
                onPressed: () async {
                  final statusCode = await _sendCode();

                  if (statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("OTP Resent Successfully")),
                    );
                    _otpController.startTimer();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Error Occurred: Failed to resend OTP"),
                      ),
                    );
                  }
                },
                text: const Text(
                  'Resend OTP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                duration: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:manzil_app_v3/screens/otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  String _phoneNumber = '';
  final _phoneNumberController = TextEditingController();
  bool _isProcessing = false;

  String? _validatePhoneNumber(String phoneNumber) {

    phoneNumber = phoneNumber.trim();

    if (phoneNumber.isEmpty) {
      return 'Phone number is required';
    }

    // this checks if phone number starts with 0 or 3
    if (!phoneNumber.startsWith('0') && !phoneNumber.startsWith('3')) {
      return 'Phone number must start with 0 or 3';
    }

    // this checks length depending on the start number
    if ((phoneNumber.startsWith('3') && phoneNumber.length != 10) ||
        (phoneNumber.startsWith('0') && phoneNumber.length != 11)) {
      return 'Invalid phone number length';
    }

    // to check if it contains only numbers
    if (!RegExp(r'^[0-9]+$').hasMatch(phoneNumber)) {
      return 'Phone number can only contain digits';
    }

    return null;
  }

  String _formatPhoneNumber() {
    final userPhoneNo = _phoneNumberController.text.trim();
    if (userPhoneNo[0] == '0') {
      return "+92${userPhoneNo.substring(1)}";
    }
    return "+92$userPhoneNo";
  }

  Future<bool> _checkIfUserBanned(String phoneNumber) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone_number', isEqualTo: phoneNumber)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        return userData['isBanned'] == true;
      }

      return false;
    } catch (e) {
      print('Error checking user ban status: $e');
      return false;
    }
  }

  Future<void> _handlePhoneSubmission() async {

    final validationError = _validatePhoneNumber(_phoneNumberController.text);
    if (validationError != null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      FocusScope.of(context).unfocus();
      _phoneNumber = _formatPhoneNumber();

      // we had to check if the user is banned here, so that we dont send him otp
      final isBanned = await _checkIfUserBanned(_phoneNumber);
      if (isBanned) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been banned. Please contact support.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // if not banned,  we send OTP
      final statusCode = await _sendCode();

      if (statusCode == 200) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OtpScreen(phoneNumber: _phoneNumber),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error Occurred: Failed to send otp."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<int> _sendCode() async {
    const url = "https://shrimp-select-vertically.ngrok-free.app";
    final response = await http.post(
      Uri.parse('$url/sendotp'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'phone': _phoneNumber,
      }),
    );

    return response.statusCode;
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          // mainAxisSize: MainAxisSize.max,
          children: [
            Image.asset(
              'assets/images/phone_screen_illustration.png',
              width: 300,
            ),
            const SizedBox(
              height: 24,
            ),
            const Text(
              "Verify Your Phone",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 45, 45, 45),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  TextField(
                    controller: _phoneNumberController,
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                    decoration: const InputDecoration(
                      label: Text("Enter Phone Number",
                          style: TextStyle(fontSize: 18)),
                      prefixIcon: Icon(
                        Icons.phone,
                      ),
                      prefix: Padding(
                        padding: EdgeInsets.fromLTRB(0, 0, 8, 0),
                        child: Text(
                          "+92",
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(
                    height: 60,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: _isProcessing ? null : _handlePhoneSubmission,
                      child: _isProcessing
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(),
                      )
                          : const Text("Receive OTP"),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

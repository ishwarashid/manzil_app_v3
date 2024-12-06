import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manzil_app_v3/main.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final _formKey = GlobalKey<FormState>();
  var _firstName = '';
  var _lastName = '';
  var _emailAddress = '';

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final firstName = _firstName.trim();
        final lastName = _lastName.trim();
        final email = _emailAddress.trim().toLowerCase();

        final userData = {
          "phone_number": widget.phoneNumber,
          "first_name": firstName,
          "last_name": lastName,
          "email": email,
          // "isBanned": false,
          "createdAt": Timestamp.now(),
          "updatedAt": Timestamp.now(),
        };

        await FirebaseFirestore.instance
            .collection("users")
            .add(userData);

        if (!mounted) return;

        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MyApp(),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// methods to validate fields
  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return '$fieldName must be less than 50 characters';
    }

    // Check if name contains only letters and spaces
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return '$fieldName can only contain letters and spaces';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(emailRegex);

    if (!regex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    if (value.trim().length > 100) {
      return 'Email must be less than 100 characters';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Let's Get Started",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 45, 45, 45),
                ),
              ),
              const SizedBox(height: 60),
              Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 30,
                    right: 30,
                    bottom: keyboardSpace,
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          label: Text(
                            "First Name",
                            style: TextStyle(fontSize: 18),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        style: const TextStyle(fontSize: 18),
                        textCapitalization: TextCapitalization.words,
                        autocorrect: false,
                        enableSuggestions: false,
                        validator: (value) => _validateName(value, 'First name'),
                        onSaved: (value) => _firstName = value ?? '',
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          label: Text(
                            "Last Name",
                            style: TextStyle(fontSize: 18),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        style: const TextStyle(fontSize: 18),
                        textCapitalization: TextCapitalization.words,
                        autocorrect: false,
                        enableSuggestions: false,
                        validator: (value) => _validateName(value, 'Last name'),
                        onSaved: (value) => _lastName = value ?? '',
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          label: Text(
                            "Email Address",
                            style: TextStyle(fontSize: 18),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        enableSuggestions: false,
                        style: const TextStyle(fontSize: 18),
                        validator: _validateEmail,
                        onSaved: (value) => _emailAddress = value ?? '',
                      ),
                      const SizedBox(height: 60),
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
                          onPressed: _saveData,
                          child: const Text("Finish Setup"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

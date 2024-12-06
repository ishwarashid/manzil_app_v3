import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v3/providers/current_user_provider.dart';

class SetupDriverScreen extends ConsumerStatefulWidget {
  const SetupDriverScreen({super.key});

  @override
  ConsumerState<SetupDriverScreen> createState() => _SetupDriverScreenState();
}

class _SetupDriverScreenState extends ConsumerState<SetupDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  late TextEditingController _licenseController;
  late TextEditingController _cnicController;
  DateTime? _licenseExpiry;
  DateTime? _cnicExpiry;

  @override
  void initState() {
    super.initState();
    _licenseController = TextEditingController();
    _cnicController = TextEditingController();
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  String? _validateLicense(String? value) {
    if (value == null || value.isEmpty) {
      return 'License number is required';
    }
    // XX-XX-XXX
    final RegExp licenseRegex = RegExp(r'^[A-Z]{2}-\d{2}-\d{3}$');
    if (!licenseRegex.hasMatch(value)) {
      return 'Invalid format. Use XX-XX-XXX';
    }
    return null;
  }

  String? _validateCNIC(String? value) {
    if (value == null || value.isEmpty) {
      return 'CNIC is required';
    }
    // XXXXX-XXXXXXX-X
    final RegExp cnicRegex = RegExp(r'^\d{5}-\d{7}-\d{1}$');
    if (!cnicRegex.hasMatch(value)) {
      return 'Invalid format. Use XXXXX-XXXXXXX-X';
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context, bool isLicense) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() {
        if (isLicense) {
          _licenseExpiry = picked;
        } else {
          _cnicExpiry = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_licenseExpiry == null || _cnicExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select expiry dates for both documents'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser['uid'])
          .update({
        'drivingLicense': _licenseController.text,
        'licenseExpiry': Timestamp.fromDate(_licenseExpiry!),
        'cnic': _cnicController.text,
        'cnicExpiry': Timestamp.fromDate(_cnicExpiry!),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver setup completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = (MediaQuery.of(context).viewInsets.bottom / 4);
    print(keyboardSpace);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Setup'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(left: 30, right: 30, bottom: keyboardSpace),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Please provide your driver details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 45, 45, 45),
                    ),
                  ),
                  // const SizedBox(height: 24),
                  const SizedBox(height: 30),


                  TextFormField(
                    controller: _licenseController,
                    decoration: const InputDecoration(
                      labelText: 'License Number',
                      hintText: 'XX-XX-XXX',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: _validateLicense,
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final newText = newValue.text.toUpperCase();
                        return newValue.copyWith(
                          text: newText,
                          selection:
                              TextSelection.collapsed(offset: newText.length),
                        );
                      }),
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9-]')),
                      LengthLimitingTextInputFormatter(9),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    title: const Text('License Expiry Date'),
                    subtitle: Text(
                      _licenseExpiry == null
                          ? 'Not selected'
                          : '${_licenseExpiry!.day}/${_licenseExpiry!.month}/${_licenseExpiry!.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    onTap: () => _selectDate(context, true),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _cnicController,
                    decoration: const InputDecoration(
                      labelText: 'CNIC Number',
                      hintText: 'XXXXX-XXXXXXX-X',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateCNIC,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                      LengthLimitingTextInputFormatter(15),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    title: const Text('CNIC Expiry Date'),
                    subtitle: Text(
                      _cnicExpiry == null
                          ? 'Not selected'
                          : '${_cnicExpiry!.day}/${_cnicExpiry!.month}/${_cnicExpiry!.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    onTap: () => _selectDate(context, false),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Submit',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

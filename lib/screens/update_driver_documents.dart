import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v3/providers/current_user_provider.dart';

class UpdateDriverDocuments extends ConsumerStatefulWidget {
  final bool isCnicExpired;
  final bool isLicenseExpired;
  final Map<String, dynamic> currentData;

  const UpdateDriverDocuments({
    required this.isCnicExpired,
    required this.isLicenseExpired,
    required this.currentData,
    super.key,
  });

  @override
  ConsumerState<UpdateDriverDocuments> createState() => _UpdateDriverDocumentsState();
}

class _UpdateDriverDocumentsState extends ConsumerState<UpdateDriverDocuments> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  late TextEditingController _licenseController;
  late TextEditingController _cnicController;
  DateTime? _licenseExpiry;
  DateTime? _cnicExpiry;

  @override
  void initState() {
    super.initState();
    // we only had to initialize controllers for expired documents
    if (widget.isLicenseExpired) {
      _licenseController = TextEditingController(text: widget.currentData['drivingLicense']);
    }
    if (widget.isCnicExpired) {
      _cnicController = TextEditingController(text: widget.currentData['cnic']);
    }
  }

  @override
  void dispose() {
    if (widget.isLicenseExpired) _licenseController.dispose();
    if (widget.isCnicExpired) _cnicController.dispose();
    super.dispose();
  }

  String? _validateCNIC(String? value) {
    if (value == null || value.isEmpty) {
      return 'CNIC is required';
    }
    final RegExp cnicRegex = RegExp(r'^\d{5}-\d{7}-\d{1}$');
    if (!cnicRegex.hasMatch(value)) {
      return 'Invalid format. Use XXXXX-XXXXXXX-X';
    }
    return null;
  }

  String? _validateLicense(String? value) {
    if (value == null || value.isEmpty) {
      return 'License number is required';
    }
    final RegExp licenseRegex = RegExp(r'^[A-Z]{2}-\d{2}-\d{3}$');
    if (!licenseRegex.hasMatch(value)) {
      return 'Invalid format. Use XX-XX-XXX';
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

    if (widget.isCnicExpired && _cnicExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select CNIC expiry date'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (widget.isLicenseExpired && _licenseExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select license expiry date'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final updates = <String, dynamic>{};

      if (widget.isCnicExpired) {
        updates['cnic'] = _cnicController.text;
        updates['cnicExpiry'] = Timestamp.fromDate(_cnicExpiry!);
      }

      if (widget.isLicenseExpired) {
        updates['drivingLicense'] = _licenseController.text;
        updates['licenseExpiry'] = Timestamp.fromDate(_licenseExpiry!);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(ref.read(currentUserProvider)['uid'])
          .update(updates);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documents updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating documents: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = (MediaQuery.of(context).viewInsets.bottom / 4);
    print(keyboardSpace);
    print(_cnicExpiry);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Documents'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(left: 30, right: 30, bottom: keyboardSpace),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update ${[
                      if(widget.isCnicExpired) 'CNIC',
                      if(widget.isLicenseExpired) 'License'
                    ].join(" and ")}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 45, 45, 45),
                    ),
                  ),
                  const SizedBox(height: 30),

                  if (widget.isCnicExpired) ...[
                    TextFormField(
                      controller: _cnicController,
                      decoration: const InputDecoration(
                        labelText: 'CNIC Number *',
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
                      title: const Text('CNIC Expiry Date *'),
                      subtitle: Text(_cnicExpiry?.toString().split(' ')[0] ?? 'Not selected'),
                      trailing: const Icon(Icons.calendar_today),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                      onTap: () => _selectDate(context, false),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (widget.isLicenseExpired) ...[
                    TextFormField(
                      controller: _licenseController,
                      decoration: const InputDecoration(
                        labelText: 'License Number *',
                        hintText: 'XX-XX-XXX',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: _validateLicense,
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          return newValue.copyWith(text: newValue.text.toUpperCase());
                        }),
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9-]')),
                        LengthLimitingTextInputFormatter(9),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('License Expiry Date *'),
                      subtitle: Text(_licenseExpiry?.toString().split(' ')[0] ?? 'Not selected'),
                      trailing: const Icon(Icons.calendar_today),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                      onTap: () => _selectDate(context, true),
                    ),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      child: _isSubmitting
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text('Update', style: TextStyle(fontSize: 18)),
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
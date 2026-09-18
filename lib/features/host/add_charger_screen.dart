import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_color.dart';
import '../../firebase_options.dart';

class AddChargerScreen extends StatefulWidget {
  const AddChargerScreen({super.key, this.charger})
    : isEditing = charger != null;

  final Map<String, dynamic>? charger;
  final bool isEditing;

  @override
  State<AddChargerScreen> createState() => _AddChargerScreenState();
}

class _AddChargerScreenState extends State<AddChargerScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _maxPowerController = TextEditingController(
    text: '22',
  );
  final TextEditingController _priceController = TextEditingController(
    text: '18',
  );
  final TextEditingController _timeSlotController = TextEditingController(
    text: '08:00 - 22:00',
  );

  final Set<String> _selectedPlugTypes = {'Type 2'};
  final Set<String> _selectedDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri'};
  final List<XFile> _chargerPhotos = [];
  final List<XFile> _parkingPhotos = [];

  final List<String> _plugTypeOptions = ['Type 2', 'CCS2', 'CHAdeMO'];
  final List<String> _daysOfWeek = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  int _currentStep = 0;
  bool _isSaving = false;
  String _selectedLocationLabel = 'Select charger pin on map';
  double? _latitude;
  double? _longitude;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.charger != null) {
      final charger = widget.charger!;
      _titleController.text = (charger['title'] ?? '').toString();
      _descriptionController.text = (charger['description'] ?? '').toString();
      _addressController.text = (charger['address'] ?? '').toString();
      _maxPowerController.text = (charger['maxPowerKw'] ?? 22).toString();
      _priceController.text = (charger['pricePerKwh'] ?? 18).toString();
      _timeSlotController.text =
          (charger['timeSlots'] is List &&
              (charger['timeSlots'] as List).isNotEmpty)
          ? (charger['timeSlots'] as List).first.toString()
          : '08:00 - 22:00';

      if (charger['plugTypes'] is List) {
        _selectedPlugTypes
          ..clear()
          ..addAll(List<String>.from(charger['plugTypes']));
      }

      if (charger['availableDays'] is List) {
        _selectedDays
          ..clear()
          ..addAll(List<String>.from(charger['availableDays']));
      }

      final location = charger['location'];
      if (location is Map) {
        final lat = location['latitude'];
        final lng = location['longitude'];
        if (lat != null) _latitude = double.tryParse(lat.toString());
        if (lng != null) _longitude = double.tryParse(lng.toString());
        _selectedLocationLabel =
            location['name']?.toString() ?? 'Charger pin selected';
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _maxPowerController.dispose();
    _priceController.dispose();
    _timeSlotController.dispose();
    super.dispose();
  }

  Future<void> _pickLocationPin() async {
    final lat = _latitude ?? 6.9271;
    final lng = _longitude ?? 79.8612;

    setState(() {
      _latitude = lat;
      _longitude = lng;
      _selectedLocationLabel = 'Pin selected • $lat, $lng';
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Map pin saved for this charger. You can refine it later.',
        ),
        backgroundColor: AppColors.neonGreen,
      ),
    );
  }

  Future<void> _pickImages({required bool forCharger}) async {
    final picked = await _imagePicker.pickMultiImage();
    if (picked.isEmpty) return;

    setState(() {
      if (forCharger) {
        _chargerPhotos
          ..clear()
          ..addAll(picked);
      } else {
        _parkingPhotos
          ..clear()
          ..addAll(picked);
      }
    });
  }

  Future<void> _saveCharger() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPlugTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose at least one plug type.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one available day.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Firebase is not ready. Please ensure the app is configured correctly.\n$error',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (Firebase.apps.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase is not initialized for host mode.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final hostUserId = FirebaseAuth.instance.currentUser?.uid ?? 'guest-host';
      final docRef = firestore.collection('stations').doc();
      final payload = {
        'id': docRef.id,
        'hostId': hostUserId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'location': {
          'name': _selectedLocationLabel,
          'latitude': _latitude ?? 6.9271,
          'longitude': _longitude ?? 79.8612,
        },
        'plugTypes': _selectedPlugTypes.toList(),
        'maxPowerKw': double.tryParse(_maxPowerController.text) ?? 22,
        'pricePerKwh': double.tryParse(_priceController.text) ?? 18,
        'availableDays': _selectedDays.toList(),
        'timeSlots': [_timeSlotController.text.trim()],
        'chargerPhotos': _chargerPhotos.map((file) => file.path).toList(),
        'parkingPhotos': _parkingPhotos.map((file) => file.path).toList(),
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(payload);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Charger saved successfully.'),
          backgroundColor: AppColors.neonGreen,
        ),
      );

      Navigator.of(context).pop(true);
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save charger. ${error.message ?? 'Try again.'}',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unexpected error while saving charger.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          widget.isEditing ? 'Edit Charger' : 'Add New Charger',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.neonGreen),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepTapped: (step) => setState(() => _currentStep = step),
            physics: const BouncingScrollPhysics(),
            controlsBuilder: (context, details) {
              final isLastStep = _currentStep == 3;
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.neonGreen),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : (isLastStep
                                  ? _saveCharger
                                  : details.onStepContinue),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonGreen,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _isSaving
                              ? 'Saving...'
                              : (isLastStep ? 'Save Charger' : 'Next'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            onStepContinue: () {
              if (_currentStep == 0) {
                final valid =
                    _titleController.text.trim().isNotEmpty &&
                    _addressController.text.trim().isNotEmpty;
                if (!valid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please complete the charger location details.',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
              }

              if (_currentStep < 3) {
                setState(() => _currentStep += 1);
              }
            },
            onStepCancel: _currentStep > 0
                ? () => setState(() => _currentStep -= 1)
                : null,
            steps: [
              Step(
                title: const Text(
                  'Location & Overview',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                content: _buildStepOne(),
              ),
              Step(
                title: const Text(
                  'Connector & Pricing',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                content: _buildStepTwo(),
              ),
              Step(
                title: const Text(
                  'Availability',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                content: _buildStepThree(),
              ),
              Step(
                title: const Text(
                  'Photos',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                content: _buildStepFour(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepOne() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textField(
          controller: _titleController,
          label: 'Charger Title',
          hint: 'Green Grid Station',
          icon: Icons.ev_station_rounded,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Please enter a charger title'
              : null,
        ),
        const SizedBox(height: 16),
        _textField(
          controller: _descriptionController,
          label: 'Description',
          hint: 'Fast charger near the main parking area',
          icon: Icons.description_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        _textField(
          controller: _addressController,
          label: 'Address',
          hint: 'No. 18, Galle Road, Colombo 03',
          icon: Icons.location_on_outlined,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Please enter the charger address'
              : null,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickLocationPin,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.neonGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.push_pin_rounded, color: AppColors.neonGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedLocationLabel,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Plug Types',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _plugTypeOptions.map((type) {
            final selected = _selectedPlugTypes.contains(type);
            return FilterChip(
              label: Text(type),
              selected: selected,
              selectedColor: AppColors.neonGreen,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: selected ? AppColors.background : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) {
                setState(() {
                  if (selected) {
                    _selectedPlugTypes.remove(type);
                  } else {
                    _selectedPlugTypes.add(type);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _textField(
                controller: _maxPowerController,
                label: 'Max Power',
                hint: '22',
                icon: Icons.bolt_rounded,
                keyboardType: TextInputType.number,
                suffixText: 'kW',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _textField(
                controller: _priceController,
                label: 'Price / kWh',
                hint: '18',
                icon: Icons.currency_rupee_rounded,
                keyboardType: TextInputType.number,
                suffixText: 'LKR',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepThree() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Days',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _daysOfWeek.map((day) {
            final selected = _selectedDays.contains(day);
            return ChoiceChip(
              label: Text(day),
              selected: selected,
              selectedColor: AppColors.neonGreen,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: selected ? AppColors.background : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) {
                setState(() {
                  if (selected) {
                    _selectedDays.remove(day);
                  } else {
                    _selectedDays.add(day);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _textField(
          controller: _timeSlotController,
          label: 'Time Slots',
          hint: '08:00 - 22:00',
          icon: Icons.schedule_rounded,
        ),
      ],
    );
  }

  Widget _buildStepFour() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _photoUploadSection(
          title: 'Charger Photos',
          icon: Icons.photo_library_rounded,
          files: _chargerPhotos,
          onTap: () => _pickImages(forCharger: true),
        ),
        const SizedBox(height: 20),
        _photoUploadSection(
          title: 'Parking Space Photos',
          icon: Icons.local_parking_rounded,
          files: _parkingPhotos,
          onTap: () => _pickImages(forCharger: false),
        ),
      ],
    );
  }

  Widget _photoUploadSection({
    required String title,
    required IconData icon,
    required List<XFile> files,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.neonGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.neonGreen.withValues(alpha: 0.25),
                ),
              ),
              child: const Center(
                child: Text(
                  'Tap to upload photos',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          if (files.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: files.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final file = files[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(file.path),
                      width: 110,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffixText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      validator:
          validator ??
          (value) => value == null || value.trim().isEmpty
              ? 'Please enter $label'
              : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        labelStyle: const TextStyle(color: Colors.white70),
        suffixText: suffixText,
        suffixStyle: const TextStyle(color: AppColors.neonGreen),
        filled: true,
        fillColor: AppColors.surface,
        prefixIcon: Icon(icon, color: AppColors.neonGreen),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.neonGreen.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.neonGreen),
        ),
      ),
    );
  }
}

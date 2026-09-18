import 'package:flutter/material.dart';

import '../../core/models/ev_station_model.dart';
import '../../core/theme/app_color.dart';

class AddStationScreen extends StatefulWidget {
  const AddStationScreen({super.key});

  @override
  State<AddStationScreen> createState() => _AddStationScreenState();
}

class _AddStationScreenState extends State<AddStationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  final Set<ConnectorType> _selectedConnectors = {};
  bool _isAvailable = true;

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedConnectors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one connector type'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Charging Station listed successfully!'),
          backgroundColor: AppColors.neonGreen,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Host Your Charger',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Station Details',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              // Station Name Input
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Station / Host Name',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(
                    Icons.ev_station,
                    color: AppColors.neonGreen,
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter station name'
                    : null,
              ),
              const SizedBox(height: 15),

              // Address Input
              TextFormField(
                controller: _addressController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Address / Location Details',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: AppColors.neonGreen,
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter location address'
                    : null,
              ),
              const SizedBox(height: 15),

              // Rate Input
              TextFormField(
                controller: _rateController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Hourly Rate (e.g., LKR 250/hr)',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(
                    Icons.payments,
                    color: AppColors.neonGreen,
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter rate per hour'
                    : null,
              ),
              const SizedBox(height: 25),

              // Connectors Selection
              const Text(
                'Available Connectors',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                children: ConnectorType.values.map((type) {
                  final isSelected = _selectedConnectors.contains(type);
                  return FilterChip(
                    label: Text(
                      type.name.toUpperCase(),
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.background
                            : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.neonGreen,
                    backgroundColor: AppColors.surface,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedConnectors.add(type);
                        } else {
                          _selectedConnectors.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 25),

              // Active Switch
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available for Booking Immediately',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: _isAvailable,
                      activeThumbColor: AppColors.neonGreen,
                      onChanged: (val) => setState(() => _isAvailable = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _submitForm,
                  child: const Text(
                    'List Charging Station',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

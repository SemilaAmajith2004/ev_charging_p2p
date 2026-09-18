import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_color.dart';

class EditProfileScreen extends StatefulWidget {
  final String? initialName;
  final String? initialEmail;
  final String? initialPhone;
  final String? initialVehicle;
  final String? initialImagePath;

  // Backward-compatible aliases for existing callers.
  final String? currentName;
  final String? currentEmail;
  final String? currentPhone;
  final String? currentVehicle;
  final String? currentImagePath;

  const EditProfileScreen({
    super.key,
    this.initialName,
    this.initialEmail,
    this.initialPhone,
    this.initialVehicle,
    this.initialImagePath,
    this.currentName,
    this.currentEmail,
    this.currentPhone,
    this.currentVehicle,
    this.currentImagePath,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _vehicleController;

  @override
  void initState() {
    super.initState();
    final name = widget.initialName ?? widget.currentName ?? 'Semila Amajith';
    final email =
        widget.initialEmail ?? widget.currentEmail ?? 'semila@evgrid.io';
    final phone =
        widget.initialPhone ?? widget.currentPhone ?? '+94 77 123 4567';
    final vehicle =
        widget.initialVehicle ?? widget.currentVehicle ?? 'Nissan Leaf ZE1';
    final imagePath = widget.initialImagePath ?? widget.currentImagePath;

    _nameController = TextEditingController(text: name);
    _emailController = TextEditingController(text: email);
    _phoneController = TextEditingController(text: phone);
    _vehicleController = TextEditingController(text: vehicle);

    if (imagePath != null) {
      _selectedImage = XFile(imagePath);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImage = pickedFile;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to pick image: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.neonGreen,
                ),
                title: const Text(
                  'Choose from gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: AppColors.neonGreen,
                ),
                title: const Text(
                  'Take a photo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Remove photo',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.neonGreen,
          duration: Duration(seconds: 2),
        ),
      );

      // Return Map object to ProfileScreen
      Navigator.pop(context, {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'vehicle': _vehicleController.text,
        'imagePath': _selectedImage?.path,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF161922),
        elevation: 0,
        title: const Text(
          'EDIT_PROFILE',
          style: TextStyle(
            color: AppColors.neonGreen,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Avatar with Edit Badge
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _showImageSourcePicker,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.neonGreen.withValues(
                            alpha: 0.2,
                          ),
                          backgroundImage: _selectedImage != null
                              ? FileImage(File(_selectedImage!.path))
                              : null,
                          child: _selectedImage == null
                              ? const Icon(
                                  Icons.person,
                                  size: 65,
                                  color: AppColors.neonGreen,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImageSourcePicker,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.neonGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Personal Info Section
                _buildSectionTitle('PERSONAL_DETAILS'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Name cannot be empty'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) =>
                      val == null || !val.contains('@') || val.trim().isEmpty
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 28),

                // Vehicle Info Section
                _buildSectionTitle('VEHICLE_INFO'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _vehicleController,
                  label: 'Primary EV Model',
                  icon: Icons.electric_car_outlined,
                ),

                const SizedBox(height: 36),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _saveProfile,
                    child: const Text(
                      'SAVE CHANGES',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 17),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 15),
        prefixIcon: Icon(icon, color: AppColors.neonGreen, size: 22),
        filled: true,
        fillColor: const Color(0xFF161922),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonGreen),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}

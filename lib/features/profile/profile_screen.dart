import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_color.dart';
import '../auth/role_selection_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserRole initialRole;
  final ValueChanged<UserRole>? onRoleChanged;

  const ProfileScreen({
    super.key,
    this.initialRole = UserRole.driver,
    this.onRoleChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  FirebaseAuth? _auth;
  late UserRole _selectedRole;

  String _userName = 'Semila Amajith';
  String _userEmail = 'semila@evgrid.io';
  String _userPhone = '+94 77 123 4567';
  String _vehicleModel = 'Nissan Leaf ZE1';
  String? _profileImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _auth = Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null;
    _selectedRole = widget.initialRole;
    _syncUserProfile();
  }

  bool get _isHost => _selectedRole == UserRole.host;

  void _syncUserProfile() {
    final user = _auth?.currentUser;
    if (user == null) return;

    setState(() {
      _userName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : 'EV Driver';
      _userEmail = user.email ?? _userEmail;
      _userPhone = user.phoneNumber ?? _userPhone;
    });
  }

  void _toggleRole(bool value) {
    setState(() {
      _selectedRole = value ? UserRole.host : UserRole.driver;
    });
    widget.onRoleChanged?.call(_selectedRole);
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          initialName: _userName,
          initialEmail: _userEmail,
          initialPhone: _userPhone,
          initialVehicle: _vehicleModel,
          initialImagePath: _profileImagePath,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _userName = (result['name'] as String?)?.trim().isNotEmpty == true
          ? result['name'] as String
          : _userName;
      _userEmail = (result['email'] as String?)?.trim().isNotEmpty == true
          ? result['email'] as String
          : _userEmail;
      _userPhone = (result['phone'] as String?)?.trim().isNotEmpty == true
          ? result['phone'] as String
          : _userPhone;
      _vehicleModel = (result['vehicle'] as String?)?.trim().isNotEmpty == true
          ? result['vehicle'] as String
          : _vehicleModel;
      _profileImagePath = result['imagePath'] as String?;
    });
  }

  Future<void> _changePassword() async {
    final user = _auth?.currentUser;
    if (user == null || user.email == null) {
      _showMessage(
        'No active user found. Please sign in again.',
        Colors.redAccent,
      );
      return;
    }

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161922),
          title: const Text(
            'Change Password',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGreen,
              ),
              onPressed: () async {
                final currentPassword = currentPasswordController.text.trim();
                final newPassword = newPasswordController.text.trim();

                if (currentPassword.isEmpty || newPassword.isEmpty) {
                  _showMessage(
                    'Both password fields are required.',
                    Colors.redAccent,
                  );
                  return;
                }

                if (newPassword.length < 6) {
                  _showMessage(
                    'New password must be at least 6 characters.',
                    Colors.redAccent,
                  );
                  return;
                }

                try {
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPassword,
                  );

                  await user.reauthenticateWithCredential(credential);
                  await user.updatePassword(newPassword);

                  if (!mounted) return;
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully.'),
                      backgroundColor: AppColors.neonGreen,
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  if (!mounted) return;
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(_parseAuthError(e)),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                } catch (_) {
                  if (!mounted) return;
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Unable to change password. Please try again.',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text(
                'Update',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    setState(() => _isLoading = true);
    try {
      if (_auth == null) {
        if (!mounted) return;
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
          (route) => false,
        );
        return;
      }

      await _auth!.signOut();
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(_parseAuthError(e), Colors.redAccent);
    } catch (_) {
      _showMessage(
        'Unable to sign out right now. Please try again.',
        Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseAuthError(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'user-not-found':
        return 'No user found with this account.';
      case 'wrong-password':
        return 'The current password is incorrect.';
      case 'requires-recent-login':
        return 'Please sign in again and try one more time.';
      case 'weak-password':
        return 'The new password is too weak.';
      case 'email-already-in-use':
        return 'This email is already associated with another account.';
      default:
        return exception.message ?? 'Authentication error occurred.';
    }
  }

  void _showMessage(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }

  List<Widget> get _driverMenuItems => [
    _buildMenuTile(
      icon: Icons.history,
      title: 'My Bookings History',
      subtitle: 'Recent rides and charging sessions',
      onTap: () {},
    ),
    _buildMenuTile(
      icon: Icons.bookmark_border,
      title: 'Saved Chargers',
      subtitle: 'Favourite stations and bookmarked locations',
      onTap: () {},
    ),
    _buildMenuTile(
      icon: Icons.electric_car,
      title: 'Vehicle Info',
      subtitle: 'EV model: $_vehicleModel',
      onTap: () {},
    ),
    _buildMenuTile(
      icon: Icons.payment,
      title: 'Payment Methods',
      subtitle: 'Cards, wallets, and auto-pay settings',
      onTap: () {},
    ),
    _buildMenuTile(
      icon: Icons.help_outline,
      title: 'Help & Support',
      subtitle: 'Need assistance? Contact support',
      onTap: () {},
    ),
  ];

  List<Widget> get _hostMenuItems => [
    _buildMenuTile(
      icon: Icons.ev_station,
      title: 'My Chargers',
      subtitle: 'Manage your station list and availability',
      onTap: () {},
    ),
    _buildMenuTile(
      icon: Icons.attach_money,
      title: 'Earnings & Payout History',
      subtitle: 'Revenue trends and settlement history',
      onTap: () {},
    ),
    _buildMenuTile(
      icon: Icons.star_border,
      title: 'Host Reviews',
      subtitle: 'Feedback from drivers and guests',
      onTap: () {},
    ),
    _buildMenuTile(
      icon: Icons.schedule,
      title: 'Charger Schedule Settings',
      subtitle: 'Time windows, capacity, and slot rules',
      onTap: () {},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final menuItems = _isHost ? _hostMenuItems : _driverMenuItems;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _openEditProfile,
                    icon: const Icon(
                      Icons.edit_note_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'Edit profile',
                  ),
                ],
              ),
              const SizedBox(height: 22),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF121813),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.neonGreen.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: AppColors.neonGreen.withValues(
                            alpha: 0.12,
                          ),
                          backgroundImage: _profileImagePath != null
                              ? FileImage(File(_profileImagePath!))
                              : null,
                          child: _profileImagePath == null
                              ? const Icon(
                                  Icons.person,
                                  color: AppColors.neonGreen,
                                  size: 40,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.neonGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF121813),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userEmail,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _userPhone,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isHost
                                  ? AppColors.neonGreen.withValues(alpha: 0.14)
                                  : Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _isHost ? 'Host • Premium' : 'Driver • Level 4',
                              style: TextStyle(
                                color: _isHost
                                    ? AppColors.neonGreen
                                    : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF161922),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.neonGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isHost
                              ? AppColors.neonGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: GestureDetector(
                          onTap: () => _toggleRole(false),
                          child: Center(
                            child: Text(
                              'Driver',
                              style: TextStyle(
                                color: !_isHost ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isHost
                              ? AppColors.neonGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: GestureDetector(
                          onTap: () => _toggleRole(true),
                          child: Center(
                            child: Text(
                              'Host',
                              style: TextStyle(
                                color: _isHost ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _statsCard(
                      title: _isHost ? 'Earnings' : 'Spent',
                      value: _isHost ? 'LKR 12.5k' : 'LKR 4.2k',
                      icon: Icons.account_balance_wallet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statsCard(
                      title: _isHost ? 'Sessions' : 'Bookings',
                      value: _isHost ? '18' : '07',
                      icon: Icons.electric_bolt,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              const Text(
                'Account',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              _buildActionTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: _openEditProfile,
              ),
              _buildActionTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: _changePassword,
              ),
              _buildActionTile(
                icon: Icons.logout,
                title: 'Logout',
                color: Colors.redAccent,
                onTap: _logout,
              ),

              const SizedBox(height: 18),

              const Text(
                'Menu',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              ...menuItems,

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.neonGreen,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.neonGreen, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = AppColors.neonGreen,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: color == Colors.redAccent ? Colors.redAccent : Colors.white,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white70,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.neonGreen.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.neonGreen),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: onTap,
      ),
    );
  }
}

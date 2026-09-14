import 'package:flutter/material.dart';
import '../../core/theme/app_color.dart';
import '../auth/role_selection_screen.dart';

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
  late UserRole _currentRole;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.initialRole;
  }

  bool get _isHost => _currentRole == UserRole.host;

  void _toggleRole(bool value) {
    setState(() {
      _currentRole = value ? UserRole.host : UserRole.driver;
    });
    if (widget.onRoleChanged != null) {
      widget.onRoleChanged!(_currentRole);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'USER_PROFILE',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white70,
                      size: 26,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161922),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.neonGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: AppColors.neonGreen.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.person,
                        size: 45,
                        color: AppColors.neonGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Semila Amajith',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'semila@evgrid.io',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isHost ? 'Host • Station Owner' : 'EV Pilot • Level 4',
                            style: const TextStyle(
                              color: AppColors.neonGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Mode Toggle (Driver vs Host) Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161922),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.neonGreen.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isHost ? Icons.ev_station : Icons.directions_car,
                          color: AppColors.neonGreen,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ACTIVE_MODE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isHost ? 'Host Mode' : 'Driver Mode',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _isHost,
                      activeColor: AppColors.neonGreen,
                      activeTrackColor: AppColors.neonGreen.withValues(alpha: 0.3),
                      onChanged: _toggleRole,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stats Row (Dynamic content)
              Row(
                children: [
                  Expanded(
                    child: _buildStatTile(
                      title: _isHost ? 'TOTAL EARNINGS' : 'TOTAL SPENT',
                      value: _isHost ? 'LKR 12,500' : 'LKR 4,200',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatTile(
                      title: _isHost ? 'HOSTED SESSIONS' : 'TOTAL BOOKINGS',
                      value: _isHost ? '18' : '7',
                      icon: Icons.history,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Menu Options
              if (!_isHost)
                _buildMenuItem(Icons.electric_car, 'Vehicle Information', () {}),
              _buildMenuItem(
                Icons.history,
                _isHost ? 'Hosting History' : 'Charging History',
                () {},
              ),
              _buildMenuItem(Icons.payment, 'Payment Methods', () {}),
              _buildMenuItem(Icons.security, 'Security & Privacy', () {}),
              _buildMenuItem(Icons.help_outline, 'Support & FAQs', () {}),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RoleSelectionScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'LOGOUT',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.neonGreen, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.neonGreen, size: 24),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.white70,
        ),
        onTap: onTap,
      ),
    );
  }
}
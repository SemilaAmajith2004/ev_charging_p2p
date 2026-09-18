import 'package:flutter/material.dart';

import '../../core/theme/app_color.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({super.key});

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  bool _isOnline = true;

  final List<Map<String, dynamic>> _bookingRequests = [
    {
      'name': 'Nimali S.',
      'vehicle': 'Tesla Model 3',
      'location': 'Colombo 07',
      'time': 'Today • 18:30 - 20:00',
      'amount': 'LKR 850',
      'status': 'Request sent',
    },
    {
      'name': 'Kasun P.',
      'vehicle': 'Hyundai Ioniq 5',
      'location': 'Bambalapitiya',
      'time': 'Today • 21:00 - 22:30',
      'amount': 'LKR 640',
      'status': 'Waiting approval',
    },
    {
      'name': 'Aisha M.',
      'vehicle': 'BMW i4',
      'location': 'Kollupitiya',
      'time': 'Tomorrow • 09:00 - 10:30',
      'amount': 'LKR 760',
      'status': 'Needs review',
    },
  ];

  void _handleBookingDecision(int index, bool accepted) {
    setState(() {
      _bookingRequests.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          accepted ? 'Booking request accepted.' : 'Booking request declined.',
        ),
        backgroundColor: accepted ? AppColors.neonGreen : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Host Dashboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _isOnline
                  ? AppColors.neonGreen.withValues(alpha: 0.15)
                  : Colors.redAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _isOnline
                    ? AppColors.neonGreen.withValues(alpha: 0.4)
                    : Colors.redAccent.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: _isOnline ? AppColors.neonGreen : Colors.redAccent,
                  size: 10,
                ),
                const SizedBox(width: 6),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: _isOnline ? AppColors.neonGreen : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Earnings',
                      value: 'LKR 24.8k',
                      icon: Icons.account_balance_wallet_rounded,
                      accent: AppColors.neonGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Sessions Hosted',
                      value: '148',
                      icon: Icons.electric_bolt_rounded,
                      accent: AppColors.solarAmber,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.neonGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.power_settings_new_rounded,
                        color: AppColors.neonGreen,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Charger Status',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isOnline
                                ? 'Online & accepting bookings'
                                : 'Offline & paused',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isOnline,
                      activeTrackColor: AppColors.neonGreen.withValues(
                        alpha: 0.45,
                      ),
                      activeThumbColor: AppColors.neonGreen,
                      onChanged: (value) {
                        setState(() => _isOnline = value);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pending Booking Requests',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_bookingRequests.length} new',
                    style: const TextStyle(
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_bookingRequests.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Text(
                      'No pending booking requests.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bookingRequests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final request = _bookingRequests[index];
                    return _buildRequestCard(index, request);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 24),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(int index, Map<String, dynamic> request) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.neonGreen.withValues(alpha: 0.15),
                child: Text(
                  (request['name'] as String).substring(0, 1),
                  style: const TextStyle(
                    color: AppColors.neonGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['name'],
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request['vehicle'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  request['status'],
                  style: const TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.location_on_outlined, request['location']),
          const SizedBox(height: 6),
          _infoRow(Icons.access_time_rounded, request['time']),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request['amount'],
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _handleBookingDecision(index, false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.12),
                    ),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Decline'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _handleBookingDecision(index, true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: AppColors.neonGreen,
                    ),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Accept'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.neonGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

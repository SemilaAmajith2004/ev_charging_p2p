import 'package:flutter/material.dart';

import '../../core/theme/app_color.dart';
import '../bookings/booking_modal.dart';

class StationDetailsScreen extends StatefulWidget {
  const StationDetailsScreen({
    super.key,
    required this.stationName,
    required this.address,
    required this.pricePerKwh,
    required this.totalPowerKw,
    required this.connectorTypes,
    required this.hostName,
    required this.rating,
    required this.isAvailable,
    this.images,
  });

  final String stationName;
  final String address;
  final double pricePerKwh;
  final double totalPowerKw;
  final List<String> connectorTypes;
  final String hostName;
  final double rating;
  final bool isAvailable;
  final List<String>? images;

  @override
  State<StationDetailsScreen> createState() => _StationDetailsScreenState();
}

class _StationDetailsScreenState extends State<StationDetailsScreen> {
  final PageController _pageController = PageController();
  int _activeImageIndex = 0;
  bool _isFavorite = false;

  List<String> get _stationImages =>
      widget.images ??
      const [
        'https://images.unsplash.com/photo-1593941707882-a5bac6861d75?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=1200&q=80',
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openBookingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingModal(pricePerKwh: widget.pricePerKwh),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 270,
              pinned: false,
              leadingWidth: 48,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.background,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: _stationImages.length,
                      onPageChanged: (index) =>
                          setState(() => _activeImageIndex = index),
                      itemBuilder: (context, index) {
                        return Image.network(
                          _stationImages[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.surface,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported_rounded,
                                color: AppColors.neonGreen,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 48,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _iconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Row(
                            children: [
                              _iconButton(
                                icon: Icons.share_rounded,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Share link copied.'),
                                      backgroundColor: AppColors.neonGreen,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              _iconButton(
                                icon: _isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                onPressed: () =>
                                    setState(() => _isFavorite = !_isFavorite),
                                color: _isFavorite
                                    ? Colors.redAccent
                                    : Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: Row(
                        children: List.generate(
                          _stationImages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _activeImageIndex == index ? 18 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: _activeImageIndex == index
                                  ? AppColors.neonGreen
                                  : Colors.white38,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.stationName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppColors.solarAmber,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${widget.rating.toStringAsFixed(1)} / 5.0',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.isAvailable
                                          ? AppColors.neonGreen.withValues(
                                              alpha: 0.14,
                                            )
                                          : AppColors.solarAmber.withValues(
                                              alpha: 0.18,
                                            ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      widget.isAvailable
                                          ? 'Available Now'
                                          : 'In Use',
                                      style: TextStyle(
                                        color: widget.isAvailable
                                            ? AppColors.neonGreen
                                            : AppColors.solarAmber,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'LKR ${widget.pricePerKwh.toStringAsFixed(0)} / kWh',
                            style: const TextStyle(
                              color: AppColors.neonGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.neonGreen.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AppColors.neonGreen.withValues(
                                  alpha: 0.15,
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.neonGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Hosted by',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      widget.hostName,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.neonGreen,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _infoRow(Icons.location_on_outlined, widget.address),
                          const SizedBox(height: 12),
                          _infoRow(
                            Icons.electric_bolt_rounded,
                            '${widget.totalPowerKw.toStringAsFixed(0)} kW total output',
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            Icons.power_rounded,
                            widget.connectorTypes.join(' • '),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      'Reviews & Ratings',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _reviewCard(
                      name: 'Micheal R.',
                      comment: 'Clean station, fast charging, and the host was very helpful. Highly recommended.',
                      rating: 5,
                      response: 'Thanks for the review! I usually keep the charger ready before peak hours.',
                    ),
                    const SizedBox(height: 12),
                    _reviewCard(
                      name: 'Dulani K.',
                      comment: 'Easy to find, great location, and charging speeds were consistent.',
                      rating: 4,
                      response: 'Glad it worked well for you. I’ll keep my schedule updated for future bookings.',
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _openBookingModal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonGreen,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Book a Slot',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewCard({
    required String name,
    required String comment,
    required int rating,
    required String response,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.solarAmber,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Host response: ',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: response,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.neonGreen, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 20),
        splashRadius: 18,
      ),
    );
  }
}

enum BookingStatus { pending, confirmed, charging, completed, cancelled }

class BookingModel {
  final String bookingId;
  final String stationId;
  final String driverId;
  final DateTime startTime;
  final DateTime endTime;
  final double estimatedCost;
  final BookingStatus status;

  const BookingModel({
    required this.bookingId,
    required this.stationId,
    required this.driverId,
    required this.startTime,
    required this.endTime,
    required this.estimatedCost,
    this.status = BookingStatus.confirmed,
  });

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'stationId': stationId,
      'driverId': driverId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'estimatedCost': estimatedCost,
      'status': status.name,
    };
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['bookingId'] as String,
      stationId: json['stationId'] as String,
      driverId: json['driverId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      estimatedCost: (json['estimatedCost'] as num).toDouble(),
      status: BookingStatus.values.byName(json['status'] as String),
    );
  }
}
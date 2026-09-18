import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Time Slot එකේ කාලය පහසුවෙන් ගන්න (Hours වලින්)
  double get durationInHours => endTime.difference(startTime).inMinutes / 60.0;

  // Active Booking එකක්ද කියා බලන්න
  bool get isActive =>
      status == BookingStatus.confirmed || status == BookingStatus.charging;

  // වෙනත් Booking එකක් එක්ක Time Slot එක Overlap වෙනවාද (හැපෙනවාද) කියා පරීක්ෂා කිරීමට
  bool overlapsWith(DateTime newStart, DateTime newEnd) {
    return newStart.isBefore(endTime) && newEnd.isAfter(startTime);
  }

  // State Updates සදහා copyWith Method එක
  BookingModel copyWith({
    String? bookingId,
    String? stationId,
    String? driverId,
    DateTime? startTime,
    DateTime? endTime,
    double? estimatedCost,
    BookingStatus? status,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      stationId: stationId ?? this.stationId,
      driverId: driverId ?? this.driverId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'stationId': stationId,
      'driverId': driverId,
      'startTime': Timestamp.fromDate(startTime), // Firestore Timestamps සඳහා
      'endTime': Timestamp.fromDate(endTime),
      'estimatedCost': estimatedCost,
      'status': status.name,
    };
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // String (ISO String) හෝ Timestamp දෙකෙන්ම parse කරගත හැකි වන සේ සකසා ඇත
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    return BookingModel(
      bookingId: json['bookingId'] as String? ?? '',
      stationId: json['stationId'] as String? ?? '',
      driverId: json['driverId'] as String? ?? '',
      startTime: parseDateTime(json['startTime']),
      endTime: parseDateTime(json['endTime']),
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble() ?? 0.0,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.confirmed,
      ),
    );
  }
}
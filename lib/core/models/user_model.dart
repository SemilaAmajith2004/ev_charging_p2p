import 'ev_station_model.dart';

enum UserRole { driver, host, both }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String vehicleModel;
  final ConnectorType vehicleConnector;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.vehicleModel,
    required this.vehicleConnector,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.name,
      'vehicleModel': vehicleModel,
      'vehicleConnector': vehicleConnector.name,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.byName(json['role'] as String),
      vehicleModel: json['vehicleModel'] as String,
      vehicleConnector: ConnectorType.values.byName(json['vehicleConnector'] as String),
    );
  }
}
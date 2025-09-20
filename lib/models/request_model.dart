class ServiceRequest {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String userLocation;
  final String userAddress;
  final String issueDescription;
  final String vehicleType;
  final String vehicleModel;
  final List<String> mechanicIds;
  final String status; // pending, accepted, rejected, completed
  final String acceptedMechanicId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userLocation,
    required this.userAddress,
    required this.issueDescription,
    required this.vehicleType,
    required this.vehicleModel,
    required this.mechanicIds,
    this.status = 'pending',
    this.acceptedMechanicId = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceRequest.fromMap(Map<String, dynamic> map) {
    return ServiceRequest(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? '',
      userPhone: map['user_phone'] ?? '',
      userLocation: map['user_location'] ?? '',
      userAddress: map['user_address'] ?? '',
      issueDescription: map['issue_description'] ?? '',
      vehicleType: map['vehicle_type'] ?? '',
      vehicleModel: map['vehicle_model'] ?? '',
      mechanicIds: List<String>.from(map['mechanic_ids'] ?? []),
      status: map['status'] ?? 'pending',
      acceptedMechanicId: map['accepted_mechanic_id'] ?? '',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_phone': userPhone,
      'user_location': userLocation,
      'user_address': userAddress,
      'issue_description': issueDescription,
      'vehicle_type': vehicleType,
      'vehicle_model': vehicleModel,
      'mechanic_ids': mechanicIds,
      'status': status,
      'accepted_mechanic_id': acceptedMechanicId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
// lib/models/mechanic_list_item.dart
class MechanicListItem {
  final String id;
  final String userId;
  final String name;
  final String phoneNumber;
  final String email;
  final String location;
  final double rating;
  final int totalReviews;
  final String specialization;
  final int yearsOfExperience;
  final bool isAvailable;

  MechanicListItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.location,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.specialization = 'General Mechanic',
    this.yearsOfExperience = 0,
    this.isAvailable = true,
  });

  factory MechanicListItem.fromMap(Map<String, dynamic> map) {
    return MechanicListItem(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown Mechanic',
      phoneNumber: map['phone_number']?.toString() ?? 'Not provided',
      email: map['email']?.toString() ?? 'Not provided',
      location: map['location']?.toString() ?? 'Location not specified',
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 0.0,
      totalReviews: (map['total_reviews'] is int) ? map['total_reviews'] as int : 0,
      specialization: map['specialization']?.toString() ?? 'General Mechanic',
      yearsOfExperience: (map['years_of_experience'] is int) ? map['years_of_experience'] as int : 0,
      isAvailable: (map['is_available'] is bool) ? map['is_available'] as bool : true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'location': location,
      'rating': rating,
      'total_reviews': totalReviews,
      'specialization': specialization,
      'years_of_experience': yearsOfExperience,
      'is_available': isAvailable,
    };
  }
}
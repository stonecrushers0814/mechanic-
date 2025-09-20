import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mechanic_profile.dart';
import '../models/user_profile.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Mechanic profile methods
  Future<MechanicProfile?> getMechanicProfile(String userId) async {
    try {
      final profileMap = await _supabase
          .from('mechanic_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (profileMap != null) {
        return MechanicProfile.fromMap(profileMap);
      }
      return null;
    } catch (e) {
      print('Error getting mechanic profile: $e');
      return null;
    }
  }

  Future<bool> hasMechanicProfile(String userId) async {
    try {
      final profileMap = await _supabase
          .from('mechanic_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return profileMap != null;
    } catch (e) {
      print('Error checking mechanic profile: $e');
      return false;
    }
  }

  // User profile methods
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final profileMap = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (profileMap != null) {
        return UserProfile.fromMap(profileMap);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<bool> hasUserProfile(String userId) async {
    try {
      final profileMap = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return profileMap != null;
    } catch (e) {
      print('Error checking user profile: $e');
      return false;
    }
  }

  // Save methods for both user and mechanic profiles
  Future<void> saveUserProfile({
    required String userId,
    required String name,
    required String phoneNumber,
    required String email,
  }) async {
    try {
      // Check if profile exists
      final existingProfile = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existingProfile != null) {
        // Update existing profile
        await _supabase
            .from('user_profiles')
            .update({
              'name': name,
              'phone_number': phoneNumber,
              'email': email,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      } else {
        // Create new profile
        await _supabase
            .from('user_profiles')
            .insert({
              'user_id': userId,
              'name': name,
              'phone_number': phoneNumber,
              'email': email,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      print('Error saving user profile: $e');
      rethrow;
    }
  }

  Future<void> saveMechanicProfile({
    required String userId,
    required String name,
    required String phoneNumber,
    required String email,
    required String location,
  }) async {
    try {
      // Check if profile exists
      final existingProfile = await _supabase
          .from('mechanic_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existingProfile != null) {
        // Update existing profile
        await _supabase
            .from('mechanic_profiles')
            .update({
              'name': name,
              'phone_number': phoneNumber,
              'email': email,
              'location': location,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      } else {
        // Create new profile
        await _supabase
            .from('mechanic_profiles')
            .insert({
              'user_id': userId,
              'name': name,
              'phone_number': phoneNumber,
              'email': email,
              'location': location,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      print('Error saving mechanic profile: $e');
      rethrow;
    }
  }
}
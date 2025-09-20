import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/request_model.dart';
import '../models/mechanic_list_item.dart';

class RequestService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ServiceRequest>> getMechanicRequests(String mechanicId) async {
    try {
      final requestsData = await _supabase
          .from('service_requests')
          .select('*')
          .contains('mechanic_ids', [mechanicId])
          .order('created_at', ascending: false);

      if (requestsData != null) {
        return requestsData.map((map) => ServiceRequest.fromMap(map)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting mechanic requests: $e');
      return [];
    }
  }

  // Update request status
  Future<void> updateRequestStatus(String requestId, String status, {String? acceptedMechanicId}) async {
    try {
      final updates = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (acceptedMechanicId != null) {
        updates['accepted_mechanic_id'] = acceptedMechanicId;
      }

      await _supabase
          .from('service_requests')
          .update(updates)
          .eq('id', requestId);
    } catch (e) {
      print('Error updating request status: $e');
      rethrow;
    }
  }

  // Create notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedRequestId,
  }) async {
    try {
      await _supabase
          .from('notifications')
          .insert({
            'user_id': userId,
            'title': title,
            'message': message,
            'type': type,
            'related_request_id': relatedRequestId,
            'created_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  // Create a new service request
  Future<String> createServiceRequest({
    required String userId,
    required String userName,
    required String userPhone,
    required String userLocation,
    required String userAddress,
    required String issueDescription,
    required String vehicleType,
    required String vehicleModel,
    required List<String> mechanicIds,
  }) async {
    try {
      final response = await _supabase
          .from('service_requests')
          .insert({
            'user_id': userId,
            'user_name': userName,
            'user_phone': userPhone,
            'user_location': userLocation,
            'user_address': userAddress,
            'issue_description': issueDescription,
            'vehicle_type': vehicleType,
            'vehicle_model': vehicleModel,
            'mechanic_ids': mechanicIds,
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      print('Error creating service request: $e');
      rethrow;
    }
  }

  // Get requests for a user
  Future<List<ServiceRequest>> getUserRequests(String userId) async {
    try {
      final requestsData = await _supabase
          .from('service_requests')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return requestsData.map((map) => ServiceRequest.fromMap(map)).toList();
    } catch (e) {
      print('Error getting user requests: $e');
      return [];
    }
  }

  // // Get requests for a mechanic
  // Future<List<ServiceRequest>> getMechanicRequests(String mechanicId) async {
  //   try {
  //     final requestsData = await _supabase
  //         .from('service_requests')
  //         .select('*')
  //         .contains('mechanic_ids', [mechanicId])
  //         .order('created_at', ascending: false);

  //     return requestsData.map((map) => ServiceRequest.fromMap(map)).toList();
  //   } catch (e) {
  //     print('Error getting mechanic requests: $e');
  //     return [];
  //   }
  // }

  // // Update request status
  // Future<void> updateRequestStatus(String requestId, String status, {String? acceptedMechanicId}) async {
  //   try {
  //     final updates = {
  //       'status': status,
  //       'updated_at': DateTime.now().toIso8601String(),
  //     };

  //     if (acceptedMechanicId != null) {
  //       updates['accepted_mechanic_id'] = acceptedMechanicId;
  //     }

  //     await _supabase
  //         .from('service_requests')
  //         .update(updates)
  //         .eq('id', requestId);
  //   } catch (e) {
  //     print('Error updating request status: $e');
  //     rethrow;
  //   }
  // }

  // // Create notification
  // Future<void> createNotification({
  //   required String userId,
  //   required String title,
  //   required String message,
  //   required String type,
  //   String? relatedRequestId,
  // }) async {
  //   try {
  //     await _supabase
  //         .from('notifications')
  //         .insert({
  //           'user_id': userId,
  //           'title': title,
  //           'message': message,
  //           'type': type,
  //           'related_request_id': relatedRequestId,
  //         });
  //   } catch (e) {
  //     print('Error creating notification: $e');
  //     rethrow;
  //   }
  // }

  // Get user notifications
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      return await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }
}
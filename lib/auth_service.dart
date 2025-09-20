// lib/auth_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _currentUser;
  String? _currentUserRole;
  bool _isLoading = true;

  AuthService() {
    _getCurrentUser();
    _supabase.auth.onAuthStateChange.listen((AuthState data) {
      _getCurrentUser();
    });
  }

  User? get currentUser => _currentUser;
  String? get currentUserRole => _currentUserRole;
  bool get isLoading => _isLoading;

  Future<void> _getCurrentUser() async {
    try {
      _currentUser = _supabase.auth.currentUser;
      
      if (_currentUser != null) {
        // Fetch user role from profiles table
        final profile = await _supabase
            .from('profiles')
            .select('role')
            .eq('id', _currentUser!.id)
            .maybeSingle();

        if (profile != null) {
          _currentUserRole = profile['role'];
        }
      }
    } catch (e) {
      print('Error getting current user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // Sign up without email confirmation
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': role,
        },
      );
      
      if (response.user != null) {
        // Insert user profile with role
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'role': role,
        });
        
        // Immediately sign in after sign up
        final AuthResponse loginResponse = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        
        _currentUser = loginResponse.user;
        _currentUserRole = role;
        notifyListeners();
      }
      
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      _currentUser = response.user;
      
      // Fetch user role
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', _currentUser!.id)
          .maybeSingle();
          
      if (profile != null) {
        _currentUserRole = profile['role'];
      }
      
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      _currentUserRole = null;
      notifyListeners();
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
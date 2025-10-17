import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'role_selection_page.dart';
import 'user_home_page.dart';
import 'user_profile_form.dart';
import 'mechanic_home_page.dart';
import 'mechanic_profile_form.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'map_sample.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  bool _checkingProfile = true;
  bool _userHasProfile = false;
  bool _mechanicHasProfile = false;
  String? _lastCheckedUserId;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _checkProfiles();
  }

  Future<void> _checkProfiles() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (authService.currentUser != null) {
      try {
        final role = authService.currentUserRole;
        
        if (role == 'user') {
          final profile = await Supabase.instance.client
              .from('user_profiles')
              .select()
              .eq('user_id', authService.currentUser!.id)
              .maybeSingle();

          setState(() {
            _userHasProfile = profile != null;
            _checkingProfile = false;
          });
        } else if (role == 'mechanic') {
          final profile = await Supabase.instance.client
              .from('mechanic_profiles')
              .select()
              .eq('user_id', authService.currentUser!.id)
              .maybeSingle();

          setState(() {
            _mechanicHasProfile = profile != null;
            _checkingProfile = false;
          });
        } else {
          setState(() {
            _checkingProfile = false;
          });
        }
      } catch (e) {
        setState(() {
          _checkingProfile = false;
        });
      }
    } else {
      setState(() {
        _checkingProfile = false;
      });
    }
    // Allow navigation after profile check completes
    _didNavigate = false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Trigger profile re-check when the signed-in user changes
        final currentUserId = authService.currentUser?.id;
        if (currentUserId != _lastCheckedUserId && authService.currentUser != null && !_checkingProfile) {
          _checkingProfile = true;
          _userHasProfile = false;
          _mechanicHasProfile = false;
          _lastCheckedUserId = currentUserId;
          // Schedule async check to avoid calling setState during build
          Future.microtask(_checkProfiles);
        }

        if (authService.isLoading || _checkingProfile) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Perform navigation via named routes based on state (once per resolution)
        if (!_didNavigate) {
          _didNavigate = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (authService.currentUser == null) {
              _lastCheckedUserId = null;
              _userHasProfile = false;
              _mechanicHasProfile = false;
              Navigator.of(context).pushNamedAndRemoveUntil('/role', (route) => false);
              return;
            }

            final role = authService.currentUserRole;
            if (role == 'user') {
              Navigator.of(context).pushNamedAndRemoveUntil(
                _userHasProfile ? '/user/home' : '/user/profile',
                (route) => false,
              );
            } else if (role == 'mechanic') {
              Navigator.of(context).pushNamedAndRemoveUntil(
                _mechanicHasProfile ? '/mechanic/home' : '/mechanic/profile',
                (route) => false,
              );
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil('/role', (route) => false);
            }
          });
        }

        // While navigation happens, render a minimal placeholder
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
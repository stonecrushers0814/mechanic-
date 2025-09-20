import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'role_selection_page.dart';
import 'user_home_page.dart';
import 'user_profile_form.dart';
import 'mechanic_home_page.dart';
import 'mechanic_profile_form.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  bool _checkingProfile = true;
  bool _userHasProfile = false;
  bool _mechanicHasProfile = false;

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
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoading || _checkingProfile) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (authService.currentUser == null) {
          return const RoleSelectionPage();
        }
        
        // User is logged in, check their role and redirect accordingly
        final role = authService.currentUserRole;
        if (role == 'user') {
          // For users, check if they have a profile
          if (_userHasProfile) {
            return const UserHomePage();
          } else {
            return UserProfileForm(isFirstTime: true);
          }
        } else if (role == 'mechanic') {
          // For mechanics, check if they have a profile
          if (_mechanicHasProfile) {
            return const MechanicHomePage();
          } else {
            return MechanicProfileForm(isFirstTime: true);
          }
        } else {
          // If role is not set, go to role selection
          return const RoleSelectionPage();
        }
      },
    );
  }
}
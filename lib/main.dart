import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import 'theme/app_theme.dart';
import 'map_sample.dart';
import 'role_selection_page.dart';
import 'user_home_page.dart';
import 'mechanic_home_page.dart';
import 'mechanic_profile_form.dart';
import 'user_profile_form.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MechanicOnDemand',
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const App(),
          '/role': (context) => const RoleSelectionPage(),
          '/user/home': (context) => const UserHomePage(),
          '/mechanic/home': (context) => const MechanicHomePage(),
          '/user/profile': (context) => UserProfileForm(isFirstTime: true),
          '/mechanic/profile': (context) => const MechanicProfileForm(isFirstTime: true),
          '/map': (context) => const MapSample(),
        },
      ),
    );
  }
  
}
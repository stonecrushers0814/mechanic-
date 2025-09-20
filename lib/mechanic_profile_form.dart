import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'models/mechanic_profile.dart';
import 'mechanic_home_page.dart'; // Add this import if not present

class MechanicProfileForm extends StatefulWidget {
  final bool isFirstTime;
  
  const MechanicProfileForm({super.key, this.isFirstTime = false});

  @override
  _MechanicProfileFormState createState() => _MechanicProfileFormState();
}

class _MechanicProfileFormState extends State<MechanicProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final supabase = Supabase.instance.client;
    
    try {
      final profileMap = await supabase
          .from('mechanic_profiles')
          .select()
          .eq('user_id', authService.currentUser!.id)
          .maybeSingle();

      if (profileMap != null) {
        final profile = MechanicProfile.fromMap(profileMap);
        setState(() {
          _nameController.text = profile.name;
          _phoneController.text = profile.phoneNumber;
          _emailController.text = profile.email;
          _locationController.text = profile.location;
        });
      } else {
        // Pre-fill with user email if available
        _emailController.text = authService.currentUser?.email ?? '';
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mechanic Profile'),
        automaticallyImplyLeading: !widget.isFirstTime,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isFirstTime 
                  ? 'Complete Your Profile to Continue'
                  : 'Update Your Profile',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.isFirstTime ? 'Complete Profile' : 'Update Profile',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final supabase = Supabase.instance.client;
        
        // Check if profile already exists
        final existingProfile = await supabase
            .from('mechanic_profiles')
            .select()
            .eq('user_id', authService.currentUser!.id)
            .maybeSingle();

        if (existingProfile != null) {
          // Update existing profile
          await supabase
              .from('mechanic_profiles')
              .update({
                'name': _nameController.text,
                'phone_number': _phoneController.text,
                'email': _emailController.text,
                'location': _locationController.text,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', authService.currentUser!.id);
        } else {
          // Create new profile
          await supabase
              .from('mechanic_profiles')
              .insert({
                'user_id': authService.currentUser!.id,
                'name': _nameController.text,
                'phone_number': _phoneController.text,
                'email': _emailController.text,
                'location': _locationController.text,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );

        if (widget.isFirstTime) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MechanicHomePage()),
            (route) => false,
          );
        } else {
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to save profile: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
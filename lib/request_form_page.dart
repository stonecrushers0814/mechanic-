import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'models/mechanic_list_item.dart';
import 'services/request_service.dart';

class RequestFormPage extends StatefulWidget {
  final List<MechanicListItem> selectedMechanics;

  const RequestFormPage({super.key, required this.selectedMechanics});

  @override
  _RequestFormPageState createState() => _RequestFormPageState();
}

class _RequestFormPageState extends State<RequestFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _issueController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

    final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    // You can integrate with geolocation services here
    // For now, we'll use a placeholder
    _locationController.text = 'Current Location (approximate)';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Service Request'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Selected Mechanics
              if (widget.selectedMechanics.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Mechanics:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...widget.selectedMechanics.map((mechanic) => ListTile(
                          leading: CircleAvatar(
                            child: Text(mechanic.name[0]),
                          ),
                          title: Text(mechanic.name),
                          subtitle: Text(mechanic.specialization),
                        )),
                    const Divider(),
                  ],
                ),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Your Location',
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
              const SizedBox(height: 16),

              // Detailed Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Detailed Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your detailed address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Vehicle Type
              TextFormField(
                controller: _vehicleTypeController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type (e.g., Car, Bike, Truck)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vehicle type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Vehicle Model
              TextFormField(
                controller: _vehicleModelController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Model (e.g., Honda Civic, Toyota Corolla)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vehicle model';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Issue Description
              TextFormField(
                controller: _issueController,
                decoration: const InputDecoration(
                  labelText: 'Issue Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please describe the issue';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Send Request to Mechanics'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final requestService = RequestService();
        final authService = Provider.of<AuthService>(context, listen: false);

        // Get user profile for contact info
        final userProfile = await _supabase
            .from('user_profiles')
            .select()
            .eq('user_id', authService.currentUser!.id)
            .single();

        // Create request
        final requestId = await requestService.createServiceRequest(
          userId: authService.currentUser!.id,
          userName: userProfile['name'] ?? 'User',
          userPhone: userProfile['phone_number'] ?? 'Not provided',
          userLocation: _locationController.text,
          userAddress: _addressController.text,
          issueDescription: _issueController.text,
          vehicleType: _vehicleTypeController.text,
          vehicleModel: _vehicleModelController.text,
          mechanicIds: widget.selectedMechanics.map((m) => m.userId).toList(),
        );

        // Create notifications for mechanics
        for (final mechanic in widget.selectedMechanics) {
          await requestService.createNotification(
            userId: mechanic.userId,
            title: 'New Service Request',
            message: 'You have a new service request from ${userProfile['name']}',
            type: 'request',
            relatedRequestId: requestId,
          );
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent successfully!')),
        );

        // Navigate back
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to send request: $e';
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
    _locationController.dispose();
    _addressController.dispose();
    _issueController.dispose();
    _vehicleTypeController.dispose();
    _vehicleModelController.dispose();
    super.dispose();
  }
}
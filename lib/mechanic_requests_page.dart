import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'models/request_model.dart';
import 'services/request_service.dart';

class MechanicRequestsPage extends StatefulWidget {
  const MechanicRequestsPage({super.key});

  @override
  _MechanicRequestsPageState createState() => _MechanicRequestsPageState();
}

class _MechanicRequestsPageState extends State<MechanicRequestsPage> {
  List<ServiceRequest> _requests = []; // Fixed: Properly declared
  bool _isLoading = true;
  final RequestService _requestService = RequestService();

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      final requests = await _requestService.getMechanicRequests(authService.currentUser!.id);
      setState(() {
        _requests = requests; // This should work now
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading requests: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptRequest(ServiceRequest request) async {
    try {
      await _requestService.updateRequestStatus(
        request.id, 
        'accepted',
        acceptedMechanicId: Provider.of<AuthService>(context, listen: false).currentUser!.id,
      );

      // Notify user
      await _requestService.createNotification(
        userId: request.userId,
        title: 'Request Accepted',
        message: 'Your service request has been accepted by a mechanic',
        type: 'acceptance',
        relatedRequestId: request.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request accepted! User has been notified.')),
      );

      _loadRequests(); // Refresh list
    } catch (e) {
      print('Error accepting request: $e');
    }
  }

  Future<void> _rejectRequest(ServiceRequest request) async {
    try {
      await _requestService.updateRequestStatus(request.id, 'rejected');
      _loadRequests(); // Refresh list
    } catch (e) {
      print('Error rejecting request: $e');
    }
  }

  Widget _buildRequestCard(ServiceRequest request) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request from ${request.userName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Phone: ${request.userPhone}'),
            Text('Location: ${request.userLocation}'),
            Text('Vehicle: ${request.vehicleType} ${request.vehicleModel}'),
            const SizedBox(height: 8),
            Text(
              'Issue: ${request.issueDescription}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            if (request.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptRequest(request),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectRequest(request),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              )
            else
              Text(
                'Status: ${request.status}',
                style: TextStyle(
                  color: request.status == 'accepted' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Requests'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('No service requests yet'))
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: ListView.builder(
                    itemCount: _requests.length,
                    itemBuilder: (context, index) => _buildRequestCard(_requests[index]),
                  ),
                ),
    );
  }
}
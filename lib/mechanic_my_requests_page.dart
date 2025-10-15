import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'theme/app_theme.dart';
import 'models/request_model.dart';

class MechanicMyRequestsPage extends StatefulWidget {
  const MechanicMyRequestsPage({super.key});

  @override
  State<MechanicMyRequestsPage> createState() => _MechanicMyRequestsPageState();
}

class _MechanicMyRequestsPageState extends State<MechanicMyRequestsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<ServiceRequest> _myRequests = [];
  Map<String, Map<String, dynamic>> _userProfiles = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedTab = 'all';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
    _loadMyRequests();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMyRequests() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final supabase = Supabase.instance.client;
      
      // Fetch service requests where the mechanic is involved
      final response = await supabase
          .from('service_requests')
          .select('*')
          .contains('mechanic_ids', [authService.currentUser!.id])
          .order('created_at', ascending: false);

      // Get user profiles separately
      final userIds = <String>{};
      for (var request in response) {
        if (request['user_id'] != null) {
          userIds.add(request['user_id'] as String);
        }
      }

      Map<String, Map<String, dynamic>> userProfiles = {};
      if (userIds.isNotEmpty) {
        final userProfilesResponse = await supabase
            .from('user_profiles')
            .select('*')
            .inFilter('user_id', userIds.toList());
        
        for (var profile in userProfilesResponse) {
          userProfiles[profile['user_id'] as String] = profile;
        }
      }

      setState(() {
        _myRequests = response
            .map<ServiceRequest>((data) => ServiceRequest.fromMap(data))
            .toList();
        _userProfiles = userProfiles;
        _isLoading = false;
      });
      
      // Debug information
      print('Loaded ${_myRequests.length} requests for mechanic');
      for (var request in _myRequests) {
        print('Request ${request.id}: ${request.status} - ${request.vehicleType}');
      }
    } catch (e) {
      setState(() {
        _myRequests = []; // Empty list on error
        _userProfiles = {};
        _errorMessage = 'Failed to load requests: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateRequestStatus(ServiceRequest request, String newStatus) async {
    try {
      final supabase = Supabase.instance.client;
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final updates = {
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // If starting work or completing, set the accepted mechanic
      if (newStatus == 'in_progress' || newStatus == 'completed') {
        updates['accepted_mechanic_id'] = authService.currentUser!.id;
      }

      await supabase
          .from('service_requests')
          .update(updates)
          .eq('id', request.id);

      // Create notification for user when service is completed
      if (newStatus == 'completed') {
        try {
          // Get mechanic details
          final mechanicData = await supabase
              .from('mechanic_profiles')
              .select('name')
              .eq('user_id', authService.currentUser!.id)
              .single();

          final mechanicName = mechanicData['name'] as String? ?? 'Your mechanic';
          final vehicleInfo = '${request.vehicleType} ${request.vehicleModel}';

          // Create notification for the user
          await supabase
              .from('notifications')
              .insert({
                'user_id': request.userId,
                'title': 'Service Completed!',
                'message': '$mechanicName has completed your service request for $vehicleInfo. Thank you for using our service!',
                'type': 'service_completed',
                'related_request_id': request.id,
                'created_at': DateTime.now().toIso8601String(),
              });
        } catch (notificationError) {
          print('Error creating completion notification: $notificationError');
          // Don't rethrow here to avoid breaking the main flow
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request status updated to $newStatus'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      _loadMyRequests(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update request status: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                slivers: [
                  // Custom App Bar
                  _buildSliverAppBar(context),
                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats Section
                          _buildStatsSection(context),
                          const SizedBox(height: 24),
                          // Tab Section
                          _buildTabSection(context),
                          const SizedBox(height: 24),
                          // Requests List
                          _buildRequestsList(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final inProgressCount = _myRequests.where((r) => r.status == 'in_progress').length;
    final pendingCount = _myRequests.where((r) => r.status == 'pending').length;

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.secondaryGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  // Back Button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'My Requests',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$inProgressCount in progress • $pendingCount pending',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final totalRequests = _myRequests.length;
    final completedRequests = _myRequests.where((r) => r.status == 'completed').length;
    final pendingRequests = _myRequests.where((r) => r.status == 'pending').length;
    final inProgressRequests = _myRequests.where((r) => r.status == 'in_progress').length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requests Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total',
                  totalRequests.toString(),
                  Icons.assignment,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Completed',
                  completedRequests.toString(),
                  Icons.check_circle,
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'In Progress',
                  inProgressRequests.toString(),
                  Icons.build,
                  AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Pending',
                  pendingRequests.toString(),
                  Icons.pending_actions,
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection(BuildContext context) {
    final completedCount = _myRequests.where((r) => r.status == 'completed').length;
    final pendingCount = _myRequests.where((r) => r.status == 'pending').length;
    final inProgressCount = _myRequests.where((r) => r.status == 'in_progress').length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              context,
              'All (${_myRequests.length})',
              _selectedTab == 'all',
              () => setState(() => _selectedTab = 'all'),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              context,
              'Pending ($pendingCount)',
              _selectedTab == 'pending',
              () => setState(() => _selectedTab = 'pending'),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              context,
              'In Progress ($inProgressCount)',
              _selectedTab == 'in_progress',
              () => setState(() => _selectedTab = 'in_progress'),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              context,
              'Completed ($completedCount)',
              _selectedTab == 'completed',
              () => setState(() => _selectedTab = 'completed'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildRequestsList(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Requests',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMyRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredRequests = _getFilteredRequests();

    if (filteredRequests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              color: AppTheme.textTertiary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No Requests Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyStateMessage(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getListTitle(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...filteredRequests.map((request) => _buildRequestCard(context, request)),
      ],
    );
  }

  List<ServiceRequest> _getFilteredRequests() {
    switch (_selectedTab) {
      case 'completed':
        return _myRequests.where((r) => r.status == 'completed').toList();
      case 'pending':
        return _myRequests.where((r) => r.status == 'pending').toList();
      case 'in_progress':
        return _myRequests.where((r) => r.status == 'in_progress').toList();
      default:
        return _myRequests;
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedTab) {
      case 'completed':
        return 'You haven\'t completed any requests yet.\nKeep up the great work!';
      case 'pending':
        return 'You don\'t have any pending requests.\nNew requests will appear here!';
      case 'in_progress':
        return 'You don\'t have any requests in progress.\nStart working on accepted requests!';
      default:
        return 'You don\'t have any requests at the moment.\nAccept service requests to start working!';
    }
  }

  String _getListTitle() {
    switch (_selectedTab) {
      case 'completed':
        return 'Completed Requests';
      case 'pending':
        return 'Pending Requests';
      case 'in_progress':
        return 'In Progress Requests';
      default:
        return 'All Requests';
    }
  }

  Widget _buildRequestCard(BuildContext context, ServiceRequest request) {
    final userProfile = _getUserProfile(request.userId);
    final userName = userProfile?['name'] ?? 'Unknown Customer';
    final userPhone = userProfile?['phone_number'] as String? ?? request.userPhone;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(request.status),
                  color: _getStatusColor(request.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.vehicleType,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      request.vehicleModel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.status.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(
                    color: _getStatusColor(request.status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            request.issueDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.person,
                color: AppTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Customer: $userName',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Icon(
                Icons.phone,
                color: AppTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                userPhone,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.userLocation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Icon(
                Icons.access_time,
                color: AppTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(request.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionButtons(context, request),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ServiceRequest request) {
    return Row(
      children: [
        if (request.status == 'pending') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateRequestStatus(request, 'in_progress'),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Start Work'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (request.status == 'in_progress') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showCompleteServiceDialog(context, request),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Complete Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showRequestDetails(context, request),
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCompleteServiceDialog(BuildContext context, ServiceRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Service'),
        content: const Text('Are you sure you want to mark this service as completed? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateRequestStatus(request, 'completed');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete Service'),
          ),
        ],
      ),
    );
  }

  void _showRequestDetails(BuildContext context, ServiceRequest request) {
    final userProfile = _getUserProfile(request.userId);
    final userName = userProfile?['name'] ?? 'Unknown Customer';
    final userPhone = userProfile?['phone_number'] as String? ?? request.userPhone;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request Details - ${request.vehicleType}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Customer', userName),
              _buildDetailRow('Phone', userPhone),
              _buildDetailRow('Vehicle', '${request.vehicleType} ${request.vehicleModel}'),
              _buildDetailRow('Location', request.userLocation),
              _buildDetailRow('Issue', request.issueDescription),
              _buildDetailRow('Status', request.status.toUpperCase().replaceAll('_', ' ')),
              _buildDetailRow('Created', _formatDate(request.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'in_progress':
        return AppTheme.primaryColor;
      case 'accepted':
        return AppTheme.accentColor;
      case 'rejected':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending_actions;
      case 'in_progress':
        return Icons.build;
      case 'accepted':
        return Icons.thumb_up;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Map<String, dynamic>? _getUserProfile(String userId) {
    return _userProfiles[userId];
  }
}


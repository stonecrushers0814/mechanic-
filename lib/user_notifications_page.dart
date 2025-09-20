import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'services/request_service.dart';

class UserNotificationsPage extends StatefulWidget {
  const UserNotificationsPage({super.key});

  @override
  _UserNotificationsPageState createState() => _UserNotificationsPageState();
}

class _UserNotificationsPageState extends State<UserNotificationsPage> {
  List<Map<String, dynamic>> _notifications = []; // Fixed: Properly declared
  bool _isLoading = true;
  final RequestService _requestService = RequestService();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      final notifications = await _requestService.getUserNotifications(authService.currentUser!.id);
      setState(() {
        _notifications = notifications; // This should work now
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _requestService.markNotificationAsRead(notificationId);
      _loadNotifications(); // Refresh list
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] ?? false;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: isRead ? Colors.grey[100] : Colors.blue[50],
      child: ListTile(
        leading: Icon(
          _getNotificationIcon(notification['type']),
          color: isRead ? Colors.grey : Colors.blue,
        ),
        title: Text(
          notification['title'] ?? 'Notification',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(notification['message'] ?? ''),
        trailing: !isRead
            ? IconButton(
                icon: const Icon(Icons.check, size: 20),
                onPressed: () => _markAsRead(notification['id']),
                tooltip: 'Mark as read',
              )
            : null,
        onTap: () => _markAsRead(notification['id']),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'acceptance':
        return Icons.check_circle;
      case 'request':
        return Icons.notifications;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) => _buildNotificationCard(_notifications[index]),
                ),
    );
  }
}
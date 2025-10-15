import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'theme/app_theme.dart';

class MechanicAnalyticsPage extends StatefulWidget {
  const MechanicAnalyticsPage({super.key});

  @override
  State<MechanicAnalyticsPage> createState() => _MechanicAnalyticsPageState();
}

class _MechanicAnalyticsPageState extends State<MechanicAnalyticsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _selectedPeriod = 'month';
  bool _isLoading = true;
  String? _errorMessage;

  // Mock analytics data
  Map<String, dynamic> _analytics = {};

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
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final supabase = Supabase.instance.client;
      
      // Load analytics data from the database
      final serviceRequests = await supabase
          .from('service_requests')
          .select('*')
          .eq('accepted_mechanic_id', authService.currentUser!.id);
      
      final ratings = await supabase
          .from('ratings')
          .select('*')
          .eq('mechanic_id', authService.currentUser!.id);
      
      final earnings = await supabase
          .from('earnings')
          .select('*')
          .eq('mechanic_id', authService.currentUser!.id);

      // Calculate analytics
      final totalServices = serviceRequests.length;
      final completedServices = serviceRequests.where((s) => s['status'] == 'completed').length;
      final pendingServices = serviceRequests.where((s) => s['status'] == 'pending').length;
      final rejectedServices = serviceRequests.where((s) => s['status'] == 'rejected').length;
      
      final averageRating = ratings.isNotEmpty 
          ? ratings.map((r) => r['rating'] as int).reduce((a, b) => a + b) / ratings.length
          : 0.0;
      
      final totalRatings = ratings.length;
      final fiveStarRatings = ratings.where((r) => r['rating'] == 5).length;
      final fourStarRatings = ratings.where((r) => r['rating'] == 4).length;
      final threeStarRatings = ratings.where((r) => r['rating'] == 3).length;
      final twoStarRatings = ratings.where((r) => r['rating'] == 2).length;
      final oneStarRatings = ratings.where((r) => r['rating'] == 1).length;
      
      final totalEarnings = earnings.fold(0.0, (sum, e) => sum + (e['amount'] as double));
      final thisMonthEarnings = earnings.where((e) {
        final date = DateTime.parse(e['created_at'] as String);
        final now = DateTime.now();
        return date.month == now.month && date.year == now.year;
      }).fold(0.0, (sum, e) => sum + (e['amount'] as double));

      _analytics = {
        'totalServices': totalServices,
        'completedServices': completedServices,
        'pendingServices': pendingServices,
        'rejectedServices': rejectedServices,
        'averageRating': averageRating,
        'totalRatings': totalRatings,
        'fiveStarRatings': fiveStarRatings,
        'fourStarRatings': fourStarRatings,
        'threeStarRatings': threeStarRatings,
        'twoStarRatings': twoStarRatings,
        'oneStarRatings': oneStarRatings,
        'totalEarnings': totalEarnings,
        'thisMonthEarnings': thisMonthEarnings,
        'completionRate': totalServices > 0 ? (completedServices / totalServices) * 100 : 0.0,
        'topServices': [],
        'weeklyData': [],
      };

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _analytics = {}; // Empty analytics on error
        _errorMessage = 'Failed to load analytics: $e';
        _isLoading = false;
      });
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
                          // Performance Overview
                          _buildPerformanceOverview(context),
                          const SizedBox(height: 24),
                          // Period Selector
                          _buildPeriodSelector(context),
                          const SizedBox(height: 24),
                          // Key Metrics
                          _buildKeyMetrics(context),
                          const SizedBox(height: 24),
                          // Rating Analysis
                          _buildRatingAnalysis(context),
                          const SizedBox(height: 24),
                          // Top Services
                          _buildTopServices(context),
                          const SizedBox(height: 24),
                          // Weekly Performance
                          _buildWeeklyPerformance(context),
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
    final averageRating = _analytics['averageRating'] ?? 0.0;
    final completionRate = _analytics['completionRate'] ?? 0.0;

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
                          'Analytics',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${averageRating.toStringAsFixed(1)}⭐ • ${completionRate.toStringAsFixed(1)}% completion',
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

  Widget _buildPerformanceOverview(BuildContext context) {
    final totalServices = _analytics['totalServices'] ?? 0;
    final completedServices = _analytics['completedServices'] ?? 0;
    final totalEarnings = _analytics['totalEarnings'] ?? 0.0;
    final averageRating = _analytics['averageRating'] ?? 0.0;

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
            'Performance Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Services',
                  totalServices.toString(),
                  completedServices.toString(),
                  Icons.build,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Earnings',
                  '\$${totalEarnings.toStringAsFixed(0)}',
                  'Total',
                  Icons.account_balance_wallet,
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Rating',
                  averageRating.toStringAsFixed(1),
                  '⭐ Average',
                  Icons.star,
                  AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Completion',
                  '${_analytics['completionRate']?.toStringAsFixed(1) ?? '0'}%',
                  'Rate',
                  Icons.check_circle,
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
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
            child: _buildPeriodButton(
              context,
              'Week',
              _selectedPeriod == 'week',
              () => setState(() => _selectedPeriod = 'week'),
            ),
          ),
          Expanded(
            child: _buildPeriodButton(
              context,
              'Month',
              _selectedPeriod == 'month',
              () => setState(() => _selectedPeriod = 'month'),
            ),
          ),
          Expanded(
            child: _buildPeriodButton(
              context,
              'Year',
              _selectedPeriod == 'year',
              () => setState(() => _selectedPeriod = 'year'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildKeyMetrics(BuildContext context) {
    final responseTime = _analytics['responseTime'] ?? 0.0;
    final averageServiceTime = _analytics['averageServiceTime'] ?? 0.0;
    final customerSatisfaction = _analytics['customerSatisfaction'] ?? 0.0;
    final repeatCustomers = _analytics['repeatCustomers'] ?? 0;

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
            'Key Metrics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Response Time',
                  '${responseTime.toStringAsFixed(0)} min',
                  Icons.schedule,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Service Time',
                  '${averageServiceTime.toStringAsFixed(1)} hrs',
                  Icons.timer,
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Satisfaction',
                  '${customerSatisfaction.toStringAsFixed(0)}%',
                  Icons.sentiment_satisfied,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Repeat Customers',
                  repeatCustomers.toString(),
                  Icons.repeat,
                  AppTheme.warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
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
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingAnalysis(BuildContext context) {
    final ratingData = [
      {'stars': 5, 'count': _analytics['fiveStarRatings'] ?? 0},
      {'stars': 4, 'count': _analytics['fourStarRatings'] ?? 0},
      {'stars': 3, 'count': _analytics['threeStarRatings'] ?? 0},
      {'stars': 2, 'count': _analytics['twoStarRatings'] ?? 0},
      {'stars': 1, 'count': _analytics['oneStarRatings'] ?? 0},
    ];

    final totalRatings = ratingData.fold<int>(0, (sum, rating) => sum + (rating['count'] as int));

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
            'Rating Breakdown',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...ratingData.map((rating) => _buildRatingBar(context, rating, totalRatings)),
        ],
      ),
    );
  }

  Widget _buildRatingBar(BuildContext context, Map<String, dynamic> rating, int totalRatings) {
    final stars = rating['stars'] as int;
    final count = rating['count'] as int;
    final percentage = totalRatings > 0 ? (count / totalRatings) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Row(
              children: [
                Text(
                  '$stars⭐',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppTheme.textTertiary.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getRatingColor(stars),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopServices(BuildContext context) {
    final topServices = _analytics['topServices'] as List<dynamic>? ?? [];

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
            'Top Services',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...topServices.map((service) => _buildServiceItem(context, service)),
        ],
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, Map<String, dynamic> service) {
    final name = service['name'] as String;
    final count = service['count'] as int;
    final revenue = service['revenue'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.build,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count services',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${revenue.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPerformance(BuildContext context) {
    final weeklyData = _analytics['weeklyData'] as List<dynamic>? ?? [];

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
            'Weekly Performance',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...weeklyData.map((week) => _buildWeekItem(context, week)),
        ],
      ),
    );
  }

  Widget _buildWeekItem(BuildContext context, Map<String, dynamic> week) {
    final weekName = week['week'] as String;
    final services = week['services'] as int;
    final earnings = week['earnings'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.successColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_today,
              color: AppTheme.successColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$services services completed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${earnings.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.successColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(int stars) {
    switch (stars) {
      case 5:
        return AppTheme.successColor;
      case 4:
        return AppTheme.primaryColor;
      case 3:
        return AppTheme.warningColor;
      case 2:
        return AppTheme.accentColor;
      case 1:
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }
}

// lib/screens/restaurant_dashboard.dart - FULL RESTAURANT MANAGEMENT
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'admin_orders_screen.dart';
import 'admin_menu_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'restaurant_form_screen.dart';
import 'login_screen.dart';

class RestaurantDashboard extends StatefulWidget {
  final User user;

  const RestaurantDashboard({super.key, required this.user});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _myRestaurant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    setState(() => _isLoading = true);
    final restaurant = await _apiService.getMyRestaurant();
    setState(() {
      _myRestaurant = restaurant;
      _isLoading = false;
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _authService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _createOrEditRestaurant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantFormScreen(
          restaurantId: _myRestaurant?['_id'],
          existingData: _myRestaurant,
        ),
      ),
    );

    if (result == true) {
      _loadRestaurant();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ NO RESTAURANT YET
    if (_myRestaurant == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.user.name} - Restaurant Owner'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant, size: 100, color: Colors.grey.shade300),
                const SizedBox(height: 24),
                const Text(
                  'No Restaurant Yet',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Create your restaurant to start managing menu and orders',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _createOrEditRestaurant,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Create Restaurant', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ HAS RESTAURANT - SHOW DASHBOARD
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _myRestaurant!['name'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Restaurant Owner',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _createOrEditRestaurant,
            tooltip: 'Edit Restaurant',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restaurant Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your restaurant analytics, menu, and orders',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // ✅ ANALYTICS
                  _buildDashboardCard(
                    icon: Icons.analytics,
                    title: 'Analytics',
                    subtitle: 'View your stats',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnalyticsDashboardScreen(),
                        ),
                      );
                    },
                  ),
                  // ✅ MANAGE MENU
                  _buildDashboardCard(
                    icon: Icons.restaurant_menu,
                    title: 'Manage Menu',
                    subtitle: 'Add, edit items',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminMenuScreen(),
                        ),
                      );
                    },
                  ),
                  // ✅ MANAGE ORDERS
                  _buildDashboardCard(
                    icon: Icons.shopping_bag,
                    title: 'Manage Orders',
                    subtitle: 'View & update orders',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminOrdersScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
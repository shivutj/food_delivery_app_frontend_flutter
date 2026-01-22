// lib/screens/admin_reviews_dashboard.dart - LIGHTWEIGHT ADMIN REVIEWS
import 'admin_reviews_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../services/auth_service.dart';


class AdminReviewsDashboard extends StatefulWidget {
  const AdminReviewsDashboard({super.key});

  @override
  State<AdminReviewsDashboard> createState() => _AdminReviewsDashboardState();
}

class _AdminReviewsDashboardState extends State<AdminReviewsDashboard>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late TabController _tabController;

  List<Map<String, dynamic>> _flaggedReviews = [];
  List<Map<String, dynamic>> _allReviews = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String _activeTab = 'flagged';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _activeTab = ['flagged', 'all', 'stats'][_tabController.index];
        });
      }
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    await Future.wait([
      _loadFlaggedReviews(),
      _loadAllReviews(),
      _loadStats(),
    ]);
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadFlaggedReviews() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/reviews/flagged'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _flaggedReviews =
              List<Map<String, dynamic>>.from(data['flagged_reviews']);
        });
      }
    } catch (e) {
      print('Load flagged reviews error: $e');
    }
  }

  Future<void> _loadAllReviews() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/reviews/all?limit=50'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _allReviews = List<Map<String, dynamic>>.from(data['reviews']);
        });
      }
    } catch (e) {
      print('Load all reviews error: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/reviews/stats/overview'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _stats = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print('Load stats error: $e');
    }
  }

  Future<void> _approveReview(String reviewId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/admin/reviews/$reviewId/approve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'notes': 'Approved by admin'}),
      );

      if (response.statusCode == 200) {
        _showMessage('Review approved', const Color(0xFF4CAF50));
        _loadData();
      }
    } catch (e) {
      _showMessage('Failed to approve', const Color(0xFFFF5252));
    }
  }

  Future<void> _hideReview(String reviewId) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hide Review'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Reason for hiding (min 10 characters)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
            ),
            child: const Text('Hide', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && reasonController.text.length >= 10) {
      try {
        final token = await _authService.getToken();
        final response = await http.patch(
          Uri.parse('${ApiConfig.baseUrl}/admin/reviews/$reviewId/hide'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'reason': reasonController.text}),
        );

        if (response.statusCode == 200) {
          _showMessage('Review hidden', const Color(0xFFFF9800));
          _loadData();
        }
      } catch (e) {
        _showMessage('Failed to hide', const Color(0xFFFF5252));
      }
    }
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Review Management',
          style: TextStyle(
            color: Color(0xFF212121),
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF212121)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF6B6B),
          unselectedLabelColor: const Color(0xFF9E9E9E),
          indicatorColor: const Color(0xFFFF6B6B),
          tabs: const [
            Tab(text: 'Flagged'),
            Tab(text: 'All Reviews'),
            Tab(text: 'Statistics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFlaggedTab(),
                _buildAllReviewsTab(),
                _buildStatsTab(),
              ],
            ),
    );
  }

  Widget _buildFlaggedTab() {
    if (_flaggedReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No flagged reviews',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _flaggedReviews.length,
      itemBuilder: (context, index) {
        return _buildReviewCard(_flaggedReviews[index], isFlagged: true);
      },
    );
  }

  Widget _buildAllReviewsTab() {
    if (_allReviews.isEmpty) {
      return Center(
        child: Text(
          'No reviews yet',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allReviews.length,
      itemBuilder: (context, index) {
        return _buildReviewCard(_allReviews[index]);
      },
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review,
      {bool isFlagged = false}) {
    final user = review['user_id'];
    final rating = review['rating']?.toDouble() ?? 0.0;
    final trustScore = review['trust_score'] ?? 0;
    final reportCount = review['report_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFlagged
              ? const Color(0xFFFF5252).withOpacity(0.3)
              : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE3F2FD),
                child: Text(
                  user['name'][0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          size: 14,
                          color: const Color(0xFFFFA000),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trustScore >= 70
                      ? const Color(0xFF4CAF50).withOpacity(0.1)
                      : const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: trustScore >= 70
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF9800),
                  ),
                ),
                child: Text(
                  'Trust: $trustScore',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: trustScore >= 70
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF9800),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            review['review_text'],
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF424242),
              height: 1.4,
            ),
          ),
          
          if (isFlagged) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF5252)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag, color: Color(0xFFFF5252), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Reported $reportCount times',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF5252),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _approveReview(review['_id']),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4CAF50),
                    side: const BorderSide(color: Color(0xFF4CAF50)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Approve', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _hideReview(review['_id']),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5252),
                    side: const BorderSide(color: Color(0xFFFF5252)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Hide', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_stats == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final reviews = _stats!['reviews'];
    final trust = _stats!['trust'];
    final reviewers = _stats!['reviewers'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(
          'Total Reviews',
          reviews['total'].toString(),
          Icons.rate_review,
          const Color(0xFF2196F3),
        ),
        _buildStatCard(
          'Active Reviews',
          reviews['active'].toString(),
          Icons.check_circle,
          const Color(0xFF4CAF50),
        ),
        _buildStatCard(
          'Flagged Reviews',
          reviews['flagged'].toString(),
          Icons.flag,
          const Color(0xFFFF9800),
        ),
        _buildStatCard(
          'Hidden Reviews',
          reviews['hidden'].toString(),
          Icons.visibility_off,
          const Color(0xFFFF5252),
        ),
        _buildStatCard(
          'Average Trust Score',
          trust['avg_trust_score'].toString(),
          Icons.security,
          const Color(0xFF9C27B0),
        ),
        _buildStatCard(
          'Total Reviewers',
          reviewers['total'].toString(),
          Icons.people,
          const Color(0xFF00BCD4),
        ),
        _buildStatCard(
          'Banned Reviewers',
          reviewers['banned'].toString(),
          Icons.block,
          const Color(0xFFE91E63),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
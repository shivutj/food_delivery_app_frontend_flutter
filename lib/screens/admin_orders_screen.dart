// lib/screens/admin_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final ApiService _apiService = ApiService();
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await _apiService.getAllOrders();
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    final result = await _apiService.updateOrderStatus(orderId, newStatus);
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order status updated')),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to update'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStatusDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order #${order.id.substring(order.id.length - 8)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Placed'),
              leading: Radio<String>(
                value: 'Placed',
                groupValue: order.status,
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateOrderStatus(order.id, value!);
                },
              ),
            ),
            ListTile(
              title: const Text('Preparing'),
              leading: Radio<String>(
                value: 'Preparing',
                groupValue: order.status,
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateOrderStatus(order.id, value!);
                },
              ),
            ),
            ListTile(
              title: const Text('Delivered'),
              leading: Radio<String>(
                value: 'Delivered',
                groupValue: order.status,
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateOrderStatus(order.id, value!);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Placed':
        return Colors.blue;
      case 'Preparing':
        return Colors.orange;
      case 'Delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Placed':
        return Icons.receipt;
      case 'Preparing':
        return Icons.restaurant;
      case 'Delivered':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('No orders yet'))
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    itemCount: _orders.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        child: ExpansionTile(
                          leading: Icon(
                            _getStatusIcon(order.status),
                            color: _getStatusColor(order.status),
                            size: 32,
                          ),
                          title: Text(
                            'Order #${order.id.substring(order.id.length - 8)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(order.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total: ₹${order.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(
                              order.status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: _getStatusColor(order.status),
                          ),
                          children: [
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Order Items:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...order.items.map((item) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${item.quantity}x ${item.name}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '₹${order.total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showStatusDialog(order),
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Update Status'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
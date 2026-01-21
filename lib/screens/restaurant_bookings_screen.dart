// lib/screens/restaurant_bookings_screen.dart - RESTAURANT OWNER VIEW
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/booking_service.dart';

class RestaurantBookingsScreen extends StatefulWidget {
  const RestaurantBookingsScreen({super.key});

  @override
  State<RestaurantBookingsScreen> createState() => _RestaurantBookingsScreenState();
}

class _RestaurantBookingsScreenState extends State<RestaurantBookingsScreen> {
  final BookingService _bookingService = BookingService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String _filter = 'All'; // All, Pending, Confirmed, Completed

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final bookings = await _bookingService.getRestaurantBookings();
    setState(() {
      _bookings = bookings;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredBookings {
    if (_filter == 'All') return _bookings;
    return _bookings.where((b) => b['status'] == _filter).toList();
  }

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await _bookingService.updateBookingStatus(bookingId, newStatus);
    
    Navigator.pop(context);

    if (success) {
      _showMessage('Booking status updated', Colors.green);
      await _loadBookings();
    } else {
      _showMessage('Failed to update status', Colors.red);
    }
  }

  Future<void> _callCustomer(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showMessage('Could not make call', Colors.red);
    }
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dine-In Bookings'),
        backgroundColor: Colors.orange.shade600,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Confirmed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed'),
                ],
              ),
            ),
          ),

          // Bookings List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBookings.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredBookings.length,
                          itemBuilder: (context, index) {
                            final booking = _filteredBookings[index];
                            return _buildBookingCard(booking);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filter = label);
      },
      selectedColor: Colors.orange.shade600,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_seat, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No ${_filter == 'All' ? '' : _filter.toLowerCase()} bookings',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final bookingDate = DateTime.parse(booking['booking_date']);
    final status = booking['status'];
    final user = booking['user_id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.event_seat,
            color: _getStatusColor(status),
            size: 28,
          ),
        ),
        title: Text(
          user['name'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(dateFormat.format(bookingDate)),
            Text('${booking['time_slot']} • ${booking['number_of_guests']} guests'),
          ],
        ),
        trailing: _buildStatusChip(status),
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Details
                _buildDetailRow(Icons.person, 'Customer', user['name']),
                _buildDetailRow(Icons.phone, 'Phone', user['phone']),
                _buildDetailRow(Icons.email, 'Email', user['email']),
                const Divider(height: 24),
                
                // Booking Details
                _buildDetailRow(Icons.calendar_today, 'Date', dateFormat.format(bookingDate)),
                _buildDetailRow(Icons.access_time, 'Time', booking['time_slot']),
                _buildDetailRow(Icons.people, 'Guests', '${booking['number_of_guests']}'),
                
                if (booking['special_requests']?.isNotEmpty ?? false) ...[
                  const Divider(height: 24),
                  const Text(
                    'Special Requests:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(booking['special_requests']),
                ],

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _callCustomer(user['phone']),
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatusButton(booking['_id'], status),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusButton(String bookingId, String currentStatus) {
    String? nextStatus;
    
    if (currentStatus == 'Pending') {
      nextStatus = 'Confirmed';
    } else if (currentStatus == 'Confirmed') {
      nextStatus = 'Completed';
    }

    if (nextStatus == null) return const SizedBox.shrink();

    return ElevatedButton(
      onPressed: () => _updateStatus(bookingId, nextStatus!),
      style: ElevatedButton.styleFrom(
        backgroundColor: _getStatusColor(nextStatus),
      ),
      child: Text(
        nextStatus,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade600;
      case 'Confirmed':
        return Colors.blue.shade600;
      case 'Completed':
        return Colors.green.shade600;
      case 'Cancelled':
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }
}
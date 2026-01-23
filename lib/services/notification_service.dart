// lib/services/notification_service.dart - NEW FILE
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final StreamController<int> _notificationController =
      StreamController<int>.broadcast();
  Stream<int> get notificationStream => _notificationController.stream;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  final List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  Future<void> initialize() async {
    await _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    _unreadCount = prefs.getInt('unread_notifications') ?? 0;
    _notificationController.add(_unreadCount);
  }

  Future<void> addNotification({
    required String title,
    required String message,
    String? orderId,
    String? restaurantName,
    int? coinsEarned,
  }) async {
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'message': message,
      'orderId': orderId,
      'restaurantName': restaurantName,
      'coinsEarned': coinsEarned,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
    };

    _notifications.insert(0, notification);
    _unreadCount++;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unread_notifications', _unreadCount);

    _notificationController.add(_unreadCount);
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n['id'] == notificationId);
    if (index != -1 && !_notifications[index]['read']) {
      _notifications[index]['read'] = true;
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('unread_notifications', _unreadCount);

      _notificationController.add(_unreadCount);
    }
  }

  Future<void> markAllAsRead() async {
    for (var notification in _notifications) {
      notification['read'] = true;
    }
    _unreadCount = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unread_notifications', 0);

    _notificationController.add(0);
  }

  Future<void> clearAll() async {
    _notifications.clear();
    _unreadCount = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unread_notifications', 0);

    _notificationController.add(0);
  }

  void dispose() {
    _notificationController.close();
  }
}

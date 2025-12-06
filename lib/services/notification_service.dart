import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../main.dart' show navigatorKey;
import '../screens/expiring.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static const String _notificationEnabledKey = 'notifications_enabled';
  static const String _notificationDaysKey = 'notification_days';

  // Initialize notification service
  Future<void> initialize(BuildContext context) async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Request permission
    await _requestPermission();

    // Initialize local notifications
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iOSInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iOSInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(context, response);
      },
    );
  }

  // Request notification permission
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  // Handle notification tap
  void _handleNotificationTap(BuildContext context, NotificationResponse response) {
    if (response.payload == 'expiring') {
      // Use global navigator key to ensure navigation works from any state
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const ExpiringItemsScreen(),
        ),
      );
    }
  }

  // Show local notification
  Future<void> _showNotification({
    required String title,
    required String body,
    String payload = 'expiring',
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'expiring_items_channel',
      'Expiring Items',
      channelDescription: 'Notifications for items expiring soon',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iOSNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Get notification preferences
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_notificationEnabledKey) ?? false,
      'days': prefs.getInt(_notificationDaysKey) ?? 3,
    };
  }

  // Save notification preferences
  Future<void> saveNotificationPreferences({
    required bool enabled,
    required int days,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, enabled);
    await prefs.setInt(_notificationDaysKey, days);

    // Save to Firestore for user
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'notificationEnabled': enabled,
        'notificationDays': days,
      }, SetOptions(merge: true));
    }
  }

  // Check expiring items and send notifications
  Future<void> checkExpiringItems({bool forceCheck = false}) async {
    final prefs = await getNotificationPreferences();
    
    // Check if notifications are enabled
    if (!prefs['enabled']) {
      debugPrint('🔕 Notifications are disabled');
      return;
    }

    final int daysThreshold = prefs['days'];
    debugPrint('📋 Checking for items expiring within $daysThreshold days');
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('❌ No user logged in');
      return;
    }

    try {
      final inventorySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .get();

      debugPrint('📦 Found ${inventorySnapshot.docs.length} items in inventory');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Check if we've already sent a notification today (skip this check if forceCheck is true)
      if (!forceCheck) {
        final lastNotificationDate = await _getLastNotificationDate();
        if (lastNotificationDate != null && 
            lastNotificationDate.year == today.year &&
            lastNotificationDate.month == today.month &&
            lastNotificationDate.day == today.day) {
          debugPrint('⏭️ Notification already sent today - skipping');
          return;
        }
      } else {
        debugPrint('🔄 Force check enabled - bypassing daily limit');
      }

      bool hasExpiringItems = false;
      int itemsInRange = 0;

      for (final doc in inventorySnapshot.docs) {
        final data = doc.data();
        final expiryDateStr = data['expiryDate'] as String?;
        final itemName = data['name'] as String? ?? 'Unknown';

        if (expiryDateStr == null || expiryDateStr.isEmpty) {
          debugPrint('⚠️ Item "$itemName" has no expiry date - skipping');
          continue;
        }

        try {
          final expiryDate = DateTime.parse(expiryDateStr);
          final expiryDay = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
          final difference = expiryDay.difference(today);
          final daysUntilExpiry = difference.inDays;

          debugPrint('📅 Item "$itemName" expires in $daysUntilExpiry days');

          // Check if item is within the threshold range (0 to daysThreshold days)
          if (daysUntilExpiry >= 0 && daysUntilExpiry <= daysThreshold) {
            hasExpiringItems = true;
            itemsInRange++;
            debugPrint('✅ Item "$itemName" is within expiry range!');
          }
        } catch (e) {
          debugPrint('❌ Error parsing date for "$itemName": $e');
        }
      }

      debugPrint('📊 Total items in expiry range: $itemsInRange');

      // Send one notification per day if any items are expiring within threshold
      if (hasExpiringItems) {
        await _showNotification(
          title: 'Items Expiring Soon',
          body: 'Your items are about to expire! Tap to check in.',
          payload: 'expiring',
        );
        
        // Save the notification date
        await _saveLastNotificationDate(today);
        debugPrint('🔔 Notification sent for expiring items');
      } else {
        debugPrint('✅ No items expiring within threshold');
      }
    } catch (e) {
      debugPrint('❌ Error checking expiring items: $e');
    }
  }

  // Get last notification date
  Future<DateTime?> _getLastNotificationDate() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_notification_date');
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  // Save last notification date
  Future<void> _saveLastNotificationDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_notification_date', date.millisecondsSinceEpoch);
  }

  // Schedule daily check for expiring items
  Future<void> scheduleDailyCheck() async {
    // Check immediately when app opens
    await checkExpiringItems();
  }
  
  // Method to be called when app comes to foreground
  Future<void> onAppResume() async {
    final prefs = await getNotificationPreferences();
    if (prefs['enabled']) {
      await checkExpiringItems();
    }
  }
}

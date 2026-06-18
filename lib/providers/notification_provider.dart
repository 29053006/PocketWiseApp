import 'dart:io';
import 'package:flutter/material.dart';
import 'package:myapp/data/database_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myapp/providers/language_provider.dart';

class NotificationItem {
  final String id;
  final String titleKey;
  final String messageKey;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.titleKey,
    required this.messageKey,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titleKey': titleKey,
      'messageKey': messageKey,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead ? 1 : 0,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'],
      titleKey: map['titleKey'],
      messageKey: map['messageKey'],
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] == 1,
    );
  }
}

class NotificationProvider with ChangeNotifier {
  final List<NotificationItem> _notifications = [];
  final DatabaseHelper _dbHelper;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final LanguageProvider _languageProvider;

  List<NotificationItem> get notifications => _notifications; // This is for in-app notifications
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider(this._flutterLocalNotificationsPlugin, this._languageProvider)
      : _dbHelper = DatabaseHelper() {
    _loadFromDb();
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  Future<void> _loadFromDb() async {
    final data = await _dbHelper.getNotifications();
    _notifications.clear();
    _notifications.addAll(data.map((m) => NotificationItem.fromMap(m)));
    notifyListeners();
  }

  Future<void> addNotification({required String titleKey, required String messageKey}) async {
    // Evitar duplicar la misma notificación en un corto periodo (ej. alerta de presupuesto)
    if (_notifications.any((n) => n.titleKey == titleKey && 
        n.timestamp.day == DateTime.now().day && 
        n.timestamp.month == DateTime.now().month &&
        n.timestamp.year == DateTime.now().year)) {
      return;
    }

    final newItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titleKey: titleKey,
      messageKey: messageKey,
      timestamp: DateTime.now(),
    );

    _notifications.insert(0, newItem);
    notifyListeners();
    
    await _dbHelper.insertNotification(newItem.toMap());

    // Programar la notificación local del sistema
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pocketwise_channel_id', // ID del canal
      'PocketWise Notifications', // Nombre del canal
      channelDescription: 'Notifications from PocketWise app', // Descripción del canal
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      int.parse(newItem.id.substring(newItem.id.length - 9)), // Usar parte del ID como int para la notificación
      _languageProvider.translate(titleKey), // El título traducido para la notificación del sistema
      _languageProvider.translate(messageKey), // El mensaje traducido para la notificación del sistema
      platformChannelSpecifics,
      payload: newItem.id, // Puedes pasar el ID de la notificación para manejarla al tocar
    );
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    await _dbHelper.markAllNotificationsRead();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    await _dbHelper.deleteNotification(id);
  }

  Future<void> clearNotifications() async {
    _notifications.clear();
    notifyListeners();
    await _dbHelper.deleteAllNotifications();
  }
}
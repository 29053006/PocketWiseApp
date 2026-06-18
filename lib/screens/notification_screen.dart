import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/notification_provider.dart';
import 'package:myapp/providers/language_provider.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('notifications')),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => notificationProvider.markAllAsRead(),
            tooltip: 'Mark all as read',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => notificationProvider.clearNotifications(),
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: notificationProvider.notifications.isEmpty
          ? Center(child: Text(lang.translate('no_notifications')))
          : ListView.builder(
              itemCount: notificationProvider.notifications.length,
              itemBuilder: (context, index) {
                final notif = notificationProvider.notifications[index];
                return Dismissible(
                  key: ValueKey(notif.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    notificationProvider.deleteNotification(notif.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(lang.translate('notification_deleted')),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: notif.isRead ? null : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                    child: ListTile(
                      leading: Icon(
                        notif.titleKey.contains('budget') ? Icons.warning_amber_rounded : Icons.notifications_active_outlined,
                        color: notif.isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        lang.translate(notif.titleKey),
                        style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lang.translate(notif.messageKey)),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.yMMMd().add_jm().format(notif.timestamp),
                            style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
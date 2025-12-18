import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/notification_provider.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import '../../../constants/app_sizes.dart';
import 'package:customer_app/src/features/auth/presentation/screens/login_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNotifications();
    });
  }

  void _fetchNotifications() {
     final authProvider = Provider.of<AuthProvider>(context, listen: false);
     if (authProvider.isAuthenticated) {
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
     }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text("Notifications")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               const Text("Please login to see notifications."),
               const SizedBox(height: AppSizes.p16),
               ElevatedButton(
                 onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                 child: const Text("Login"),
               )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.error != null && provider.notifications.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Text(provider.error!),
                   const SizedBox(height: AppSizes.p16),
                   ElevatedButton(onPressed: _fetchNotifications, child: const Text("Retry")),
                 ],
               ),
             );
          }

          if (provider.notifications.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            child: ListView.separated(
              itemCount: provider.notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return Dismissible(
                  key: Key(notification.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    provider.deleteNotification(notification.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Notification deleted")),
                    );
                  },
                  child: ListTile(
                    onTap: () {
                      if (!notification.isRead) {
                        provider.markAsRead(notification.id);
                      }
                    },
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.body),
                        const SizedBox(height: 4),
                        Text(
                          notification.createdAt.toLocal().toString().split('.')[0],
                           style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    leading: CircleAvatar(
                      backgroundColor: notification.isRead ? Colors.grey[300] : Theme.of(context).primaryColor.withOpacity(0.2),
                      child: Icon(Icons.notifications, color: notification.isRead ? Colors.grey : Theme.of(context).primaryColor),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                         provider.deleteNotification(notification.id);
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text("Notification deleted")),
                         );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

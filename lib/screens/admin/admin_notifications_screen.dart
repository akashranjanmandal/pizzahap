import 'package:flutter/material.dart';
import '../../config/app_config.dart';

// FCM has been removed. This screen is a stub that can be wired to a
// future notification delivery mechanism (e.g. in-app DB notifications).
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});
  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(AppColors.background),
    appBar: AppBar(title: const Text('Notifications')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🔔', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 20),
            const Text('Notifications',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 10),
            Text(
              'Push notification support via FCM has been removed.\n'
              'In-app notifications for orders are still delivered through the database.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}

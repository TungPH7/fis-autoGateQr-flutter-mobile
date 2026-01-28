import 'package:flutter/material.dart';
import '../../../shared/widgets/empty_state.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(
            onPressed: () {
              // Mark all as read
            },
            child: const Text('Đánh dấu đã đọc'),
          ),
        ],
      ),
      body: const EmptyState(
        icon: Icons.notifications_outlined,
        title: 'Chưa có thông báo',
        subtitle: 'Các thông báo về đăng ký sẽ hiển thị ở đây',
      ),
    );
  }
}
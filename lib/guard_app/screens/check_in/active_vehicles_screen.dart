import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/check_in_provider.dart';
import '../../../models/access_log_model.dart';
import '../../../core/theme/app_colors.dart';

/// Screen showing people currently inside (checked-in but not checked-out)
/// This replaces the legacy "active vehicles" screen
class ActiveVehiclesScreen extends StatelessWidget {
  const ActiveVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nguoi trong nha may'),
        backgroundColor: AppColors.guardPrimary,
      ),
      body: Consumer<CheckInProvider>(
        builder: (context, provider, _) {
          // Filter to only show people currently inside
          final currentlyInside = provider.todayLogs.where((log) {
            // Find if this person has checked out after this check-in
            if (!log.isCheckIn) return false;

            // Check if there's a later check-out for this user
            final hasCheckedOut = provider.todayLogs.any((l) =>
                l.userId == log.userId &&
                l.isCheckOut &&
                l.timestamp.isAfter(log.timestamp));

            return !hasCheckedOut;
          }).toList();

          if (currentlyInside.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Khong co ai trong nha may',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Nguoi da check-in se hien thi o day',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              provider.initialize();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: currentlyInside.length,
              itemBuilder: (context, index) {
                final log = currentlyInside[index];
                return _PersonInsideCard(log: log);
              },
            ),
          );
        },
      ),
    );
  }
}

class _PersonInsideCard extends StatelessWidget {
  final AccessLogModel log;

  const _PersonInsideCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final duration = DateTime.now().difference(log.timestamp).inMinutes;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.green.withValues(alpha: 0.1),
              backgroundImage:
                  log.userPhotoUrl != null ? NetworkImage(log.userPhotoUrl!) : null,
              child: log.userPhotoUrl == null
                  ? Text(
                      log.userName.isNotEmpty ? log.userName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vao luc ${log.timeDisplay}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    'Cong: ${log.gateName}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Trong NM',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes phut';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours gio';
    }
    return '$hours gio $mins phut';
  }
}

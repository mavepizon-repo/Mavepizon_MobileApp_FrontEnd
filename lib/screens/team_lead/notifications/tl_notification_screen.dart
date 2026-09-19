import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/tl_notification_service.dart';

class TlNotificationScreen extends ConsumerStatefulWidget {
  const TlNotificationScreen({super.key});

  @override
  ConsumerState<TlNotificationScreen> createState() =>
      _TlNotificationScreenState();
}

class _TlNotificationScreenState extends ConsumerState<TlNotificationScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await TlNotificationService.getAll();
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          _notifications = data;
        }
      } else {
        _error = result['message'] ?? 'Failed to load notifications';
      }
    } catch (e) {
      _error = 'Error: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markAsRead(String id) async {
    await TlNotificationService.markAsRead(id);
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? Center(child: Text(_error!))
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          Icon(Icons.notifications_none_rounded,
                              size: 80,
                              color: AppColors.textHi(context).withOpacity(0.3)),
                          const SizedBox(height: 20),
                          Text('No Notifications',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPri(context))),
                          const SizedBox(height: 8),
                          Text(
                              'You\'ll see notifications about leave and\npermission approvals here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppColors.textSec(context))),
                        ]),
                  )
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (_, i) {
                          final n = _notifications[i] as Map<String, dynamic>;
                          final read = n['isRead'] == true;
                          return Dismissible(
                            key: Key(n['id']?.toString() ?? '$i'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.done_all_rounded,
                                  color: Colors.white),
                            ),
                            onDismissed: (_) => _markAsRead(
                                n['id']?.toString() ?? ''),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: read ? Colors.white : AppColors.accent.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: !read
                                    ? Border.all(
                                        color: AppColors.accent.withOpacity(0.2))
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Row(children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: read
                                        ? AppColors.textHi(context)
                                        : AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            n['title']?.toString() ?? '',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: read
                                                    ? AppColors.textSec(context)
                                                    : AppColors.textPri(context))),
                                        const SizedBox(height: 4),
                                        Text(
                                            n['message']?.toString() ?? '',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textHi(context))),
                                      ]),
                                ),
                                if (!read)
                                  GestureDetector(
                                    onTap: () => _markAsRead(
                                        n['id']?.toString() ?? ''),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('Read',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.accent)),
                                    ),
                                  ),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

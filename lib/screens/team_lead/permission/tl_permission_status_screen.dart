import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/permission_service.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_widget.dart';
import '../../../widgets/status_badge.dart';

class TlPermissionStatusScreen extends ConsumerStatefulWidget {
  const TlPermissionStatusScreen({super.key});

  @override
  ConsumerState<TlPermissionStatusScreen> createState() =>
      _TlPermissionStatusScreenState();
}

class _TlPermissionStatusScreenState
    extends ConsumerState<TlPermissionStatusScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final res = await PermissionService.getMyPermissionHistory();
    if (!mounted) return;
    if (res['success'] == true) {
      final d = res['data'];
      if (d is List) {
        _list = d.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).cast<Map<String, dynamic>>().toList();
      } else if (d is Map && d['data'] is List) {
        _list = (d['data'] as List).map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).cast<Map<String, dynamic>>().toList();
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _list.where((item) {
      if (_statusFilter.isNotEmpty &&
          !(item['status'] ?? 'PENDING').toString().toUpperCase().contains(_statusFilter))
        return false;
      return true;
    }).toList();
    return Scaffold(
      
      body: Column(children: [
        Container(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 8, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28)),
          ),
          child: Row(children: [
            GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20))),
            const SizedBox(width: 14),
            const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Permission History',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text('Your permission requests',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                ]),
          ]),
        ),
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FChip(context, 'All', '', _statusFilter, (v) {
                setState(() => _statusFilter = v);
              }),
              _FChip(context, 'Pending', 'PENDING', _statusFilter, (v) {
                setState(() => _statusFilter = v);
              }),
              _FChip(context, 'Approved', 'APPROVED', _statusFilter, (v) {
                setState(() => _statusFilter = v);
              }),
              _FChip(context, 'Rejected', 'REJECTED', _statusFilter, (v) {
                setState(() => _statusFilter = v);
              }),
            ]),
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget(message: 'Loading permission history...')
              : filtered.isEmpty
                  ? const EmptyWidget(
                      message: 'No permission history found',
                      icon: Icons.timer_off_rounded)
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: AppColors.accent,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final item = filtered[i];
                          final date =
                              item['permissionDate']?.toString() ?? '';
                          final time = item['durationHours']?.toString() ?? '1';
                          final reason = item['reason']?.toString() ?? '';
                          final remarks = item['remarks']?.toString() ?? '';
                          final status =
                              item['status']?.toString() ?? 'PENDING';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Permission',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPri(context))),
                                        StatusBadge(
                                            status: status, fontSize: 10),
                                      ]),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Icon(Icons.calendar_today_rounded,
                                        size: 14, color: AppColors.textHi(context)),
                                    const SizedBox(width: 6),
                                    Text(date,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSec(context))),
                                    const SizedBox(width: 16),
                                    Icon(Icons.timer_rounded,
                                        size: 14, color: AppColors.textHi(context)),
                                    const SizedBox(width: 6),
                                    Text('$time hr',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSec(context))),
                                  ]),
                                  if (reason.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(reason,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textHi(context))),
                                  ],
                                  if (remarks.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(children: [
                                      const Icon(Icons.feedback_rounded,
                                          size: 14, color: Color(0xFFEF4444)),
                                      const SizedBox(width: 6),
                                      Text('Admin: ',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFFEF4444))),
                                    ]),
                                    const SizedBox(height: 2),
                                    Text(remarks,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFFEF4444))),
                                  ],
                                ]),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}

Widget _FChip(BuildContext context, String label, String value, String current, void Function(String) onSelected) {
  final selected = current == value;
  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: GestureDetector(
      onTap: () => onSelected(selected ? '' : value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSec(context))),
      ),
    ),
  );
}

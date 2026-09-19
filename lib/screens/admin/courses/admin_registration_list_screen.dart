import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/admin_course_management_service.dart';
import '../../../widgets/status_badge.dart';

class AdminRegistrationListScreen extends StatefulWidget {
  const AdminRegistrationListScreen({super.key});
  @override
  State<AdminRegistrationListScreen> createState() =>
      _AdminRegistrationListScreenState();
}

class _AdminRegistrationListScreenState
    extends State<AdminRegistrationListScreen> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _registrations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await AdminCourseManagementService.getAllRegistrations();
      if (result['success'] == true) {
        final data = result['data'];
        _registrations = data is List ? data : [];
      } else {
        _error = result['message'] ?? 'Failed to load';
      }
    } catch (e) {
      _error = 'Error: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Registration'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true) {
      await AdminCourseManagementService.deleteRegistration(id);
      _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    var filtered = _registrations.where((r) {
      final q = _searchCtrl.text.toLowerCase();
      if (q.isEmpty) return true;
      final student = r['student'] is Map ? r['student'] as Map : <String, dynamic>{};
      final course = r['course'] is Map ? r['course'] as Map : <String, dynamic>{};
      final studentName = (student['name'] ?? student['fullName'] ?? '').toString().toLowerCase();
      final courseName = (course['courseName'] ?? course['name'] ?? '').toString().toLowerCase();
      return studentName.contains(q) || courseName.contains(q);
    }).toList();

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Student Registrations'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by student or course...',
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.textHi(context)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); setState(() {}); })
                  : null,
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _error != null
                  ? Center(child: Text(_error!))
                  : filtered.isEmpty
                      ? Center(child: Text('No registrations found', style: TextStyle(color: AppColors.textHi(context))))
                      : RefreshIndicator(
                          onRefresh: _fetch,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final r = filtered[i];
                              final student = r['student'] is Map ? r['student'] as Map : <String, dynamic>{};
                              final course = r['course'] is Map ? r['course'] as Map : <String, dynamic>{};
                              final studentName = student['name'] ?? student['fullName'] ?? 'Unknown';
                              final courseName = course['courseName'] ?? course['name'] ?? 'Unknown';
                              final status =
                                  (r['paymentStatus'] ?? 'PAYMENT_PENDING')
                                      .toString()
                                      .toUpperCase();
                              final regStatus =
                                  (r['registrationStatus'] ?? '')
                                      .toString()
                                      .toUpperCase();
                              final regMode = r['mode']?.toString() ?? '';
                              final regLocation =
                                  r['location']?.toString() ?? '';
                              final regDate =
                                  r['registrationDate'] ??
                                      r['createdAt'] ??
                                      '';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(studentName,
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPri(context))),
                                    ),
                                    StatusBadge(status: status),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(courseName,
                                      style: TextStyle(fontSize: 12, color: AppColors.textSec(context))),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    if (regMode.isNotEmpty)
                                      _Chip(regMode, AppColors.accent),
                                    if (regLocation.isNotEmpty)
                                      _Chip(regLocation, AppColors.info),
                                    if (regStatus.isNotEmpty)
                                      _Chip(regStatus, AppColors.warning),
                                    const Spacer(),
                                    if (regDate.toString().length >= 10)
                                      Text(regDate.toString().substring(0, 10),
                                          style: TextStyle(fontSize: 11, color: AppColors.textHi(context))),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                                      onPressed: () => _delete(r['id']?.toString() ?? ''),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ]),
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

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

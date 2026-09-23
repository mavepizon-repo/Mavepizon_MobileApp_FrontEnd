import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/pagination_data.dart';
import '../../../services/admin_course_management_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/pagination_bar.dart';
import '../../../widgets/status_badge.dart';

class AdminOfferedCourseListScreen extends StatefulWidget {
  const AdminOfferedCourseListScreen({super.key});
  @override
  State<AdminOfferedCourseListScreen> createState() =>
      _AdminOfferedCourseListScreenState();
}

class _AdminOfferedCourseListScreenState
    extends State<AdminOfferedCourseListScreen> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _courses = [];
  PaginationData _paged = const PaginationData();
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

  Future<void> _fetch({int page = 0}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await AdminCourseManagementService.getAllOfferedCourses(
          page: page,
          size: 20,
      );
      if (result['success'] == true) {
        final data = result['data'];
        // /api/course/get-all returns a Spring Page; both categories are
        // present server-side, so keep only COURSE here per page.
        _paged = PaginationData.parse(data);
        _courses = _paged.content
            .where((e) =>
                e is Map &&
                (e['category']?.toString() ?? '').toUpperCase() == 'COURSE')
            .toList();
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
        title: const Text('Delete Offered Course'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true) {
      await AdminCourseManagementService.deleteOfferedCourse(id);
      _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    var filtered = _courses.where((c) {
      final q = _searchCtrl.text.toLowerCase();
      if (q.isEmpty) return true;
      final name = (c['courseName'] ?? c['name'] ?? '').toString().toLowerCase();
      final code = (c['courseCode'] ?? c['code'] ?? '').toString().toLowerCase();
      return name.contains(q) || code.contains(q);
    }).toList();

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Offered Courses'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () => Navigator.pushNamed(context, AppRoutes.adminOfferedCourseCreate).then((_) => _fetch()),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by name or code...',
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
                      ? Center(child: Text('No offered courses found', style: TextStyle(color: AppColors.textHi(context))))
                      : RefreshIndicator(
                          onRefresh: _fetch,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final c = filtered[i];
                              final name = c['courseName'] ?? c['name'] ?? '';
                              final code = c['courseCode'] ?? c['code'] ?? '';
                              final fees = c['fees'] ?? c['totalFees'] ?? 0;
                              final status = c['status'] ?? 'ACTIVE';
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
                                      child: Text('$name ($code)',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPri(context))),
                                    ),
                                    StatusBadge(status: status),
                                  ]),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    _InfoChip(Icons.currency_rupee_rounded, '₹$fees', AppColors.accent),
                                    const Spacer(),
                                    IconButton(
                                      icon: Icon(Icons.edit_rounded, color: AppColors.textHi(context), size: 20),
                                      onPressed: () => Navigator.pushNamed(context, AppRoutes.adminOfferedCourseEdit, arguments: {'id': c['id']?.toString() ?? ''}).then((_) => _fetch()),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                                      onPressed: () => _delete(c['id']?.toString() ?? ''),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ]),
                                ]),
                              );
                            },
                          ),
                        ),
        ),
        PaginationBar(
          data: _paged,
          isLoading: _loading,
          onPageChanged: (page) => _fetch(page: page),
        ),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

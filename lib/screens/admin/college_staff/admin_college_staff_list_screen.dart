import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/download/file_downloader.dart';
import '../../../models/college_staff_model.dart';
import '../../../providers/admin_college_staff_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/admin_student_service.dart';

class AdminCollegeStaffListScreen extends ConsumerStatefulWidget {
  const AdminCollegeStaffListScreen({super.key});
  @override
  ConsumerState<AdminCollegeStaffListScreen> createState() =>
      _AdminCollegeStaffListScreenState();
}

class _AdminCollegeStaffListScreenState
    extends ConsumerState<AdminCollegeStaffListScreen> {
  final _searchCtrl = TextEditingController();
  String _collegeFilter = '';
  String _deptFilter = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(adminCollegeStaffProvider.notifier).fetch());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _downloadCollegeStudents(CollegeStaffModel staff) async {
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(SnackBar(
      content: Text('Downloading students of ${staff.collegeName}...'),
      duration: const Duration(seconds: 5),
    ));

    try {
      final result = await AdminStudentService.getAll();
      if (result['success'] != true) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(
            content: Text(result['message']?.toString() ??
                'Failed to load students')));
        return;
      }
      final data = result['data'];
      if (data is! List) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
            const SnackBar(content: Text('No students data found')));
        return;
      }

      final rows = data.where((e) =>
          (e is Map && (e['collegeName']?.toString() ?? '')
                  .toLowerCase() ==
              staff.collegeName.toLowerCase()));
      if (rows.isEmpty) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(
            content: Text('No students found for ${staff.collegeName}')));
        return;
      }

      final buf = StringBuffer();
      buf.writeln(
          'Name,Email,Mobile,Department,Gender,College,StudentID');
      for (final e in rows) {
        final m = Map<String, dynamic>.from(e);
        final row = [
          m['name'] ?? '',
          m['email'] ?? '',
          m['mobileNumber'] ?? '',
          m['department'] ?? '',
          m['gender'] ?? '',
          m['collegeName'] ?? '',
          m['studentId'] ?? '',
        ].map((v) =>
            '"${(v ?? '').toString().replaceAll('"', '""')}"').join(',');
        buf.writeln(row);
      }

      final fileName =
          '${staff.collegeName}_students_${DateTime.now().millisecondsSinceEpoch}.csv';
      final savedPath = await downloadTextFile(
        fileName: fileName,
        content: buf.toString(),
        mimeType: 'text/csv',
      );

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text(savedPath.isNotEmpty
            ? 'Saved ${rows.length} students: $savedPath'
            : 'Downloaded ${rows.length} students'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(adminCollegeStaffProvider);
    final list = p.list;

    var filtered = list.where((s) {
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty && !s.name.toLowerCase().contains(q)) return false;
      if (_collegeFilter.isNotEmpty &&
          !s.collegeName
              .toLowerCase()
              .contains(_collegeFilter.toLowerCase()))
        return false;
      if (_deptFilter.isNotEmpty &&
          !s.department.toLowerCase().contains(_deptFilter.toLowerCase()))
        return false;
      return true;
    }).toList();

    final colleges =
        list.map((s) => s.collegeName).toSet().toList()..sort();
    final departments =
        list.map((s) => s.department).toSet().toList()..sort();

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('College Staff'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(
            context, AppRoutes.adminCollegeStaffCreate),
        backgroundColor: AppColors.accent,
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
              hintText: 'Search by name...',
              prefixIcon:
                  Icon(Icons.search_rounded, color: AppColors.textHi(context)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      })
                  : null,
            ),
          ),
        ),
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FilterChip(context, 'All Colleges', '', _collegeFilter, (v) {
                setState(() => _collegeFilter = v);
              }),
              ...colleges.map((c) => _FilterChip(context, c, c, _collegeFilter, (v) {
                    setState(() => _collegeFilter = v);
                  })),
              const SizedBox(width: 8),
              _FilterChip(context, 'All Departments', '', _deptFilter, (v) {
                setState(() => _deptFilter = v);
              }),
              ...departments.map(
                  (d) => _FilterChip(context, d, d, _deptFilter, (v) {
                        setState(() => _deptFilter = v);
                      })),
            ]),
          ),
        ),
        Expanded(
          child: p.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : p.error != null
                  ? Center(child: Text(p.error!))
                  : filtered.isEmpty
                      ? Center(
                          child: Text('No college staff found',
                              style: TextStyle(color: AppColors.textHi(context))))
                      : RefreshIndicator(
                          onRefresh: () => p.fetch(),
                          color: AppColors.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final s = filtered[i];
                              return GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.adminCollegeStaffDetail,
                                  arguments: {'id': s.id},
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                          color:
                                              Colors.black.withOpacity(0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: Row(children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          AppColors.card6.withOpacity(0.1),
                                      child: Text(
                                        s.name.isNotEmpty
                                            ? s.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.card6),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(s.name,
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.textPri(context))),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${s.collegeName} | ${s.department}',
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textHi(context)),
                                            ),
                                          ]),
                                    ),
                                    IconButton(
                                      tooltip: 'Download Students (Excel)',
                                      onPressed: () =>
                                          _downloadCollegeStudents(s),
                                      icon: Icon(Icons.download_rounded,
                                          size: 20, color: AppColors.accent),
                                      visualDensity:
                                          VisualDensity.compact,
                                    ),
                                  ]),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ]),
    );
  }
}

Widget _FilterChip(BuildContext context, String label, String value, String current,
    void Function(String) onSelected) {
  final selected = current == value;
  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: GestureDetector(
      onTap: () => onSelected(selected ? '' : value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSec(context))),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_student_provider.dart';
import '../../../routes/app_routes.dart';

class AdminStudentListScreen extends ConsumerStatefulWidget {
  const AdminStudentListScreen({super.key});
  @override
  ConsumerState<AdminStudentListScreen> createState() =>
      _AdminStudentListScreenState();
}

class _AdminStudentListScreenState extends ConsumerState<AdminStudentListScreen> {
  final _searchCtrl = TextEditingController();
  String _collegeFilter = '';
  String _deptFilter = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminStudentProvider.notifier).fetchAll());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _colleges {
    final all = ref.read(adminStudentProvider).students;
    return all.map((s) => s.collegeName).where((c) => c.isNotEmpty).toSet().toList()..sort();
  }

  List<String> get _departments {
    final all = ref.read(adminStudentProvider).students;
    return all.map((s) => s.department).where((d) => d.isNotEmpty).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(adminStudentProvider);
    final students = p.students;

    var filtered = students.where((s) {
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty &&
          !s.fullName.toLowerCase().contains(q) &&
          !s.email.toLowerCase().contains(q) &&
          !s.studentId.toLowerCase().contains(q))
        return false;
      if (_collegeFilter.isNotEmpty &&
          !s.collegeName.toLowerCase().contains(_collegeFilter.toLowerCase()))
        return false;
      if (_deptFilter.isNotEmpty &&
          !s.department.toLowerCase().contains(_deptFilter.toLowerCase()))
        return false;
      return true;
    }).toList();

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Student Management'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        // Search
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by name, email, or student ID...',
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
        // Filters
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FilterChip(context, 'All Colleges', '', _collegeFilter, (v) {
                setState(() => _collegeFilter = v);
              }),
              ..._colleges.take(10).map((c) =>
                  _FilterChip(context, c.length > 15 ? '${c.substring(0, 15)}..' : c,
                      c, _collegeFilter, (v) {
                    setState(() => _collegeFilter = v);
                  })),
              const SizedBox(width: 8),
              _FilterChip(context, 'All Depts', '', _deptFilter, (v) {
                setState(() => _deptFilter = v);
              }),
              ..._departments.take(10).map((d) =>
                  _FilterChip(context, d, d, _deptFilter, (v) {
                    setState(() => _deptFilter = v);
                  })),
            ]),
          ),
        ),
        // Count
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('${filtered.length} students',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textHi(context))),
        ),
        // List
        Expanded(
          child: p.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : p.error != null
                  ? Center(child: Text(p.error!))
                  : filtered.isEmpty
                      ? Center(
                          child: Text('No students found',
                              style:
                                  TextStyle(color: AppColors.textHi(context))))
                      : RefreshIndicator(
                          onRefresh: () => p.fetchAll(),
                          color: AppColors.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final s = filtered[i];
                              return GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.adminStudentDetail,
                                    arguments: {'id': s.id}),
                                child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppColors.card5
                                              .withOpacity(0.1),
                                          child: Text(
                                            s.fullName.isNotEmpty
                                                ? s.fullName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.card5),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(s.fullName,
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            AppColors.textPri(context))),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${s.studentId} | ${s.collegeName}',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppColors.textHi(context)),
                                                ),
                                              ]),
                                        ),
                                      ]),
                                      const SizedBox(height: 6),
                                      Row(children: [
                                        Icon(Icons.school_rounded,
                                            size: 14,
                                            color: AppColors.textHi(context)),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            s.department.isNotEmpty
                                                ? s.department
                                                : 'N/A',
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors
                                                    .textSecondary),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.email_rounded,
                                            size: 14,
                                            color: AppColors.textHi(context)),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(s.email,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors
                                                      .textSecondary)),
                                        ),
                                      ]),
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

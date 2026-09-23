import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_student_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/pagination_bar.dart';

class AdminStudentListScreen extends ConsumerStatefulWidget {
  const AdminStudentListScreen({super.key});
  @override
  ConsumerState<AdminStudentListScreen> createState() =>
      _AdminStudentListScreenState();
}

class _AdminStudentListScreenState extends ConsumerState<AdminStudentListScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminStudentProvider.notifier).fetchAll());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    final prov = ref.read(adminStudentProvider.notifier);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      prov.setSearchQuery(value);
      prov.fetchAll(search: value.trim());
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchCtrl.clear();
    final prov = ref.read(adminStudentProvider.notifier);
    prov.setSearchQuery('');
    prov.fetchAll();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(adminStudentProvider);
    final students = p.students;

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
            onChanged: _onSearchChanged,
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
                      onPressed: _clearSearch)
                  : null,
            ),
          ),
        ),
        // Count
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('${p.totalElements} students',
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
                  : students.isEmpty
                      ? Center(
                          child: Text('No students found',
                              style:
                                  TextStyle(color: AppColors.textHi(context))))
                      : RefreshIndicator(
                          onRefresh: () => p.refresh(),
                          color: AppColors.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: students.length,
                            itemBuilder: (_, i) {
                              final s = students[i];
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
        PaginationBar(
          data: p.pagination,
          isLoading: p.isLoading,
          onPageChanged: (page) => ref
              .read(adminStudentProvider.notifier)
              .fetchAll(page: page, search: p.searchQuery),
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

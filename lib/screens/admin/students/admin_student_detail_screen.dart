import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_student_provider.dart';

class AdminStudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;
  const AdminStudentDetailScreen({super.key, required this.studentId});
  @override
  ConsumerState<AdminStudentDetailScreen> createState() =>
      _AdminStudentDetailScreenState();
}

class _AdminStudentDetailScreenState
    extends ConsumerState<AdminStudentDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(adminStudentProvider.notifier).fetchById(widget.studentId));
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(adminStudentProvider);
    final s = p.selected;

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Student Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: p.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : p.error != null
              ? Center(child: Text(p.error!))
              : s == null
                  ? const Center(child: Text('Not found'))
                  : ListView(padding: const EdgeInsets.all(16), children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.accent.withOpacity(0.1),
                              child: Text(
                              s.fullName.isNotEmpty
                                  ? s.fullName[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(s.fullName,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPri(context))),
                          const SizedBox(height: 4),
                          Text(s.email,
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textHi(context))),
                        ]),
                      ),
                      const SizedBox(height: 12),

                      _Section(title: 'Student Info', children: [
                        _Row(label: 'Student ID', value: s.studentId),
                        _Row(label: 'Phone', value: s.phone),
                        _Row(label: 'College', value: s.collegeName),
                        _Row(label: 'Department', value: s.department),
                        _Row(label: 'Registration Date',
                            value: s.registrationDate),
                      ]),
                      const SizedBox(height: 20),
                    ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context))),
            const SizedBox(height: 12),
            ...children,
          ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textHi(context))),
            ),
            Expanded(
              child: Text(value.isNotEmpty ? value : '-',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPri(context))),
            ),
          ]),
    );
  }
}

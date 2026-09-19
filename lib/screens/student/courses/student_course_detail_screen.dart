import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/student_course_provider.dart';
import '../../../routes/app_routes.dart';

class StudentCourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;
  const StudentCourseDetailScreen({super.key, required this.courseId});
  @override
  ConsumerState<StudentCourseDetailScreen> createState() =>
      _StudentCourseDetailScreenState();
}

class _StudentCourseDetailScreenState
    extends ConsumerState<StudentCourseDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(studentCourseProvider.notifier)
          .fetchCourseDetail(widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cp = ref.watch(studentCourseProvider);
    final c = cp.selectedCourse;

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
            c?['courseName']?.toString() ?? 'Course Detail',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
      ),
      body: cp.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 2))
          : c == null
              ? const Center(child: Text('Course not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ]),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(c['courseName']?.toString() ?? '',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPri(context))),
                        const SizedBox(height: 12),
                        _Row('Duration',
                            c['duration']?.toString() ?? 'N/A'),
                        const SizedBox(height: 8),
                        _Row('Registration Fee',
                            '₹${c['registrationFees']?.toString() ?? '0'}'),
                        const SizedBox(height: 8),
                        _Row('Course Fee',
                            '₹${c['totalFees']?.toString() ?? '0'}'),
                        const SizedBox(height: 8),
                        _Row('Available Seats (Online)',
                            '${c['availableSeatsOnline'] ?? 0}/${c['totalSeatsOnline'] ?? 0}'),
                        const SizedBox(height: 8),
                        _Row('Available Seats (Offline)',
                            '${c['availableSeatsOffline'] ?? 0}/${c['totalSeatsOffline'] ?? 0}'),
                        if ((c['availableSeatsTirunelveli'] ?? 0) > 0 || (c['totalSeatsTirunelveli'] ?? 0) > 0) ...[
                          const SizedBox(height: 8),
                          _Row('Available Seats (Tirunelveli)',
                              '${c['availableSeatsTirunelveli'] ?? 0}/${c['totalSeatsTirunelveli'] ?? 0}'),
                        ],
                        if ((c['availableSeatsTisaiyanvilai'] ?? 0) > 0 || (c['totalSeatsTisaiyanvilai'] ?? 0) > 0) ...[
                          const SizedBox(height: 8),
                          _Row('Available Seats (Tisaiyanvilai)',
                              '${c['availableSeatsTisaiyanvilai'] ?? 0}/${c['totalSeatsTisaiyanvilai'] ?? 0}'),
                        ],
                        if (c['description']?.toString().isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 16),
                          Text('Description',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPri(context))),
                          const SizedBox(height: 6),
                          Text(
                              c['description']?.toString() ?? '',
                              style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppColors.textSec(context))),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.studentCourseRegister,
                            arguments: {
                              'courseId': widget.courseId,
                              'courseName':
                                  c['courseName']?.toString() ?? ''
                            }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Register for Course',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Text(label,
            style: TextStyle(
                fontSize: 13, color: AppColors.textSec(context))),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPri(context))),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/student_course_provider.dart';
import '../../../routes/app_routes.dart';

class StudentMyCoursesScreen extends ConsumerStatefulWidget {
  const StudentMyCoursesScreen({super.key});
  @override
  ConsumerState<StudentMyCoursesScreen> createState() =>
      _StudentMyCoursesScreenState();
}

class _StudentMyCoursesScreenState
    extends ConsumerState<StudentMyCoursesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentCourseProvider.notifier).fetchMyCourses();
    });
  }

  String _courseName(dynamic r) {
    final course = r['course'];
    if (course is Map) {
      return course['courseName']?.toString() ?? 'Course';
    }
    return r['courseName']?.toString() ?? 'Course';
  }

  // PATCH /api/student-course/update/{registrationId}
  // Mode/location can be changed ONLY before payment.
  Future<void> _editMode(dynamic r) async {
    final currentMode = r['mode']?.toString() ?? 'ONLINE';
    final currentLocation = r['location']?.toString() ?? 'TIRUNELVELI';
    String mode = currentMode.toUpperCase() == 'OFFLINE' ? 'OFFLINE' : 'ONLINE';
    String location = currentLocation.toUpperCase() == 'TISAIYANVILAI'
        ? 'TISAIYANVILAI'
        : 'TIRUNELVELI';

    final changed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Mode / Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: mode,
                decoration: const InputDecoration(labelText: 'Mode'),
                items: const [
                  DropdownMenuItem(value: 'ONLINE', child: Text('Online')),
                  DropdownMenuItem(value: 'OFFLINE', child: Text('Offline')),
                ],
                onChanged: (v) => setDialogState(() => mode = v ?? 'ONLINE'),
              ),
              if (mode == 'OFFLINE') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: location,
                  decoration: const InputDecoration(labelText: 'Location'),
                  items: const [
                    DropdownMenuItem(
                        value: 'TIRUNELVELI', child: Text('Tirunelveli')),
                    DropdownMenuItem(
                        value: 'TISAIYANVILAI', child: Text('Tisaiyanvilai')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => location = v ?? 'TIRUNELVELI'),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Mode/location can be changed only before payment.',
                style: TextStyle(fontSize: 11, color: AppColors.textHi(context)),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );

    if (changed != true) return;

    final ok = await ref.read(studentCourseProvider.notifier).updateRegistrationMode(
          r['id'].toString(),
          {
            'mode': mode,
            if (mode == 'OFFLINE') 'location': location,
          },
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Registration updated successfully'
          : ref.read(studentCourseProvider).error ?? 'Update failed'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cp = ref.watch(studentCourseProvider);

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('My Courses',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(studentCourseProvider.notifier).fetchMyCourses(),
        child: cp.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2))
            : cp.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_rounded,
                              size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(
                            cp.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref
                                .read(studentCourseProvider.notifier)
                                .fetchMyCourses(),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : cp.myCourses.isEmpty
                ? Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book_rounded,
                              size: 60,
                              color: AppColors.textHi(context).withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text('No registered courses',
                              style: TextStyle(color: AppColors.textHi(context))),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.studentCourseList),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent),
                            child: const Text('Browse Courses'),
                          ),
                        ]))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cp.myCourses.length,
                    itemBuilder: (ctx, i) {
                      final r = cp.myCourses[i];
                      final regStatus =
                          (r['registrationStatus'] ?? 'PENDING_PAYMENT')
                              .toString()
                              .toUpperCase();
                      final paymentStatus =
                          (r['paymentStatus'] ?? 'PENDING')
                              .toString()
                              .toUpperCase();
                      final isConfirmed = regStatus == 'CONFIRMED' ||
                          paymentStatus == 'PAID' ||
                          paymentStatus == 'COMPLETED' ||
                          paymentStatus == 'SUCCESS';
                      final fee = r['registrationFeeAmount'];
                      final mode = r['mode']?.toString() ?? '';
                      final location = r['location']?.toString();
                      final regId = r['id'] ?? r['registrationId'];
                      return Container(
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
                                  offset: const Offset(0, 2))
                            ]),
                        child: Column(children: [
                          Row(children: [
                          Container(
                            width: 3,
                            height: 36,
                            decoration: BoxDecoration(
                                color: AppColors.card1,
                                borderRadius:
                                    BorderRadius.circular(3)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      _courseName(r),
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              AppColors.textPri(context))),
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      'Reg: $regStatus',
                                      if (mode.isNotEmpty) mode,
                                      if (location != null &&
                                          location.isNotEmpty)
                                        location,
                                    ].join(' · '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            AppColors.textSec(context)),
                                  ),
                                  if (fee != null)
                                    Text(
                                        'Registration Fee: ₹$fee',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.accent)),
                                ]),
                          ),
                          Icon(
                              isConfirmed
                                  ? Icons.check_circle_rounded
                                  : Icons.pending_rounded,
                              color: isConfirmed
                                  ? AppColors.success
                                  : AppColors.warning,
                              size: 20),
                          ]),
                          if (!isConfirmed) ...[
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _editMode(r),
                                  icon: const Icon(Icons.edit_rounded,
                                      size: 16),
                                  label: const Text('Edit Mode'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        AppColors.textSec(context),
                                    side: BorderSide(
                                        color: AppColors.borderC(context)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.studentOnlinePayment,
                                      arguments: {
                                        'registrationId': regId is int
                                            ? regId
                                            : int.tryParse(
                                                regId.toString()),
                                        'itemName': _courseName(r),
                                        'amount': fee,
                                      },
                                    ).then((_) => ref
                                        .read(studentCourseProvider
                                            .notifier)
                                        .fetchMyCourses());
                                  },
                                  icon: const Icon(
                                      Icons.payments_rounded,
                                      size: 16),
                                  label: const Text('Make Payment'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ]),
                          ],
                        ]),
                      );
                    },
                  ),
      ),
    );
  }
}
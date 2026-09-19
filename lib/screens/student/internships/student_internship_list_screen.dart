import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/student_internship_provider.dart';
import '../../../routes/app_routes.dart';

class StudentInternshipListScreen extends ConsumerStatefulWidget {
  const StudentInternshipListScreen({super.key});
  @override
  ConsumerState<StudentInternshipListScreen> createState() =>
      _StudentInternshipListScreenState();
}

class _StudentInternshipListScreenState
    extends ConsumerState<StudentInternshipListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentInternshipProvider.notifier).fetchAvailableInternships();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ip = ref.watch(studentInternshipProvider);

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Internships',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.badge_rounded,
                color: AppColors.textSec(context)),
            onPressed: () => Navigator.pushNamed(
                context, AppRoutes.studentMyInternships),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(studentInternshipProvider.notifier)
            .fetchAvailableInternships(),
        child: ip.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2))
            : ip.internships.isEmpty
                ? Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.work_rounded,
                              size: 60,
                              color: AppColors.textHi(context).withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text('No internships available',
                              style: TextStyle(color: AppColors.textHi(context))),
                        ]))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ip.internships.length,
                    itemBuilder: (ctx, i) {
                      final intern = ip.internships[i];
                      return GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.studentInternshipDetail,
                              arguments: {
                                'internshipId': intern['id']?.toString() ?? ''
                              }),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ]),
                          child: Row(children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.card2.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                  child: Icon(Icons.work_rounded,
                                      color: AppColors.card2, size: 24)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        intern['courseName']?.toString() ??
                                            intern['internshipName']?.toString() ??
                                            'Internship',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                                FontWeight.w600,
                                            color:
                                                AppColors.textPri(context))),
                                    const SizedBox(height: 4),
                                    Text(
                                        '${intern['duration']?.toString() ?? ''}  •  ₹${intern['registrationFees']?.toString() ?? '0'}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors
                                                .textSecondary)),
                                    const SizedBox(height: 4),
                                    Text(
                                        'Seats: ${intern['availableSeatsOnline'] ?? 0} online / ${intern['availableSeatsTirunelveli'] ?? 0} TV / ${intern['availableSeatsTisaiyanvilai'] ?? 0} TY',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.accent)),
                                  ]),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: AppColors.textHi(context)),
                          ]),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

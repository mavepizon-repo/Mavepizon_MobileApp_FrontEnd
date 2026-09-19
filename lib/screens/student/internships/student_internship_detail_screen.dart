import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/student_internship_provider.dart';
import '../../../routes/app_routes.dart';

class StudentInternshipDetailScreen extends ConsumerStatefulWidget {
  final String internshipId;
  const StudentInternshipDetailScreen(
      {super.key, required this.internshipId});
  @override
  ConsumerState<StudentInternshipDetailScreen> createState() =>
      _StudentInternshipDetailScreenState();
}

class _StudentInternshipDetailScreenState
    extends ConsumerState<StudentInternshipDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(studentInternshipProvider.notifier)
          .fetchInternshipDetail(widget.internshipId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ip = ref.watch(studentInternshipProvider);
    final intern = ip.selectedInternship;

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
            intern?['courseName']?.toString() ??
                intern?['internshipName']?.toString() ??
                'Internship Detail',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
      ),
      body: ip.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 2))
          : intern == null
              ? const Center(child: Text('Internship not found'))
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
                                color: Colors.black
                                    .withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ]),
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                        Text(
                            intern['courseName']?.toString() ??
                                intern['internshipName']?.toString() ??
                                '',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPri(context))),
                        const SizedBox(height: 8),
                        Text(
                            intern['createdBy']?.toString() ??
                                intern['trainerName']?.toString() ??
                                '',
                            style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        _Row('Duration',
                            intern['duration']?.toString() ?? 'N/A'),
                        const SizedBox(height: 8),
                        _Row('Registration Fee',
                            '₹${intern['registrationFees']?.toString() ?? '0'}'),
                        const SizedBox(height: 8),
                        _Row('Fees',
                            '₹${intern['totalFees']?.toString() ?? intern['fees']?.toString() ?? '0'}'),
                        const SizedBox(height: 8),
                        _Row('Available Seats (Online)',
                            '${intern['availableSeatsOnline'] ?? 0}/${intern['totalSeatsOnline'] ?? 0}'),
                        const SizedBox(height: 8),
                        _Row('Available Seats (Offline)',
                            '${intern['availableSeatsOffline'] ?? 0}/${intern['totalSeatsOffline'] ?? 0}'),
                        if ((intern['availableSeatsTirunelveli'] ?? 0) > 0 ||
                            (intern['totalSeatsTirunelveli'] ?? 0) > 0) ...[
                          const SizedBox(height: 8),
                          _Row('Available Seats (Tirunelveli)',
                              '${intern['availableSeatsTirunelveli'] ?? 0}/${intern['totalSeatsTirunelveli'] ?? 0}'),
                        ],
                        if ((intern['availableSeatsTisaiyanvilai'] ?? 0) > 0 ||
                            (intern['totalSeatsTisaiyanvilai'] ?? 0) > 0) ...[
                          const SizedBox(height: 8),
                          _Row('Available Seats (Tisaiyanvilai)',
                              '${intern['availableSeatsTisaiyanvilai'] ?? 0}/${intern['totalSeatsTisaiyanvilai'] ?? 0}'),
                        ],
                        if (intern['description']
                                ?.toString()
                                .isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 16),
                          Text('Description',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPri(context))),
                          const SizedBox(height: 6),
                          Text(
                              intern['description']?.toString() ??
                                  '',
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
                            context, AppRoutes.studentInternshipApply,
                            arguments: {
                              'internshipId': widget.internshipId,
                              'internshipCode':
                                  intern['courseCode']?.toString() ??
                                      intern['internshipCode']?.toString() ??
                                      '',
                              'internshipName':
                                  intern['courseName']?.toString() ??
                                      intern['internshipName']?.toString() ??
                                      '',
                            }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Apply Now',
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/student_internship_provider.dart';
import '../../../routes/app_routes.dart';

class StudentMyInternshipsScreen extends ConsumerStatefulWidget {
  const StudentMyInternshipsScreen({super.key});
  @override
  ConsumerState<StudentMyInternshipsScreen> createState() =>
      _StudentMyInternshipsScreenState();
}

class _StudentMyInternshipsScreenState
    extends ConsumerState<StudentMyInternshipsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentInternshipProvider.notifier).fetchMyInternships();
    });
  }

  String _internshipName(dynamic r) {
    final course = r['course'];
    if (course is Map) {
      return course['courseName']?.toString() ?? 'Internship';
    }
    return r['courseName']?.toString() ??
        r['internshipName']?.toString() ??
        'Internship';
  }

  @override
  Widget build(BuildContext context) {
    final ip = ref.watch(studentInternshipProvider);

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('My Internships',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(studentInternshipProvider.notifier).fetchMyInternships(),
        child: ip.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2))
            : ip.error != null
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
                            ip.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref
                                .read(studentInternshipProvider.notifier)
                                .fetchMyInternships(),
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
                : ip.myInternships.isEmpty
                ? Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.badge_rounded,
                              size: 60,
                              color: AppColors.textHi(context).withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text('No internships applied',
                              style: TextStyle(color: AppColors.textHi(context))),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.studentInternshipList),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent),
                            child: const Text('Browse Internships'),
                          ),
                        ]))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ip.myInternships.length,
                    itemBuilder: (ctx, i) {
                      final r = ip.myInternships[i];
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
                                color: AppColors.card2,
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
                                      _internshipName(r),
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
                            SizedBox(
                              width: double.infinity,
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
                                      'itemName': _internshipName(r),
                                      'amount': fee,
                                    },
                                  ).then((_) => ref
                                      .read(studentInternshipProvider
                                          .notifier)
                                      .fetchMyInternships());
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
                          ],
                        ]),
                      );
                    },
                  ),
      ),
    );
  }
}
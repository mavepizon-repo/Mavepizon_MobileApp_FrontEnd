import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/string_utils.dart';
import '../../../providers/student_certificate_provider.dart';
import '../../../routes/app_routes.dart';

class StudentCertificateScreen extends ConsumerStatefulWidget {
  const StudentCertificateScreen({super.key});
  @override
  ConsumerState<StudentCertificateScreen> createState() =>
      _StudentCertificateScreenState();
}

class _StudentCertificateScreenState
    extends ConsumerState<StudentCertificateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentCertificateProvider.notifier).fetchMyCertificates();
    });
  }

  void _openPreview(Map<String, dynamic> cert) {
    Navigator.of(context).pushNamed(
      AppRoutes.studentCertificatePreview,
      arguments: {'certificate': cert},
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = ref.watch(studentCertificateProvider);

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Certificates',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(studentCertificateProvider.notifier).fetchMyCertificates(),
        child: cp.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2))
            : cp.certificates.isEmpty
                ? Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 60,
                              color: AppColors.textHi(context).withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text('No certificates yet',
                              style: TextStyle(color: AppColors.textHi(context))),
                        ]))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cp.certificates.length,
                    itemBuilder: (ctx, i) {
                      final cert = cp.certificates[i];
                      final certMap = cert is Map<String, dynamic>
                          ? cert
                          : Map<String, dynamic>.from(
                              cert as Map);
                      return GestureDetector(
                        onTap: () => _openPreview(certMap),
                        child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ]),
                        child: Row(children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.card4.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: const Center(
                                child: Icon(Icons.verified_rounded,
                                    color: AppColors.card4,
                                    size: 24)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      cert['courseName']
                                              ?.toString() ??
                                          cert['certificateName']
                                                  ?.toString() ??
                                          'Certificate',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.w600,
                                          color:
                                              AppColors.textPri(context))),
                                  const SizedBox(height: 4),
                                   Text(
                                        truncate(
                                            cert['issueDate']?.toString(), 10),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors
                                              .textSecondary)),
                                ]),
                          ),
                          GestureDetector(
                            onTap: () => _openPreview(certMap),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accent
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.visibility_rounded,
                                        size: 14,
                                        color: AppColors.accent),
                                    SizedBox(width: 4),
                                    Text('View',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.accent)),
                                  ]),
                            ),
                          ),
                        ]),
                      ),
                    );
                    },
                  ),
      ),
    );
  }
}

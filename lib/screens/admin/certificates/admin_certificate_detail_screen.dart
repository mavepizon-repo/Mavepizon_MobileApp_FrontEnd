import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/file_opener.dart';
import '../../../core/utils/string_utils.dart';
import '../../../models/certificate_model.dart';
import '../../../widgets/status_badge.dart';

class AdminCertificateDetailScreen extends ConsumerStatefulWidget {
  final CertificateModel certificate;
  const AdminCertificateDetailScreen(
      {super.key, required this.certificate});
  @override
  ConsumerState<AdminCertificateDetailScreen> createState() =>
      _AdminCertificateDetailScreenState();
}

class _AdminCertificateDetailScreenState
    extends ConsumerState<AdminCertificateDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final cert = widget.certificate;

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Certificate Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _DetailSection(title: 'Student Info', children: [
          _DetailRow(label: 'Student Name', value: cert.studentName),
          _DetailRow(label: 'College', value: cert.collegeName.isNotEmpty ? cert.collegeName : '-'),
          _DetailRow(label: 'Status', valueWidget: StatusBadge(status: cert.status)),
        ]),
        const SizedBox(height: 12),
        _DetailSection(title: 'Program Details', children: [
          _DetailRow(label: 'Program', value: cert.courseOrInternshipName),
          _DetailRow(label: 'Type', value: cert.type),
          if (cert.batchCode != null)
            _DetailRow(label: 'Batch Code', value: cert.batchCode!),
        ]),
        const SizedBox(height: 12),
        _DetailSection(title: 'Dates', children: [
          _DetailRow(label: 'Registration Date', value: truncate(cert.registrationDate, 10)),
          if (cert.updatedAt != null)
            _DetailRow(label: 'Updated At', value: truncate(cert.updatedAt, 10)),
        ]),
        const SizedBox(height: 12),
        if (cert.fileUrl != null && cert.fileUrl!.isNotEmpty) ...[
          _DetailSection(title: 'Certificate File', children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(children: [
                Expanded(
                  child: Text(cert.fileUrl!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.accent),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.download_rounded,
                      color: AppColors.accent),
                  onPressed: () =>
                      openFileInApp(context, cert.fileUrl, title: 'Certificate'),
                  tooltip: 'View Certificate',
                ),
              ]),
            ),
          ]),
        ] else ...[
          _DetailSection(title: 'Certificate File', children: [
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('No file uploaded yet',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textHi(context))),
            ),
          ]),
        ],
        const SizedBox(height: 20),
      ]),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _DetailSection({required this.title, required this.children});

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

class _DetailRow extends StatelessWidget {
  final String label, value;
  final Widget? valueWidget;
  const _DetailRow(
      {required this.label, this.value = '', this.valueWidget});

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
              child: valueWidget ??
                  Text(value.isNotEmpty ? value : '-',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPri(context))),
            ),
          ]),
    );
  }
}

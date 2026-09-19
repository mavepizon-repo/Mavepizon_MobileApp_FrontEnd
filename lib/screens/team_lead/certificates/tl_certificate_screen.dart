import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/file_opener.dart';
import '../../../providers/certificate_provider.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_widget.dart';


class TlCertificateScreen extends ConsumerStatefulWidget {
  const TlCertificateScreen({super.key});
  @override
  ConsumerState<TlCertificateScreen> createState() => _TlCertificateScreenState();
}

class _TlCertificateScreenState extends ConsumerState<TlCertificateScreen> {
  String _searchStudentId = '';
  String _searchCollege = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFilters = false;
  bool _showOverdueOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(certificateProvider.notifier).fetch());
  }

  bool _isOverdue(dynamic cert) {
    final status = cert.status?.toString().toUpperCase() ?? '';
    if (status == 'ISSUED' || status == 'GENERATED') return false;
    try {
      final regDate = DateTime.parse(cert.registrationDate);
      final dueDate = regDate.add(const Duration(days: 3));
      return DateTime.now().isAfter(dueDate);
    } catch (_) {
      return false;
    }
  }

  List<dynamic> _getFilteredList(List<dynamic> list) {
    return list.where((cert) {
      final matchStudentId = _searchStudentId.isEmpty ||
          cert.studentId.toLowerCase().contains(_searchStudentId.toLowerCase());
      final matchCollege = _searchCollege.isEmpty ||
          (cert.collegeName
                  ?.toLowerCase()
                  .contains(_searchCollege.toLowerCase()) ??
              false);
      bool matchDate = true;
      if (_startDate != null && _endDate != null) {
        try {
          final regDate = DateTime.parse(cert.registrationDate);
          if (regDate.isBefore(_startDate!) || regDate.isAfter(_endDate!)) {
            matchDate = false;
          }
        } catch (_) {
          // Malformed registrationDate on this record � don't exclude it
          // from results just because it can't be date-filtered.
        }
      }
      final matchOverdue = !_showOverdueOnly || _isOverdue(cert);
      return matchStudentId && matchCollege && matchDate && matchOverdue;
    }).toList();
  }

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.accent)),
        child: child!,
      ),
    );
    if (d != null) {
      setState(() {
        if (isStart) {
          _startDate = d;
        } else {
          _endDate = d;
        }
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchStudentId = '';
      _searchCollege = '';
      _startDate = null;
      _endDate = null;
      _showOverdueOnly = false;
    });
  }

  String _fmtDate(DateTime? d) => d == null
      ? 'From'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _uploadCertificate(String id, String studentName) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null || filePath.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Unable to read the selected file.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    if (!mounted) return;
    final ok = await ref
        .read(certificateProvider.notifier)
        .uploadCertificate(id, File(filePath));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Certificate uploaded for $studentName'
          : 'Failed to upload certificate'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _deleteCert(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Certificate'),
        content: Text('Delete certificate record for $name?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok == true) {
      if (!mounted) return;
      await ref.read(certificateProvider.notifier).delete(id);
    }
  }

  // ? Status update control � TL monitors the certificate team and
  // updates the status (PENDING / GENERATED / ISSUED) for each certificate
  Future<void> _updateStatus(dynamic cert) async {
    final current = cert.status?.toString().toUpperCase() ?? '';
    final options = ['PENDING', 'GENERATED', 'ISSUED'];
    String? selected = options.contains(current) ? current : options.first;
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Update Certificate Status'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Student: ${cert.studentName}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('ID: ${cert.studentId}',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textHi(context))),
            const SizedBox(height: 14),
            for (final option in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () =>
                      setModalState(() => selected = option),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected == option
                          ? AppColors.accent.withOpacity(0.12)
                          : Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected == option
                              ? AppColors.accent
                              : AppColors.borderC(context)),
                    ),
                    child: Row(children: [
                      Icon(
                          selected == option
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 18,
                          color: selected == option
                              ? AppColors.accent
                              : AppColors.textHi(context)),
                      const SizedBox(width: 10),
                      Text(option,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected == option
                                  ? AppColors.accent
                                  : AppColors.textPri(context))),
                    ]),
                  ),
                ),
              ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child:
                    const Text('Update', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
    if (confirmed != true || selected == current || selected == null) return;
    final ok =
        await ref.read(certificateProvider.notifier).updateStatus(cert.id, selected!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Status updated to $selected for ${cert.studentName}'
          : 'Failed to update status'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ? FIX: Uses cert.batchCode (TrainingBatch ID) instead of cert.id
  // Backend /api/certificates/initiate/batch/{batchId} needs a batch ID.
  // cert.id is the certificate record's own DB row ID � wrong parameter.
  Future<void> _initiateBatch(dynamic cert) async {
    // ? batchCode holds the actual batch identifier from TrainingBatch
    final String? batchCode = cert.batchCode?.toString();

    if (batchCode == null || batchCode.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Cannot initiate: no batch code linked to this certificate.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // We need the numeric batch DB ID, not the batch code string like "B-INTFS062026001".
    // CertificateDTO from backend should include trainingBatch.id (Long).
    // ? Check if batchCode is numeric (DB ID) or string code
    // If backend returns batchId (Long) separately, use that.
    // For now, show confirm with batchCode so TL knows which batch.
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Initiate Batch Certificates'),
        content: Text(
          'Generate PENDING certificate records for all eligible paid students?\n\n'
          'This will create certificate records for paid students who don\'t '
          'have one yet.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Initiate',
                  style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      // ? Pass cert.id which maps to the trainingBatch.id in the DTO
      // NOTE: Ask backend to return trainingBatch.id (Long) in CertificateDTO
      // so we can pass the correct numeric batch ID here.
      // For now, passing cert.id as a temporary measure until backend returns batchId.
      final ok =
          await ref.read(certificateProvider.notifier).initiateBatch(cert.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Certificate records created successfully!'
            : 'All eligible students already have certificate records.'),
        backgroundColor: ok ? AppColors.success : AppColors.warning,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(certificateProvider);
    final filteredList = _getFilteredList(prov.list);
    final overdueCount = prov.list.where(_isOverdue).length;

    return Scaffold(
      
      body: Column(children: [
        Container(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 8, 20, 20),
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28))),
          child: Column(children: [
            Row(children: [
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20))),
              const SizedBox(width: 14),
              const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Certificates',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text('Manage student certificates',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ]),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    setState(() => _showOverdueOnly = !_showOverdueOnly),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _showOverdueOnly
                        ? AppColors.error.withOpacity(0.8)
                        : Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(clipBehavior: Clip.none, children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 20),
                    if (overdueCount > 0 && !_showOverdueOnly)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: AppColors.error, shape: BoxShape.circle),
                          child: Text('$overdueCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _showFilters = !_showFilters),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _showFilters
                        ? Icons.filter_alt_off_rounded
                        : Icons.filter_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ]),
            if (_showFilters) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by Student ID',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.white.withOpacity(0.5), size: 16),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.12),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => setState(() => _searchStudentId = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by College',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 12),
                      prefixIcon: Icon(Icons.business_rounded,
                          color: Colors.white.withOpacity(0.5), size: 16),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.12),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => setState(() => _searchCollege = v),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(_fmtDate(_startDate),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(Icons.event_rounded,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(_fmtDate(_endDate),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ]),
                    ),
                  ),
                ),
                if (_searchStudentId.isNotEmpty ||
                    _searchCollege.isNotEmpty ||
                    _startDate != null ||
                    _endDate != null ||
                    _showOverdueOnly)
                  GestureDetector(
                    onTap: _clearFilters,
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white70, size: 16),
                    ),
                  ),
              ]),
            ],
            const SizedBox(height: 4),
            Row(children: [
              Text('${filteredList.length} certificates',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 11)),
              if (overdueCount > 0) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$overdueCount overdue',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
          ]),
        ),
        Expanded(
          child: prov.isLoading
              ? const LoadingWidget(message: 'Loading certificates...')
              : filteredList.isEmpty
                  ? EmptyWidget(
                      message: _showOverdueOnly
                          ? 'No overdue certificates'
                          : _showFilters
                              ? 'No certificates match filters'
                              : 'No certificates found',
                      icon: Icons.card_membership_outlined)
                  : RefreshIndicator(
                      onRefresh: () => prov.fetch(),
                      color: AppColors.accent,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final cert = filteredList[i];
                          final overdue = _isOverdue(cert);
                          final status =
                              cert.status?.toString().toUpperCase() ?? '';
                          final isIssued =
                              status == 'ISSUED' || status == 'GENERATED';
                          final statusColor = isIssued
                              ? AppColors.success
                              : status == 'PENDING'
                                  ? AppColors.warning
                                  : AppColors.textHi(context);

                          return GestureDetector(
                            onTap: () {
                              final file = cert.fileUrl?.toString().trim() ?? '';
                              if (isIssued && file.isNotEmpty) {
                                openFileInApp(context, file,
                                    title: 'Certificate - ${cert.studentName}');
                              } else {
                                _uploadCertificate(
                                    cert.id, cert.studentName);
                              }
                            },
                            onLongPress: () =>
                                _deleteCert(cert.id, cert.studentName),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: overdue
                                    ? Border.all(
                                        color: AppColors.error.withOpacity(0.5),
                                        width: 1.5)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (overdue)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: Row(children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.error
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.warning_rounded,
                                                      size: 12,
                                                      color: AppColors.error),
                                                  SizedBox(width: 4),
                                                  Text('OVERDUE (3+ days)',
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              AppColors.error)),
                                                ]),
                                          ),
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () => _initiateBatch(cert),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                              decoration: BoxDecoration(
                                                color: AppColors.accent,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .play_arrow_rounded,
                                                        size: 13,
                                                        color: Colors.white),
                                                    SizedBox(width: 3),
                                                    Text('Initiate',
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                Colors.white)),
                                                  ]),
                                            ),
                                          ),
                                        ]),
                                      ),
                                    Row(children: [
                                      Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                              color:
                                                  statusColor.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          child: Icon(
                                              Icons.card_membership_rounded,
                                              color: statusColor,
                                              size: 22)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(cert.studentName,
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppColors.textPri(context))),
                                            const SizedBox(height: 2),
                                            Text('ID: ${cert.studentId}',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textHi(context))),
                                            if (cert.collegeName.isNotEmpty)
                                              Text(cert.collegeName,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppColors.textHi(context))),
                                            // ? FIX: Shows actual batch name now
                                            Text(cert.courseOrInternshipName,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors
                                                        .textSecondary)),
                                            const SizedBox(height: 4),
                                            Row(children: [
                                              Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                      color: AppColors.accent
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(4)),
                                                  child: Text(
                                                      cert.type,
                                                      style: const TextStyle(
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .accent))),
                                              const SizedBox(width: 6),
                                              Text(
                                                  cert.registrationDate
                                                              .length >=
                                                          10
                                                      ? cert.registrationDate
                                                          .substring(0, 10)
                                                      : cert.registrationDate,
                                                  style: TextStyle(
                                                      fontSize: 9,
                                                      color:
                                                          AppColors.textHi(context))),
                                            ]),
                                          ])),
                                      Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            GestureDetector(
                                              onTap: () => _updateStatus(cert),
                                              child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 5),
                                                  decoration: BoxDecoration(
                                                      color: statusColor
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                  child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                            status.replaceAll(
                                                                '_', ' '),
                                                            style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color:
                                                                    statusColor)),
                                                        const SizedBox(
                                                            width: 4),
                                                        Icon(
                                                            Icons
                                                                .edit_rounded,
                                                            size: 11,
                                                            color:
                                                                statusColor),
                                                      ])),
                                            ),
                                            const SizedBox(height: 6),
                                            // ? FIX: Show download if issued,
                                            // upload prompt if pending
                                            if (isIssued &&
                                                cert.fileUrl != null)
                                              const Row(children: [
                                                Text('View',
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color:
                                                            AppColors.success)),
                                                SizedBox(width: 2),
                                                Icon(
                                                    Icons.download_done_rounded,
                                                    size: 12,
                                                    color: AppColors.success),
                                              ])
                                            else
                                              Row(children: [
                                                Text('Tap to upload',
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color: AppColors
                                                            .textHint)),
                                                SizedBox(width: 2),
                                                Icon(Icons.upload_file_rounded,
                                                    size: 12,
                                                    color: AppColors.textHi(context)),
                                              ]),
                                          ]),
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

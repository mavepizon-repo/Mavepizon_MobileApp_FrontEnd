import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/student_internship_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/student_internship_service.dart';

class StudentInternshipApplyScreen extends ConsumerStatefulWidget {
  final String internshipId;
  final String title;
  final String internshipCode;
  const StudentInternshipApplyScreen({
    super.key,
    required this.internshipId,
    required this.title,
    this.internshipCode = '',
  });
  @override
  ConsumerState<StudentInternshipApplyScreen> createState() =>
      _StudentInternshipApplyScreenState();
}

class _StudentInternshipApplyScreenState
    extends ConsumerState<StudentInternshipApplyScreen> {
  bool _submitting = false;
  String _mode = 'ONLINE';
  String _location = 'TIRUNELVELI';
  String? _alreadyMsg;

  @override
  void initState() {
    super.initState();
    _checkAlreadyRegistered();
  }

  Future<void> _checkAlreadyRegistered() async {
    try {
      final result = await StudentInternshipService.getMyInternships();
      if (result['success'] != true) return;
      final data = result['data'];
      if (data is! List) return;
      for (final r in data) {
        if (r is! Map) continue;
        final course = r['course'];
        final cid = course is Map ? course['id'] : null;
        if (cid?.toString() == widget.internshipId) {
          final paid = (r['paymentStatus'] ?? '').toString().toUpperCase() ==
              'PAID';
          _alreadyMsg = paid
              ? 'You have already registered and paid for this internship.'
              : 'You have already registered for this internship. Complete the payment to confirm your seat.';
          break;
        }
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _apply() async {
    if (_alreadyMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_alreadyMsg!),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _submitting = true);

    final result = await ref
        .read(studentInternshipProvider.notifier)
        .applyForInternship({
      'courseId': int.tryParse(widget.internshipId) ?? widget.internshipId,
      'mode': _mode,
      if (_mode == 'OFFLINE') 'location': _location,
    });
    setState(() => _submitting = false);

    if (!mounted) return;

    if (result == null) {
      final err = ref.read(studentInternshipProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Application failed'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final registrationId = result['registrationId'];
    final fee = result['registrationFee'];

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Registration created. Complete payment to confirm.'),
        backgroundColor: AppColors.success,
      ),
    );

    if (registrationId != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.studentOnlinePayment,
        arguments: {
          'registrationId': registrationId is int
              ? registrationId
              : int.tryParse(registrationId.toString()),
          'itemName': result['internshipName']?.toString() ?? widget.title,
          'amount': fee,
        },
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Apply for Internship',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ]),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Icon(Icons.work_rounded, size: 48, color: AppColors.card2),
            const SizedBox(height: 16),
            Text(widget.title,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPri(context))),
            const SizedBox(height: 12),
            Text(
                'Choose your mode of study. After registration you must complete the online payment to confirm your seat.',
                style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSec(context))),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _mode,
              decoration: InputDecoration(
                labelText: 'Mode',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'ONLINE', child: Text('Online')),
                DropdownMenuItem(value: 'OFFLINE', child: Text('Offline')),
              ],
              onChanged: (v) => setState(() => _mode = v ?? 'ONLINE'),
            ),
            if (_mode == 'OFFLINE') ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _location,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'TIRUNELVELI', child: Text('Tirunelveli')),
                  DropdownMenuItem(
                      value: 'TISAIYANVILAI', child: Text('Tisaiyanvilai')),
                ],
                onChanged: (v) => setState(() => _location = v ?? 'TIRUNELVELI'),
              ),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.info_rounded, size: 18, color: AppColors.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'Registration fee (10% of internship fee) must be paid online via Razorpay to confirm your seat.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSec(context))),
                ),
              ]),
            ),
            if (_alreadyMsg != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.block_rounded,
                      size: 18, color: AppColors.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_alreadyMsg!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    (_submitting || _alreadyMsg != null) ? null : _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Application',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
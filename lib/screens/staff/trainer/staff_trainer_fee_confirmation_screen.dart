import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../services/trainer_service.dart';

class StaffTrainerFeeConfirmationScreen extends ConsumerStatefulWidget {
  final String batchId;
  const StaffTrainerFeeConfirmationScreen({super.key, required this.batchId});

  @override
  ConsumerState<StaffTrainerFeeConfirmationScreen> createState() =>
      _StaffTrainerFeeConfirmationScreenState();
}

class _StaffTrainerFeeConfirmationScreenState
    extends ConsumerState<StaffTrainerFeeConfirmationScreen> {
  String _staffId = '';
  List<dynamic> _students = [];
  String? _selectedStudentId;
  final _amountCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  bool _submitting = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _staffId = await StorageHelper.getStaffId() ?? '';
    if (_staffId.isNotEmpty) {
      final result = await TrainerService.getBatchStudents(
          _staffId, widget.batchId);
      if (result['success'] == true) {
        final data = result['data'];
        final students = data is Map && data['students'] is List
            ? data['students'] as List
            : data is List
                ? data
                : [];
        _students = students;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (_selectedStudentId == null || _amountCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Select a student and enter amount'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _submitting = true);
    final result = await TrainerService.confirmFee(_staffId, {
      'studentId': int.tryParse(_selectedStudentId!) ?? 0,
      'batchId': int.tryParse(widget.batchId) ?? 0,
      'amount': double.tryParse(_amountCtrl.text.trim()) ?? 0,
      'remarks': _remarksCtrl.text.trim(),
    });
    setState(() => _submitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              result['success'] == true
                  ? 'Fee confirmed'
                  : 'Confirmation failed'),
          backgroundColor: result['success'] == true
              ? AppColors.success
              : AppColors.error,
        ),
      );
      if (result['success'] == true) {
        _amountCtrl.clear();
        _remarksCtrl.clear();
        setState(() => _selectedStudentId = null);
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Fee Confirmation',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                      Text('Select Student',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPri(context))),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedStudentId,
                        decoration: InputDecoration(
                          hintText: 'Choose student',
                          hintStyle: TextStyle(
                              color: AppColors.textHi(context)),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _students.map((s) {
                          final id = s['studentId']?.toString() ?? '';
                          final name = s['studentName']?.toString() ??
                              'Unknown';
                          return DropdownMenuItem(
                            value: id,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (v) => setState(
                            () => _selectedStudentId = v),
                      ),
                      const SizedBox(height: 18),
                      Text('Amount Paid',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPri(context))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          hintText: 'Enter amount',
                          hintStyle: TextStyle(
                              color: AppColors.textHi(context)),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.accent, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('Remarks (optional)',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPri(context))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _remarksCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Any remarks',
                          hintStyle: TextStyle(
                              color: AppColors.textHi(context)),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.accent, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2))
                              : const Text('Confirm Fee Payment',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ]),
              ),
            ),
    );
  }
}

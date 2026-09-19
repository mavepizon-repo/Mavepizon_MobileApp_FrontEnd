import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../services/trainer_service.dart';

class StaffTrainerZoomLinkScreen extends ConsumerStatefulWidget {
  final String batchId;
  final String? currentZoomLink;
  const StaffTrainerZoomLinkScreen(
      {super.key, required this.batchId, this.currentZoomLink});

  @override
  ConsumerState<StaffTrainerZoomLinkScreen> createState() =>
      _StaffTrainerZoomLinkScreenState();
}

class _StaffTrainerZoomLinkScreenState
    extends ConsumerState<StaffTrainerZoomLinkScreen> {
  String _staffId = '';
  final _linkCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _staffId = await StorageHelper.getStaffId() ?? '';
    if (widget.currentZoomLink != null && widget.currentZoomLink!.isNotEmpty) {
      _linkCtrl.text = widget.currentZoomLink!;
    }
  }

  Future<void> _submit() async {
    final link = _linkCtrl.text.trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a zoom link')),
      );
      return;
    }
    setState(() => _submitting = true);
    final data = {
      'batchId': widget.batchId,
      'zoomLink': link,
    };
    final result = await TrainerService.updateZoomLink(_staffId, data);
    setState(() => _submitting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true
              ? 'Zoom link updated'
              : 'Failed to update zoom link'),
          backgroundColor: result['success'] == true
              ? AppColors.success
              : AppColors.error,
        ),
      );
      if (result['success'] == true) Navigator.pop(context, link);
    }
  }

  @override
  void dispose() {
    _linkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Update Zoom Link',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
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
              Text('Current Zoom Link',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSec(context))),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.currentZoomLink?.isNotEmpty == true
                      ? widget.currentZoomLink!
                      : 'No zoom link set',
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.currentZoomLink?.isNotEmpty == true
                        ? AppColors.textPri(context)
                        : AppColors.textHi(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text('New Zoom Link',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPri(context))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _linkCtrl,
                decoration: InputDecoration(
                  hintText: 'https://zoom.us/j/...',
                  hintStyle:
                      TextStyle(color: AppColors.textHi(context)),
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
            ]),
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
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Update Zoom Link',
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
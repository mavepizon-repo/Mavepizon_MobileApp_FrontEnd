import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/internship_model.dart';
import '../../../providers/internship_provider.dart';
import '../../../services/internship_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/status_badge.dart';

class AdminInternshipDetailScreen extends ConsumerStatefulWidget {
  final String internshipId;
  const AdminInternshipDetailScreen({super.key, required this.internshipId});
  @override
  ConsumerState<AdminInternshipDetailScreen> createState() =>
      _AdminInternshipDetailScreenState();
}

class _AdminInternshipDetailScreenState
    extends ConsumerState<AdminInternshipDetailScreen> {
  InternshipModel? _internship;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await InternshipService.getById(widget.internshipId);
      if (result['success'] == true) {
        setState(() => _internship = InternshipModel.fromJson(result['data']));
      } else {
        setState(() => _error = result['message'] ?? 'Failed to load');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleStatus() async {
    if (_internship == null) return;
    final newStatus =
        _internship!.status.toUpperCase() == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    final ok = await ref
        .read(internshipProvider.notifier)
        .toggleStatus(_internship!.id.toString(), newStatus);
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Internship Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: _internship == null
                ? null
                : () => Navigator.pushNamed(
                      context, AppRoutes.adminInternshipEdit,
                      arguments: {'internshipId': _internship!.id}),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Text(_error!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 14)),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: _load,
                          child: const Text('Retry'))
                    ]))
              : _internship == null
                  ? const Center(child: Text('Not found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                      _DetailSection(title: 'Basic Info', children: [
                        _DetailRow(
                            label: 'Name',
                            value: _internship!.internshipName),
                        _DetailRow(
                            label: 'Code',
                            value: _internship!.internshipCode),
                        _DetailRow(
                            label: 'Status',
                            valueWidget:
                                StatusBadge(status: _internship!.status)),
                        _DetailRow(
                            label: 'Duration',
                            value: _internship!.duration),
                        _DetailRow(
                            label: 'Created By',
                            value: _internship!.trainerName),
                      ]),
                      const SizedBox(height: 12),
                      _DetailSection(
                          title: 'Schedule & Fees', children: [
                        _DetailRow(
                            label: 'Start Date',
                            value: _internship!.startDate),
                        _DetailRow(
                            label: 'End Date',
                            value: _internship!.endDate),
                        _DetailRow(
                            label: 'Fees',
                            value:
                                '₹${_internship!.fees.toStringAsFixed(0)}'),
                        _DetailRow(
                            label: 'Registration Fees',
                            value:
                                '₹${_internship!.registrationFees.toStringAsFixed(0)}'),
                      ]),
                      const SizedBox(height: 12),
                      _DetailSection(
                          title: 'Seats', children: [
                        _DetailRow(
                            label: 'Online',
                            value:
                                '${_internship!.availableSeatsOnline} / ${_internship!.totalSeatsOnline}'),
                        _DetailRow(
                            label: 'Offline',
                            value:
                                '${_internship!.availableSeatsOffline} / ${_internship!.totalSeatsOffline}'),
                        _DetailRow(
                            label: 'Tirunelveli',
                            value:
                                '${_internship!.availableSeatsTirunelveli} / ${_internship!.totalSeatsTirunelveli}'),
                        _DetailRow(
                            label: 'Tisaiyanvilai',
                            value:
                                '${_internship!.availableSeatsTisaiyanvilai} / ${_internship!.totalSeatsTisaiyanvilai}'),
                      ]),
                      const SizedBox(height: 12),
                      _DetailSection(
                          title: 'Additional', children: [
                        _DetailRow(
                            label: 'Batch Code',
                            value: _internship!.batchCode),
                        _DetailRow(
                            label: 'Zoom Link',
                            value: _internship!.zoomLink ?? '-'),
                      ]),
                      const SizedBox(height: 12),
                      _DetailSection(
                          title: 'Description', children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                              _internship!.description.isNotEmpty
                                  ? _internship!.description
                                  : '-',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSec(context))),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _toggleStatus,
                          icon: Icon(
                              _internship!.status.toUpperCase() == 'ACTIVE'
                                  ? Icons.close_rounded
                                  : Icons.check_circle_rounded,
                              size: 20),
                          label: Text(
                              _internship!.status.toUpperCase() == 'ACTIVE'
                                  ? 'Deactivate Internship'
                                  : 'Activate Internship',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _internship!.status.toUpperCase() == 'ACTIVE'
                                    ? AppColors.error
                                    : AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ])),
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

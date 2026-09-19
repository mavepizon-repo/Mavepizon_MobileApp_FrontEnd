import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_payment_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/status_badge.dart';

class AdminPaymentListScreen extends ConsumerStatefulWidget {
  const AdminPaymentListScreen({super.key});
  @override
  ConsumerState<AdminPaymentListScreen> createState() =>
      _AdminPaymentListScreenState();
}

class _AdminPaymentListScreenState
    extends ConsumerState<AdminPaymentListScreen> {
  String _paymentFilter = '';
  String _modeFilter = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminPaymentProvider.notifier).fetch());
  }

  Future<void> _fetch() {
    return ref.read(adminPaymentProvider.notifier).fetch();
  }

  String _studentName(dynamic r) {
    final s = r['student'];
    if (s is Map) {
      return s['name']?.toString() ?? 'Student';
    }
    return 'Student';
  }

  String _courseName(dynamic r) {
    final c = r['course'];
    if (c is Map) {
      return c['courseName']?.toString() ?? 'Course';
    }
    return 'Course';
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(adminPaymentProvider);
    final registrations = p.registrations;

    var filtered = registrations.where((r) {
      final paymentStatus =
          (r['paymentStatus'] ?? '').toString().toUpperCase();
      final mode = (r['mode'] ?? '').toString().toUpperCase();
      if (_paymentFilter.isNotEmpty && paymentStatus != _paymentFilter) {
        return false;
      }
      if (_modeFilter.isNotEmpty && mode != _modeFilter) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Payments'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FChip(context, 'All', '', _paymentFilter, (v) {
                setState(() => _paymentFilter = v);
              }),
              _FChip(context, 'Pending', 'PAYMENT_PENDING', _paymentFilter, (v) {
                setState(() => _paymentFilter = v);
              }),
              _FChip(context, 'Paid', 'PAID', _paymentFilter, (v) {
                setState(() => _paymentFilter = v);
              }),
              _FChip(context, 'Failed', 'FAILED', _paymentFilter, (v) {
                setState(() => _paymentFilter = v);
              }),
              _FChip(context, 'Refunded', 'REFUNDED', _paymentFilter, (v) {
                setState(() => _paymentFilter = v);
              }),
              const SizedBox(width: 8),
              _FChip(context, 'All Modes', '', _modeFilter, (_) {
                setState(() => _modeFilter = _);
              }),
              _FChip(context, 'Online', 'ONLINE', _modeFilter, (_) {
                setState(() => _modeFilter = _);
              }),
              _FChip(context, 'Offline', 'OFFLINE', _modeFilter, (_) {
                setState(() => _modeFilter = _);
              }),
            ]),
          ),
        ),
        Expanded(
          child: p.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : p.error != null
                  ? Center(child: Text(p.error!))
                  : filtered.isEmpty
                      ? Center(
                          child: Text(registrations.isEmpty
                              ? 'No registrations found'
                              : 'No payments match filters',
                              style:
                                  TextStyle(color: AppColors.textHi(context))))
                      : RefreshIndicator(
                          onRefresh: _fetch,
                          color: AppColors.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final r = filtered[i];
                              final paymentStatus =
                                  (r['paymentStatus'] ?? 'PAYMENT_PENDING')
                                      .toString()
                                      .toUpperCase();
                              final regStatus =
                                  (r['registrationStatus'] ?? '')
                                      .toString()
                                      .toUpperCase();
                              final fee = r['registrationFeeAmount'];
                              final mode =
                                  (r['mode'] ?? '').toString().toUpperCase();
                              final location =
                                  r['location']?.toString().toUpperCase();
                              return GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.adminPaymentDetail,
                                    arguments: {
                                      'registrationId': r['id']?.toString()
                                    }),
                                child: Container(
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
                                          offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Expanded(
                                            child: Text(_studentName(r),
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: AppColors
                                                        .textPrimary)),
                                          ),
                                          StatusBadge(
                                              status: paymentStatus),
                                        ]),
                                        const SizedBox(height: 4),
                                        Text(_courseName(r),
                                            style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppColors.textSec(context))),
                                        const SizedBox(height: 4),
                                        Text(
                                            [
                                              if (fee != null)
                                                'Fee: ₹$fee',
                                              if (mode.isNotEmpty) mode,
                                              if (location != null &&
                                                  location.isNotEmpty)
                                                location,
                                              if (regStatus.isNotEmpty)
                                                'Reg: $regStatus',
                                            ].join(' · '),
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textHi(context))),
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

Widget _FChip(BuildContext context, String label, String value, String current, void Function(String) onSelected) {
  final selected = current == value;
  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: GestureDetector(
      onTap: () => onSelected(selected ? '' : value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSec(context))),
      ),
    ),
  );
}

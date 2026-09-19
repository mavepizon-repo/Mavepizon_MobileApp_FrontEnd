import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_payment_provider.dart';
import '../../../widgets/status_badge.dart';

class AdminPaymentDetailScreen extends ConsumerStatefulWidget {
  final String registrationId;
  const AdminPaymentDetailScreen(
      {super.key, required this.registrationId});
  @override
  ConsumerState<AdminPaymentDetailScreen> createState() =>
      _AdminPaymentDetailScreenState();
}

class _AdminPaymentDetailScreenState
    extends ConsumerState<AdminPaymentDetailScreen> {
  List<dynamic>? _payments;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // GET /api/payment/razorpay/registration/{registrationId}
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payments = await ref
          .read(adminPaymentProvider.notifier)
          .fetchPaymentsByRegistration(widget.registrationId);
      setState(() => _payments = payments);
    } catch (e) {
      setState(() => _error = 'Error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  String _fmtPaise(dynamic amount) {
    final n = amount is num
        ? amount.toInt()
        : int.tryParse(amount?.toString() ?? '');
    if (n == null) return '-';
    return '₹${(n / 100).toStringAsFixed(2)}';
  }

  String _d(dynamic v) => v?.toString() ?? '-';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Payment Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
              : _payments == null || _payments!.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          Icon(Icons.payments_rounded,
                              size: 56,
                              color: AppColors.textHi(context).withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text('No Razorpay payment record for this registration',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.textHi(context),
                                  fontSize: 13)),
                        ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            for (final p in _payments!) ...[
                              _DetailSection(title: 'Payment Info', children: [
                                _DetailRow(
                                    label: 'Payment Status',
                                    valueWidget: StatusBadge(
                                        status:
                                            _d(p['paymentStatus']))),
                                _DetailRow(
                                    label: 'Amount',
                                    value: _fmtPaise(p['amount'])),
                                _DetailRow(
                                    label: 'Currency',
                                    value: _d(p['currency'])),
                                _DetailRow(
                                    label: 'Paid On',
                                    value: _d(p['paymentDate'])
                                        .split('T')
                                        .first),
                              ]),
                              const SizedBox(height: 12),
                              _DetailSection(
                                  title: 'Transaction', children: [
                                _DetailRow(
                                    label: 'Razorpay Order ID',
                                    value: _d(p['razorpayOrderId'])),
                                _DetailRow(
                                    label: 'Razorpay Payment ID',
                                    value: _d(p['razorpayPaymentId'])),
                                _DetailRow(
                                    label: 'Signature',
                                    value: _d(p['razorpaySignature'])),
                                _DetailRow(
                                    label: 'Created At',
                                    value:
                                        _d(p['createdAt']).split('T').first),
                              ]),
                              const SizedBox(height: 20),
                            ],
                          ]),
                    ),
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/student_course_provider.dart';
import '../../../providers/student_payment_provider.dart';
import '../../../routes/app_routes.dart';

class StudentPaymentHistoryScreen extends ConsumerStatefulWidget {
  const StudentPaymentHistoryScreen({super.key});
  @override
  ConsumerState<StudentPaymentHistoryScreen> createState() =>
      _StudentPaymentHistoryScreenState();
}

class _StudentPaymentHistoryScreenState
    extends ConsumerState<StudentPaymentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentCourseProvider.notifier).fetchMyCourses();
    });
  }

  String _courseName(dynamic r) {
    final course = r['course'];
    if (course is Map) {
      return course['courseName']?.toString() ?? 'Course';
    }
    return r['courseName']?.toString() ?? 'Course';
  }

  Color _statusColor(String? s) {
    switch (s?.toUpperCase()) {
      case 'PAID':
      case 'COMPLETED':
      case 'SUCCESS':
      case 'CONFIRMED':
        return AppColors.success;
      case 'FAILED':
      case 'REFUNDED':
        return AppColors.error;
      case 'CREATED':
      case 'PAYMENT_PENDING':
      case 'PENDING':
        return AppColors.warning;
      default:
        return AppColors.textHi(context);
    }
  }

  String _fmtPaise(dynamic amount) {
    final n = amount is num
        ? amount.toInt()
        : int.tryParse(amount?.toString() ?? '');
    if (n == null) return '-';
    return '₹${(n / 100).toStringAsFixed(2)}';
  }

  // GET /api/payment/razorpay/registration/{registrationId}
  Future<void> _showPaymentSheet(dynamic reg) async {
    final regId = (reg['id'] ?? reg['registrationId']).toString();

    await ref
        .read(studentPaymentProvider.notifier)
        .fetchPaymentsByRegistration(regId);
    if (!mounted) return;

    final payments = ref.read(studentPaymentProvider).payments;

    if (payments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No payment record yet. Complete payment online.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: AppColors.accent),
                  const SizedBox(width: 10),
                  Text('Payment Receipt',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPri(context))),
                ]),
                const Divider(height: 28),
                for (final p in payments) ...[
                  _receiptRow('Status',
                      (p['paymentStatus'] ?? 'PAYMENT_PENDING').toString()),
                  _receiptRow('Amount', _fmtPaise(p['amount'])),
                  _receiptRow('Currency', p['currency']?.toString() ?? 'INR'),
                  _receiptRow('Razorpay Order ID',
                      p['razorpayOrderId']?.toString() ?? '-'),
                  _receiptRow('Razorpay Payment ID',
                      p['razorpayPaymentId']?.toString() ?? '-'),
                  if (p['paymentDate'] != null)
                    _receiptRow('Paid On',
                        p['paymentDate'].toString().split('T').first),
                  if (p['createdAt'] != null)
                    _receiptRow('Created On',
                        p['createdAt'].toString().split('T').first),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final first = payments.first;
                      Share.share(
                        'Payment Receipt\n'
                        'Course: ${_courseName(reg)}\n'
                        'Status: ${(first['paymentStatus'] ?? 'PAYMENT_PENDING').toString()}\n'
                        'Amount: ${_fmtPaise(first['amount'])}\n'
                        'Razorpay Order ID: ${first['razorpayOrderId']?.toString() ?? '-'}\n'
                        'Razorpay Payment ID: ${first['razorpayPaymentId']?.toString() ?? '-'}\n'
                        'Paid On: ${first['paymentDate']?.toString().split('T').first ?? '-'}',
                        subject: 'Payment Receipt',
                      );
                    },
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 140,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textHi(context)))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPri(context)))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = ref.watch(studentCourseProvider);

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Payment History',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(studentCourseProvider.notifier).fetchMyCourses(),
        child: cp.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2))
            : cp.error != null
                ? Center(
                    child: Text(cp.error!,
                        style: const TextStyle(color: AppColors.error)))
                : cp.myCourses.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.payments_rounded,
                                  size: 60,
                                  color:
                                      AppColors.textHi(context).withOpacity(0.4)),
                              const SizedBox(height: 16),
                              Text('No payments yet',
                                  style:
                                      TextStyle(color: AppColors.textHi(context))),
                            ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cp.myCourses.length,
                        itemBuilder: (ctx, i) {
                          final r = cp.myCourses[i];
                          final paymentStatus =
                              (r['paymentStatus'] ?? 'PENDING')
                                  .toString()
                                  .toUpperCase();
                          final regStatus =
                              (r['registrationStatus'] ?? '')
                                  .toString()
                                  .toUpperCase();
                          final fee = r['registrationFeeAmount'];
                          final regId = r['id'] ?? r['registrationId'];
                          final hasPaid = paymentStatus == 'PAID' ||
                              paymentStatus == 'COMPLETED' ||
                              paymentStatus == 'SUCCESS';
                          return GestureDetector(
                            onTap: () => _showPaymentSheet(r),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2))
                                  ]),
                              child: Row(children: [
                                Container(
                                  width: 3,
                                  height: 36,
                                  decoration: BoxDecoration(
                                      color: _statusColor(paymentStatus),
                                      borderRadius:
                                          BorderRadius.circular(3)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(_courseName(r),
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight:
                                                    FontWeight.w700,
                                                color: AppColors
                                                    .textPrimary)),
                                        const SizedBox(height: 2),
                                        Text(
                                            fee != null
                                                ? 'Registration Fee: ₹$fee'
                                                : regStatus.isNotEmpty
                                                    ? regStatus
                                                    : '',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors
                                                    .textSecondary)),
                                      ]),
                                ),
                                if (!hasPaid)
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.studentOnlinePayment,
                                        arguments: {
                                          'registrationId':
                                              regId is int
                                                  ? regId
                                                  : int.tryParse(
                                                      regId.toString()),
                                          'itemName': _courseName(r),
                                          'amount': fee,
                                        },
                                      ).then((_) => ref
                                          .read(studentCourseProvider
                                              .notifier)
                                          .fetchMyCourses());
                                    },
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Text('Pay',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white)),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(paymentStatus)
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(paymentStatus,
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: _statusColor(
                                                paymentStatus))),
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
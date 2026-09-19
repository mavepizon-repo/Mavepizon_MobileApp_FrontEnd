import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';

class StudentCashPaymentScreen extends StatefulWidget {
  final int? registrationId;
  final int? internshipRegistrationId;
  final String? itemName;

  const StudentCashPaymentScreen({
    super.key,
    this.registrationId,
    this.internshipRegistrationId,
    this.itemName,
  });

  @override
  State<StudentCashPaymentScreen> createState() =>
      _StudentCashPaymentScreenState();
}

class _StudentCashPaymentScreenState extends State<StudentCashPaymentScreen> {
  bool get _canPayOnline =>
      widget.registrationId != null &&
      widget.internshipRegistrationId == null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Payment',
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
          child: Column(children: [
            Icon(
              _canPayOnline
                  ? Icons.verified_user_rounded
                  : Icons.info_outline_rounded,
              size: 56,
              color: _canPayOnline ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(height: 14),
            Text(
              _canPayOnline
                  ? 'Pay Online'
                  : 'Online payment not available',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPri(context)),
            ),
            const SizedBox(height: 10),
            Text(
              _canPayOnline
                  ? 'Cash payments are no longer accepted. Complete your '
                      'registration by paying online via Razorpay (UPI, '
                      'cards, wallets & net banking).'
                  : 'Online payment is not yet available for this item. '
                      'Please contact office staff for assistance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textSec(context)),
            ),
            if (widget.itemName != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.menu_book_rounded,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.itemName!,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context))),
                  ),
                ]),
              ),
            ],
            if (_canPayOnline) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.studentOnlinePayment,
                      arguments: {
                        'registrationId': widget.registrationId,
                        'itemName': widget.itemName,
                      },
                    );
                  },
                  icon: const Icon(Icons.lock_rounded, size: 18),
                  label: const Text('Pay Online Now',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
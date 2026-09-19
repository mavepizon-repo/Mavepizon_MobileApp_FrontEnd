import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/student_payment_provider.dart';

class StudentOnlinePaymentScreen extends ConsumerStatefulWidget {
  final int? registrationId;
  final String? itemName;
  final num? amount;

  const StudentOnlinePaymentScreen({
    super.key,
    this.registrationId,
    this.itemName,
    this.amount,
  });

  @override
  ConsumerState<StudentOnlinePaymentScreen> createState() =>
      _StudentOnlinePaymentScreenState();
}

class _StudentOnlinePaymentScreenState
    extends ConsumerState<StudentOnlinePaymentScreen> {
  late Razorpay _razorpay;
  Map<String, dynamic>? _order;
  bool _creatingOrder = false;
  bool _verifying = false;
  bool _success = false;
  String? _orderError;
  String? _lastPaymentId;
  String? _lastSignature;

  final _paymentIdCtrl = TextEditingController();
  final _signatureCtrl = TextEditingController();

  bool get _canUseSdk => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _paymentIdCtrl.dispose();
    _signatureCtrl.dispose();
    super.dispose();
  }

  // POST /api/payment/razorpay/create-order
  Future<void> _createOrder() async {
    final regId = widget.registrationId;
    if (regId == null) {
      _showMsg('Registration ID is required. Please pay from My Courses.');
      return;
    }

    setState(() {
      _creatingOrder = true;
      _orderError = null;
      _order = null;
    });

    final order = await ref
        .read(studentPaymentProvider.notifier)
        .createRazorpayOrder(regId);

    if (!mounted) return;
    setState(() => _creatingOrder = false);

    if (order == null) {
      _orderError = ref.read(studentPaymentProvider).error ??
          'Unable to create Razorpay order';
      return;
    }

    setState(() => _order = order);

    if (_canUseSdk) {
      _openRazorpaySheet(order);
    }
  }

  void _openRazorpaySheet(Map<String, dynamic> order) {
    try {
      _razorpay.open({
        'key': order['keyId'],
        'amount': order['amount'], // already in paise
        'currency': order['currency'] ?? 'INR',
        'order_id': order['razorpayOrderId'],
        'name': 'Mavepizon Technologies',
        'description': widget.itemName ?? 'Course Registration',
        'theme': {'color': '#1E3A5F'},
      });
    } catch (e) {
      _showMsg('Unable to open Razorpay: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final paymentId = response.paymentId;
    final orderId = response.orderId;
    final signature = response.signature;
    debugPrint(
        'PAYMENT_SUCCESS => paymentId=$paymentId orderId=$orderId signature=$signature');
    if (paymentId == null || orderId == null || signature == null) {
      _showMsg(
          'Payment succeeded but the response was incomplete. Verify the payment from Razorpay dashboard.');
      return;
    }
    _verify(
      registrationId: widget.registrationId,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showMsg(
        'Payment failed (${response.code}): ${response.message ?? 'Please try again'}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showMsg('External wallet selected: ${response.walletName}');
  }

  // POST /api/payment/razorpay/verify
  Future<void> _verify({
    required int? registrationId,
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    if (registrationId == null) {
      _showMsg('Registration ID is required.');
      return;
    }

    setState(() => _verifying = true);

    final result = await ref
        .read(studentPaymentProvider.notifier)
        .verifyPayment(
      registrationId: registrationId,
      razorpayPaymentId: paymentId,
      razorpayOrderId: orderId,
      razorpaySignature: signature,
    );

    if (!mounted) return;
    setState(() => _verifying = false);

    if (result != null && result['success'] == true) {
      setState(() {
        _success = true;
        _lastPaymentId = paymentId;
        _lastSignature = signature;
      });
      _showMsg('Payment verified! Registration confirmed.',
          isSuccess: true);
    } else {
      _showMsg(ref.read(studentPaymentProvider).error ??
          'Payment verification failed');
    }
  }

  Future<void> _verifyManual() async {
    final paymentId = _paymentIdCtrl.text.trim();
    final signature = _signatureCtrl.text.trim();
    if (paymentId.isEmpty || signature.isEmpty) {
      _showMsg('Enter the Razorpay Payment ID and Signature');
      return;
    }
    await _verify(
      registrationId: widget.registrationId,
      paymentId: paymentId,
      orderId: _order?['razorpayOrderId']?.toString() ?? '',
      signature: signature,
    );
  }

  void _showMsg(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isSuccess ? AppColors.success : AppColors.error,
    ));
  }

  String _formatRupees(dynamic value) {
    if (value == null) return '';
    final paise = value is num ? value.toInt() : int.tryParse(value.toString());
    if (paise == null) return value.toString();
    return '₹${(paise / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Online Payment',
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
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    _success
                        ? Icons.check_circle_rounded
                        : Icons.payment_rounded,
                    size: 36,
                    color: _success ? AppColors.success : AppColors.info),
              ),
              const SizedBox(height: 20),
              Text(
                  _success ? 'Payment Verified' : 'Secure Online Payment',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPri(context))),
              const SizedBox(height: 10),
              if (widget.itemName != null)
                Text(widget.itemName!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSec(context))),
              if (widget.amount != null) ...[
                const SizedBox(height: 6),
                Text(_formatRupees(widget.amount),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent)),
              ],
              const SizedBox(height: 10),
              Text(
                  'Payment is processed securely via Razorpay (UPI, cards, wallets & net banking).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.textHi(context))),
              const SizedBox(height: 24),
              if (_order != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('Order ID',
                            _order!['razorpayOrderId']?.toString() ?? '-'),
                        _row('Amount',
                            _formatRupees(_order!['amount'] ?? '')),
                        _row('Status',
                            _order!['message']?.toString() ?? 'Created'),
                        if (_success) ...[
                          _row('Payment ID', _lastPaymentId ?? '-'),
                          _row('Signature', _lastSignature ?? '-'),
                        ],
                      ]),
                ),
                const SizedBox(height: 14),
              ],
              if (_orderError != null) ...[
                Text(_orderError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 13)),
                const SizedBox(height: 14),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: (_creatingOrder || _verifying || _success)
                      ? null
                      : _createOrder,
                  icon: _creatingOrder
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.lock_rounded, size: 18),
                  label: Text(
                      _order == null
                          ? 'Pay Now'
                          : (_canUseSdk ? 'Pay with Razorpay' : 'Create Order'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              if (_verifying) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text('Verifying payment...',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSec(context))),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 16),
          if (_canUseSdk && _order != null && !_success)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _openRazorpaySheet(_order!),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open Razorpay Checkout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          if (!_canUseSdk && _order != null && !_success) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                    Text('Test Mode Verification',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context))),
                    const SizedBox(height: 6),
                    Text(
                        'Razorpay checkout is available on Android/iOS. '
                        'On desktop/web, enter the payment ID and signature '
                        'from your Razorpay test dashboard to verify.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSec(context))),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _paymentIdCtrl,
                      decoration: _dec('Razorpay Payment ID'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _signatureCtrl,
                      decoration: _dec('Razorpay Signature'),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _verifying ? null : _verifyManual,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                            _verifying ? 'Verifying...' : 'Verify Payment',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
            ),
          ],
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSec(context))),
            const SizedBox(width: 8),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPri(context))),
            ),
          ]),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      hintStyle: TextStyle(color: AppColors.textHi(context)),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
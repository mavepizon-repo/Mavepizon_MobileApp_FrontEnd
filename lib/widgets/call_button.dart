import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/call_manager.dart';

/// A compact, reusable Call button for telecalling list cards
/// (Enquiries, Today Follow-up) and the Enquiry Detail screen.
///
/// Launches a normal SIM/network call via the native dialer and handles the
/// required runtime permissions. If the user denies permissions, a snackbar
/// explains what to do.
class CallButton extends StatelessWidget {
  final String phone;
  final String? enquiryId;
  final double? size;
  final Color? background;
  final Color? iconColor;
  final VoidCallback? onPlaceCall;

  const CallButton({
    super.key,
    required this.phone,
    this.enquiryId,
    this.size = 40,
    this.background,
    this.iconColor,
    this.onPlaceCall,
  });

  Future<void> _placeCall(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    void show(String msg, {bool error = true}) {
      messenger.showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ));
    }

    if (CallManager.cleanPhone(phone).isEmpty) {
      show('No phone number on this record');
      return;
    }

    final manager = CallManager.instance;

    // Ensure runtime permissions are granted before placing the call.
    final perms = await manager.getPermissions();
    if (perms['callPhone'] != true || perms['readPhoneState'] != true) {
      final granted = await manager.requestPermissions();
      if (!granted) {
        if (context.mounted) {
          show(
              'Phone permissions are required to make calls. '
              'Please allow them in Settings -> Apps -> Mavepizon -> Permissions.');
        }
        return;
      }
    }

    if (context.mounted) {
      final result = await manager.placeCall(phone, enquiryId: enquiryId);
      if (context.mounted) {
        if (!result.started) {
          switch (result.reason) {
            case 'no_number':
              show('No phone number on this record');
              break;
            case 'platform_error':
              show('Calling is only supported on Android devices');
              break;
            default:
              show('Could not start the call. Please check your permissions.');
          }
        } else {
          onPlaceCall?.call();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = size!;
    return GestureDetector(
      onTap: () => _placeCall(context),
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: background ?? AppColors.success.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.call_rounded,
          color: iconColor ?? AppColors.success,
          size: s * 0.5,
        ),
      ),
    );
  }
}

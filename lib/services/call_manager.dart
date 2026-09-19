import 'dart:async';

import 'package:flutter/services.dart';

// A single lifecycle event reported by the Android native PhoneStateListener.
enum CallPhase { started, ringing, connected, ended }

class CallEvent {
  final CallPhase phase;
  final DateTime timestamp;
  final DateTime? startedAt;
  final DateTime? connectedAt;
  final DateTime? endAt;

  const CallEvent(this.phase, this.timestamp,
      {this.startedAt, this.connectedAt, this.endAt});
}

// Result of requesting the OS to place an outgoing call.
class PlaceCallResult {
  final bool started;
  final String reason; // '', 'no_number', 'permission_required', 'activity_error'
  const PlaceCallResult({required this.started, this.reason = ''});
}

// A fully captured call that can be sent to the backend.
class CallRecord {
  final String? enquiryId;
  final String staffId;
  final String phone;
  final String status; // COMPLETED / BUSY / NO_ANSWER / FAILED / UNKNOWN
  final DateTime? startTime;
  final DateTime? connectedTime;
  final DateTime? endTime;
  final int durationSeconds;

  const CallRecord({
    this.enquiryId,
    required this.staffId,
    required this.phone,
    required this.status,
    this.startTime,
    this.connectedTime,
    this.endTime,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() {
    String? iso(DateTime? d) => d?.toLocal().toIso8601String();
    return {
      'enquiryId': enquiryId,
      'staffId': staffId,
      'phoneNumber': phone,
      'callStatus': status,
      'startTime': iso(startTime),
      'answeredTime': iso(connectedTime),
      'endTime': iso(endTime),
      'durationSeconds': durationSeconds,
    };
  }
}

/// Bridges to the Android native call implementation in [MainActivity.kt].
///
/// Native side exposes:
///  - MethodChannel `mavepizon/call` : placeCall / requestPermissions /
///    getPermissions / dispose
///  - EventChannel `mavepizon/call_events` : pushes lifecycle events as
///    `{state, ts, startedAt, connectedAt, endAt}`.
class CallManager {
  CallManager._() {
    _events.receiveBroadcastStream().listen(_onNativeEvent, onError: (_) {});
  }

  static final CallManager instance = CallManager._();

  static const MethodChannel _channel = MethodChannel('mavepizon/call');
  static const EventChannel _events = EventChannel('mavepizon/call_events');

  final StreamController<CallEvent> _controller =
      StreamController<CallEvent>.broadcast();

  bool _lastPermissionResult = true;
  bool _startedThisSession = false;

  /// Number dialled on the most recent call (used by the call logger to
  /// record the call without the native listener needing the number).
  String? lastDialedNumber;

  /// Enquiry the most recent call was placed for (nullable — list-screen
  /// calls also get logged, with no enquiry link if none was known).
  String? lastDialedEnquiryId;

  /// Broadcast stream of raw lifecycle events fired by the native listener.
  Stream<CallEvent> get events => _controller.stream;

  bool get lastPermissionGranted => _lastPermissionResult;

  Future<void> _onNativeEvent(dynamic raw) async {
    if (raw is! Map) return;
    final state = raw['state']?.toString() ?? '';
    final ts = (raw['ts'] as num?)?.toInt() ?? 0;
    final started = (raw['startedAt'] as num?)?.toInt();
    final connected = (raw['connectedAt'] as num?)?.toInt();
    final end = (raw['endAt'] as num?)?.toInt();

    final phase = state == 'started'
        ? CallPhase.started
        : state == 'ringing'
            ? CallPhase.ringing
            : state == 'connected'
                ? CallPhase.connected
                : CallPhase.ended;

    _controller.add(CallEvent(
      phase,
      DateTime.fromMillisecondsSinceEpoch(ts),
      startedAt: started != null && started > 0
          ? DateTime.fromMillisecondsSinceEpoch(started)
          : null,
      connectedAt: connected != null && connected > 0
          ? DateTime.fromMillisecondsSinceEpoch(connected)
          : null,
      endAt: end != null && end > 0
          ? DateTime.fromMillisecondsSinceEpoch(end)
          : null,
    ));
  }

  Future<Map<String, bool>> getPermissions() async {
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'getPermissions');
      if (raw == null) return {'callPhone': false, 'readPhoneState': false};
      return {
        'callPhone': raw['callPhone'] == true,
        'readPhoneState': raw['readPhoneState'] == true,
      };
    } catch (e) {
      // Not on Android (e.g. Windows/web testing) - treat as not available.
      _lastPermissionResult = false;
      return {'callPhone': false, 'readPhoneState': false};
    }
  }

  /// Requests CALL_PHONE + READ_PHONE_STATE from the user at runtime.
  Future<bool> requestPermissions() async {
    try {
      _lastPermissionResult =
          await _channel.invokeMethod('requestPermissions') == true;
    } catch (_) {
      _lastPermissionResult = false;
    }
    // Re-read truth from the OS after the prompt.
    final perms = await getPermissions();
    _lastPermissionResult =
        perms['callPhone'] == true && perms['readPhoneState'] == true;
    return _lastPermissionResult;
  }

  /// Strips all non-digit characters from a phone number so the Android
  /// dialer receives a clean numeric string (e.g. "98765 43210" → "9876543210").
  static String cleanPhone(String raw) {
    return raw.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Places an outgoing call for [number]. Returns whether the dialer opened.
  /// [enquiryId] (optional) is remembered so the auto call-logger can link the
  /// finished call to its enquiry.
  Future<PlaceCallResult> placeCall(String number, {String? enquiryId}) async {
    final cleaned = cleanPhone(number);
    lastDialedNumber = cleaned.isEmpty ? null : cleaned;
    lastDialedEnquiryId = enquiryId;
    var perms = await getPermissions();
    if (perms['callPhone'] != true || perms['readPhoneState'] != true) {
      await requestPermissions();
      perms = await getPermissions();
      if (perms['callPhone'] != true || perms['readPhoneState'] != true) {
        return const PlaceCallResult(
            started: false, reason: 'permission_required');
      }
    }
    if (cleaned.isEmpty) {
      return const PlaceCallResult(started: false, reason: 'no_number');
    }
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'placeCall', {'number': cleaned});
      if (res == null) {
        return const PlaceCallResult(started: false);
      }
      final started = res['started'] == true;
      _startedThisSession = started;
      return PlaceCallResult(
          started: started, reason: res['reason']?.toString() ?? '');
    } catch (e) {
      // Method channel unavailable (non-Android platform).
      return const PlaceCallResult(started: false, reason: 'platform_error');
    }
  }

  /// Whether a call was initiated in this app session (used by screens to
  /// surface the "call in progress" banner while the dialer is open).
  bool get startedThisSession => _startedThisSession;

  void resetSessionStarted() => _startedThisSession = false;
}

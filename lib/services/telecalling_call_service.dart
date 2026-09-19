import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_client.dart';
import 'call_manager.dart';

/// Telecalling call-log persistence.
///
/// Frontend stores call records LOCALLY (SharedPreferences) so the Enquiry
/// Detail screen and the Admin "Telecalling Calls" page keep working offline,
/// and simultaneously syncs each completed call to the backend.
///
/// Backend contract (implemented):
///   POST /api/officestaff/telecalling/call
///     Body (CallLogRequest):
///     {
///       "enquiryId":  "123" | null,
///       "staffId":    "S002",
///       "phoneNumber":"9876543210",
///       "callStatus": "COMPLETED | BUSY | NO_ANSWER | FAILED | UNKNOWN",
///       "startTime":  "2026-09-01T10:00:00.000" | null,
///       "answeredTime":"2026-09-01T10:00:12.000" | null,
///       "endTime":    "2026-09-01T10:01:00.000" | null,
///       "durationSeconds": 60
///     }
///     Response: { "success": true, "data": { "callId": "...", ... } }
///
///   GET /api/officestaff/telecalling/enquiry/calls/{enquiryId}
///     Response: { "success": true, "data": [ { ...call record... }, ... ] }
///
///   GET /api/admin/telecalling/calls?date=&staffId=
///     Response: { "success": true, "data": [ { ...call record... }, ... ] }
class TelecallingCallService {
  TelecallingCallService._();

  static const String _localKey = 'telecalling_call_records';

  // ─── Local persistence (backend endpoint pending) ──────────────────

  /// All call records saved on this device (newest first).
  static Future<List<Map<String, dynamic>>> getLocalCalls() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_localKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {
      // Corrupt store — ignore.
    }
    return [];
  }

  /// All saved records for one enquiry (newest first).
  static Future<List<Map<String, dynamic>>> getLocalCallsByEnquiry(
      String enquiryId) async {
    final calls = await getLocalCalls();
    return calls
        .where((c) => c['enquiryId']?.toString() == enquiryId)
        .toList();
  }

  static Future<void> _saveLocalList(List<Map<String, dynamic>> calls) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_localKey, jsonEncode(calls));
  }

  /// Saves a record locally (newest first, capped to 500 records).
  static Future<void> saveCallLocally(Map<String, dynamic> record) async {
    final calls = await getLocalCalls();
    calls.removeWhere((c) =>
        c['localId']?.toString() == record['localId']?.toString());
    calls.insert(0, record);
    if (calls.length > 500) calls.removeRange(500, calls.length);
    await _saveLocalList(calls);
  }

  // ─── Backend endpoints ───────────────────────────────────────────

  static Future<Map<String, dynamic>> saveCall(
      String staffId, Map<String, dynamic> call) {
    return ApiClient.post(
        '/api/officestaff/telecalling/call', call);
  }

  static Future<Map<String, dynamic>> getCallHistory(
      String staffId, String enquiryId) async {
    try {
      final res = await ApiClient.get(
          '/api/officestaff/telecalling/enquiry/calls/$enquiryId');
      if (res['success'] == true && res['data'] is List) {
        final remote = res['data'] as List;
        final locals = await getLocalCallsByEnquiry(enquiryId);
        final merged = <Map<String, dynamic>>[];
        final seenSyncIds = <String>{};
        for (final r in remote) {
          if (r is Map) {
            final m = Map<String, dynamic>.from(r);
            if (m['callId'] != null) seenSyncIds.add(m['callId'].toString());
            merged.add(m);
          }
        }
        for (final l in locals) {
          final syncId = l['callId']?.toString();
          if (syncId != null && seenSyncIds.contains(syncId)) continue;
          merged.add(l);
        }
        return {'success': true, 'data': merged};
      }
    } catch (_) {
      // Backend unreachable/pending — fall through to local store.
    }
    final locals = await getLocalCallsByEnquiry(enquiryId);
    return {'success': true, 'data': locals};
  }

  // ─── Admin view: fetch all call logs from the backend ──────────────

  /// Merges backend call logs with locally-saved (pending-sync) records so
  /// the Admin page reflects everything. Backend endpoint:
  /// GET /api/admin/telecalling/calls?date=&staffId=
  static Future<List<Map<String, dynamic>>> getAdminCalls() async {
    final merged = <Map<String, dynamic>>[];
    final seenSyncIds = <String>{};
    final seenLocalIds = <String>{};
    try {
      final res = await ApiClient.get('/api/admin/telecalling/calls');
      if (res['success'] == true && res['data'] is List) {
        for (final r in res['data'] as List) {
          if (r is Map) {
            final m = Map<String, dynamic>.from(r);
            if (m['callId'] != null) seenSyncIds.add(m['callId'].toString());
            merged.add(m);
          }
        }
      }
    } catch (_) {
      // Backend unreachable — fall back to local records only.
    }
    // Merge any locally-saved records that haven't reached the backend yet,
    // so records awaiting sync (e.g. made while offline, or with no enquiryId)
    // still appear on the admin page.
    final locals = await getLocalCalls();
    for (final l in locals) {
      final syncId = l['callId']?.toString();
      if (syncId != null && seenSyncIds.contains(syncId)) continue;
      final localId = l['localId']?.toString() ?? l['localId'];
      if (localId != null) {
        if (seenLocalIds.contains(localId)) continue;
        seenLocalIds.add(localId);
      }
      merged.add(l);
    }
    return merged;
  }

  /// Pushes every not-yet-synced local record to the backend. Called on load
  /// (admin page / enquiry screens) so records that failed the initial
  /// fire-and-forget sync are retried until they reach the server. Never
  /// throws.
  static Future<void> syncPendingCalls() async {
    final calls = await getLocalCalls();
    for (final c in calls) {
      if (c['synced'] == true) continue;
      if (c['enquiryId'] == null ||
          c['enquiryId'].toString().trim().isEmpty) {
        continue; // backend requires an enquiryId — leave local only.
      }
      await _syncToBackend(c);
    }
  }

  // ─── Store a completed call: save locally, then try syncing ────────

  /// Persists a finished call locally and fires a best-effort POST to the
  /// (pending) backend endpoint. Never throws.
  static Future<void> storeCallRecord(
      String staffId, Map<String, dynamic> call) async {
    final record = Map<String, dynamic>.from(call);
    record['localId'] =
        record['localId'] ?? '${DateTime.now().microsecondsSinceEpoch}';
    record['synced'] = false;
    await saveCallLocally(record);
    await _syncToBackend(record);
  }

  /// Posts only the fields the backend CallLogRequest DTO expects.
  static Map<String, dynamic> _cleanPayload(Map<String, dynamic> record) {
    return {
      'enquiryId': record['enquiryId']?.toString(),
      'callStatus': record['callStatus']?.toString() ?? 'COMPLETED',
      'startTime': record['startTime']?.toString(),
      'answeredTime': record['answeredTime']?.toString(),
      'endTime': record['endTime']?.toString(),
      'durationSeconds': record['durationSeconds'] is int
          ? record['durationSeconds']
          : int.tryParse(record['durationSeconds']?.toString() ?? '0') ?? 0,
    };
  }

  static Future<void> _syncToBackend(Map<String, dynamic> record) async {
    try {
      final res = await ApiClient.post(
          '/api/officestaff/telecalling/call', _cleanPayload(record));
      if (res['success'] == true) {
        final updated = Map<String, dynamic>.from(record);
        updated['synced'] = true;
        if (res['data'] is Map && (res['data'] as Map)['callId'] != null) {
          updated['callId'] = (res['data'] as Map)['callId'].toString();
        }
        await saveCallLocally(updated);
      }
    } catch (_) {
      // Will be retried on next enableAutoLogging call.
    }
  }

  // ─── Auto-log every outgoing call (any screen) ─────────────────────

  static bool _autoLogStarted = false;
  static String _autoStaffId = '';
  static DateTime? _trackStart;
  static DateTime? _trackConnected;
  static bool _trackConnectedSeen = false;

  /// Subscribes once to the native call events and records every outgoing
  /// call placed from the app. Must be called with a logged-in staff id
  /// (safe to call from every telecalling screen — it only subscribes once).
  static void enableAutoLogging(String staffId) {
    if (staffId.isEmpty) return;
    _autoStaffId = staffId;
    // Re-push any records that failed to sync while offline earlier.
    unawaited(syncPendingCalls());
    if (_autoLogStarted) return;
    _autoLogStarted = true;
    CallManager.instance.events.listen(_onAutoEvent);
  }

  static Future<void> _onAutoEvent(CallEvent e) async {
    switch (e.phase) {
      case CallPhase.started:
        _trackStart = e.startedAt ?? e.timestamp;
        _trackConnected = null;
        _trackConnectedSeen = false;
        break;
      case CallPhase.ringing:
        _trackStart ??= e.timestamp;
        break;
      case CallPhase.connected:
        _trackConnected = e.connectedAt ?? e.timestamp;
        _trackConnectedSeen = true;
        break;
      case CallPhase.ended:
        await _recordEndedCall(e);
        break;
    }
  }

  /// Minimum total call duration for a call to be considered answered/talked
  /// when the native layer did not report a "connected" phase. Android does
  /// not reliably expose the answered moment for outgoing calls on every
  /// device, so a call that stayed off-hook at least this long is treated as
  /// COMPLETED instead of NO_ANSWER.
  static const int _answeredMinSeconds = 5;

  static Future<void> _recordEndedCall(CallEvent e) async {
    final end = e.endAt ?? e.timestamp;
    final start = _trackStart;
    final connected = _trackConnected ?? e.connectedAt;
    final totalDuration = start == null
        ? 0
        : end.difference(start).inSeconds.clamp(0, 86400);
    final talkDuration = (connected != null && end.isAfter(connected))
        ? end.difference(connected).inSeconds.clamp(0, 86400)
        : totalDuration;

    // A call is "answered" when either the native layer detected the connected
    // phase, or the call lasted long enough that the caller clearly talked
    // (the connected phase is missed on many Android devices).
    final answered = _trackConnectedSeen ||
        connected != null ||
        totalDuration >= _answeredMinSeconds;

    final record = CallRecord(
      enquiryId: _autoEnquiryId,
      staffId: _autoStaffId,
      phone: CallManager.instance.lastDialedNumber ?? '',
      status: answered ? 'COMPLETED' : 'NO_ANSWER',
      startTime: start,
      connectedTime: connected,
      endTime: end,
      durationSeconds: answered ? talkDuration : totalDuration,
    ).toJson();

    _trackStart = null;
    _trackConnected = null;
    _trackConnectedSeen = false;

    if (_autoStaffId.isEmpty) return;
    await storeCallRecord(_autoStaffId, record);
  }

  static String? get _autoEnquiryId => CallManager.instance.lastDialedEnquiryId;
}
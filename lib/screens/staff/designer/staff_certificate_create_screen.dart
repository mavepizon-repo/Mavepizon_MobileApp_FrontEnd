import 'package:flutter/material.dart';
import '../../../core/utils/string_utils.dart';
import '../../../services/certificate_service.dart';
import '../../../widgets/certificate_template_view.dart';
import '../../student/certificates/certificate_preview_screen.dart';

// =============================================================
// DESIGNER STUDIO - CREATE CERTIFICATE
//
// Premium gold/ivory designer workspace.
// Pulls paid (certificate-eligible) students straight from the
// backend (/api/student-course/certificate-eligible) that is
// already permitted for OFFICE_STAFF, pre-fills the fixed
// certificate template (default prompt) with backend data
// (student name, roll number, course title, start & end date)
// and only allows creation for PAID students.
// =============================================================

const Color _kIvory = Color(0xFFF8F3E8);
const Color _kSurface = Color(0xFFFFFDF8);
const Color _kSurfaceAlt = Color(0xFFF1E9D9);
const Color _kGold = Color(0xFFB8860B);
const Color _kGoldLight = Color(0xFFD4AF37);
const Color _kGoldDark = Color(0xFF8B5E00);
const Color _kGoldBorder = Color(0xFFD6B56D);
const Color _kInk = Color(0xFF171717);
const Color _kInkSec = Color(0xFF6B6255);
const Color _kInkHint = Color(0xFF9A9085);
const Color _kGreen = Color(0xFF3D7A4D);

class StaffCertificateCreateScreen extends StatefulWidget {
  const StaffCertificateCreateScreen({super.key});

  @override
  State<StaffCertificateCreateScreen> createState() =>
      _StaffCertificateCreateScreenState();
}

class _StaffCertificateCreateScreenState
    extends State<StaffCertificateCreateScreen> {
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _registrations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Course registrations. The /certificate-eligible endpoint only
      // matches the legacy "COMPLETED" payment status, but paid
      // registrations are stored as "PAID", so we pull the full list and
      // flag each record as paid below.
      final allResult = await CertificateService.getAllRegistrations();

      List<dynamic> raw = [];
      if (allResult['success'] == true &&
          allResult['data'] is List) {
        raw = allResult['data'] as List;
      } else {
        _error = allResult['message'] ?? 'Failed to load certificate data';
      }

      // 2. Existing certificate records (studentCode -> status).
      final certResult = await CertificateService.getAll();
      final certMap = <String, String>{};
      if (certResult['success'] == true && certResult['data'] is List) {
        for (final c in certResult['data'] as List) {
          if (c is Map) {
            final code = c['studentCode']?.toString() ?? '';
            final status = c['status']?.toString().toUpperCase() ?? '';
            if (code.isNotEmpty && status.isNotEmpty) {
              certMap[code] = status;
            }
          }
        }
      }

      // 3. Normalise into a list of view models.
      final regs = <Map<String, dynamic>>[];
      for (final r in raw) {
        if (r is! Map) continue;
        final map = Map<String, dynamic>.from(r);
        final student =
            map['student'] is Map ? Map<String, dynamic>.from(map['student']) : null;
        final course =
            map['course'] is Map ? Map<String, dynamic>.from(map['course']) : null;

        final code = student?['studentId']?.toString() ?? '';
        final certStatus = certMap[code] ?? _certificateStatus(map);
        map['_certificateStatus'] = certStatus;
        final pay = map['paymentStatus']?.toString().toUpperCase() ?? '';
        map['_paid'] = pay == 'PAID' || pay == 'SUCCESS' || pay == 'COMPLETED';
        map['_studentName'] =
            student?['name']?.toString() ?? map['studentName']?.toString() ?? '';
        map['_course'] = course?['courseName']?.toString() ??
            map['courseName']?.toString() ??
            '';
        map['_start'] = course?['startDate']?.toString() ??
            map['startDate']?.toString() ??
            '';
        map['_end'] = course?['endDate']?.toString() ??
            map['endDate']?.toString() ??
            '';
        map['_code'] = code;
        regs.add(map);
      }

      regs.sort((a, b) {
        final s = (b['_paid'] == true ? 1 : 0) - (a['_paid'] == true ? 1 : 0);
        if (s != 0) return s;
        final ready = (a['_certificateStatus'] == 'NOT_GENERATED' ? 1 : 0) -
            (b['_certificateStatus'] == 'NOT_GENERATED' ? 1 : 0);
        return ready;
      });

      if (mounted) {
        setState(() {
          _registrations = regs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load certificate data';
          _loading = false;
        });
      }
    }
  }

  String _certificateStatus(Map<String, dynamic> reg) {
    final s =
        (reg['certificateStatus']?.toString() ?? 'NOT_GENERATED').toUpperCase();
    if (s.isEmpty) return 'NOT_GENERATED';
    return s;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _registrations;
    return _registrations.where((r) {
      final name = (r['_studentName'] ?? '').toString().toLowerCase();
      final code = (r['_code'] ?? '').toString().toLowerCase();
      final course = (r['_course'] ?? '').toString().toLowerCase();
      return name.contains(q) || code.contains(q) || course.contains(q);
    }).toList();
  }

  int _countWhere(bool Function(Map<String, dynamic>) test) =>
      _registrations.where(test).length;

  int get _paidCount => _countWhere((r) => r['_paid'] == true);
  int get _generatedCount =>
      _countWhere((r) => r['_certificateStatus'] != 'NOT_GENERATED');
  int get _pendingCount =>
      _countWhere((r) => r['_certificateStatus'] == 'NOT_GENERATED');

  Future<void> _openPreview(Map<String, dynamic> reg) async {
    final status = reg['_certificateStatus']?.toString() ?? 'NOT_GENERATED';
    final regId = reg['id']?.toString();

    // If the certificate record doesn't exist yet, create it first.
    if (status == 'NOT_GENERATED') {
      if (regId == null || regId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Registration ID not found'),
          backgroundColor: Colors.red.shade600,
        ));
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
            child: CircularProgressIndicator(color: _kGold)),
      );

      final result = await CertificateService.create(regId);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (result['success'] != true) {
        final msg = result['message']?.toString() ??
            'Failed to create certificate record';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade600,
        ));
        return;
      }

      reg['_certificateStatus'] = 'PENDING';
    }

    CertificateData data;
    try {
      data = CertificateData.fromCertificateJson(reg);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            const Text('Could not prepare certificate data for this student'),
        backgroundColor: Colors.red.shade600,
      ));
      return;
    }

    final name = reg['_studentName']?.toString() ?? '';
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CertificatePreviewScreen(
        data: data,
        fileName:
            '${name.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')}_certificate',
      ),
    ));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: _kIvory,
      appBar: AppBar(
        backgroundColor: _kIvory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _kInk, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Designer Studio',
            style: TextStyle(
                color: _kInk,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kGoldDark),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: _kGold,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
          children: [
            _buildHeroHeader(),
            _buildSummaryStrip(),
            _buildSearchBar(),
            const SizedBox(height: 8),
            ..._buildContent(filtered),
          ],
        ),
      ),
    );
  }

  // ── CONTENT (loading / error / empty / student list) ────────
  List<Widget> _buildContent(List<Map<String, dynamic>> filtered) {
    if (_loading) {
      return const [
        SizedBox(
          height: 220,
          child: Center(
              child: CircularProgressIndicator(
                  color: _kGold, strokeWidth: 2.5)),
        ),
      ];
    }
    if (_error != null) {
      return [
        SizedBox(
            height: 260,
            child: Center(
                child: _ErrorState(message: _error!, onRetry: _load))),
      ];
    }
    if (filtered.isEmpty) {
      return [
        SizedBox(
            height: 260,
            child: Center(
                child: _EmptyState(
                    hasData: _registrations.isNotEmpty, onRefresh: _load))),
      ];
    }
    return filtered.map((r) => _StudentCard(
        reg: r, onPreview: () => _openPreview(r))).toList();
  }

  // ── HERO HEADER ────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kGoldLight, _kGold, _kGoldDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: _kGold.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          const Text('Create Certificate',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4)),
          const SizedBox(height: 4),
          Text(
            'Design the official achievement certificate using the '
            'fixed gold template. Data is taken from the backend '
            'for every paid student.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.92),
                fontSize: 12.5,
                height: 1.45),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _heroChip(Icons.how_to_reg_rounded, 'Paid & Eligible', '$_paidCount'),
            const SizedBox(width: 8),
            _heroChip(Icons.check_circle_rounded, 'Ready', '$_pendingCount'),
            const SizedBox(width: 8),
            _heroChip(Icons.verified_rounded, 'Generated', '$_generatedCount'),
          ]),
        ],
      ),
    );
  }

  Widget _heroChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 3),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── SUMMARY STRIP ──────────────────────────────────────────
  Widget _buildSummaryStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        Expanded(
          child: _miniStat('Total Paid', '$_paidCount', _kGoldDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStat('Certificate Ready', '$_pendingCount', _kGold),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStat('Already Generated', '$_generatedCount', _kGreen),
        ),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGoldBorder.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                color: accent,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: _kInkSec, fontSize: 10.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ── SEARCH ──────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: _kInk, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search student name, roll number or course...',
          hintStyle: const TextStyle(color: _kInkHint, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: _kGoldDark),
          filled: true,
          fillColor: _kSurface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _kGoldBorder.withOpacity(0.8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kGold, width: 1.6),
          ),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  color: _kInkHint,
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {});
                  })
              : null,
        ),
      ),
    );
  }
}

// =============================================================
// STUDENT CARD
// =============================================================
class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> reg;
  final VoidCallback onPreview;

  const _StudentCard({required this.reg, required this.onPreview});

  bool get _paid => reg['_paid'] == true;
  String get _status => reg['_certificateStatus']?.toString() ?? 'NOT_GENERATED';
  String get _name => reg['_studentName']?.toString() ?? 'Student';
  String get _code => reg['_code']?.toString() ?? '';
  String get _course => reg['_course']?.toString() ?? '';
  String get _start => reg['_start']?.toString() ?? '';
  String get _end => reg['_end']?.toString() ?? '';

  String _fmt(String raw) {
    final s = truncate(raw, 10);
    final d = DateTime.tryParse(s);
    if (d == null) return s.isEmpty ? '—' : s;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _status == 'NOT_GENERATED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isReady ? _kGoldBorder : _kGoldBorder.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _kGold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kGoldBorder.withOpacity(0.7)),
              ),
              child: Text(
                _name.isEmpty ? '?' : _name[0].toUpperCase(),
                style: const TextStyle(
                    color: _kGoldDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _kInk,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(
                    'Roll No: ${_code.isEmpty ? '—' : _code}',
                    style: const TextStyle(
                        color: _kInkSec, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            _StatusChip(status: _status, paid: _paid),
          ]),

          const SizedBox(height: 14),
          Container(height: 1, color: _kGoldBorder.withOpacity(0.4)),

          // Course + dates
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.school_rounded, color: _kGoldDark, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _course.isEmpty ? 'Professional Development Program' : _course,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _kInk, fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _dateBlock(
                  Icons.event_available_rounded, 'START', _fmt(_start)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward_rounded,
                  color: _kGoldBorder, size: 15),
            ),
            Expanded(
              child: _dateBlock(Icons.event_available_rounded, 'END', _fmt(_end)),
            ),
          ]),
          const SizedBox(height: 16),

          // Action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _paid ? onPreview : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: const Color(0xFFFDF7E6),
                disabledBackgroundColor: _kSurfaceAlt,
                disabledForegroundColor: _kInkHint,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(
                  isReady
                      ? Icons.add_circle_outline_rounded
                      : Icons.visibility_outlined,
                  size: 18),
              label: Text(
                isReady ? 'Create & Preview Certificate' : 'View Certificate',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ),
          ),
          if (!_paid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 13, color: _kInkHint),
                  const SizedBox(width: 5),
                  const Text(
                    'Certificate available only after payment',
                    style: TextStyle(color: _kInkHint, fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _dateBlock(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: _kSurfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(icon, size: 15, color: _kGoldDark),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: _kInkSec, fontSize: 9.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 1),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _kInk, fontSize: 12.5, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ]),
    );
  }
}

// =============================================================
// STATUS CHIP
// =============================================================
class _StatusChip extends StatelessWidget {
  final String status;
  final bool paid;

  const _StatusChip({required this.status, required this.paid});

  (String, IconData, Color) get _style {
    switch (status) {
      case 'ISSUED':
        return ('ISSUED', Icons.verified_rounded, _kGreen);
      case 'GENERATED':
        return ('GENERATED', Icons.task_alt_rounded, _kGreen);
      case 'PENDING':
        return ('PENDING', Icons.hourglass_top_rounded, _kGold);
      default:
        return ('READY', Icons.auto_awesome_rounded, _kGoldDark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4)),
      ]),
    );
  }
}

// =============================================================
// EMPTY / ERROR STATES
// =============================================================
class _EmptyState extends StatelessWidget {
  final bool hasData;
  final VoidCallback onRefresh;
  const _EmptyState({required this.hasData, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            hasData ? Icons.search_off_rounded : Icons.workspace_premium_rounded,
            size: 64,
            color: _kGoldBorder,
          ),
          const SizedBox(height: 16),
          Text(
            hasData ? 'No students match your search' : 'No paid students yet',
            style: const TextStyle(
                color: _kInk, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            hasData
                ? 'Try a different name, roll number or course.'
                : 'Students appear here after their course payment is completed.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kInkSec, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRefresh,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kGoldDark,
              side: const BorderSide(color: _kGoldBorder),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, size: 64, color: _kGoldBorder),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _kInk, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGold,
              foregroundColor: const Color(0xFFFDF7E6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}
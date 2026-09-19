import 'dart:math' as math;
import 'package:flutter/material.dart';

// =============================================================
// FIXED CERTIFICATE TEMPLATE  —  pixel-approximate replica
// Scope   : MAVEPIZON TECHNOLOGIES "CERTIFICATE OF ACHIEVEMENT"
// Dynamic : studentName, rollNumber, program title,
//           startingDate, endingDate  (5 values only)
// Static  : EVERYTHING ELSE
// =============================================================

const Color _gold = Color(0xFFD4AF37);
const Color _goldLight = Color(0xFFF1D78C);
const Color _goldDeep = Color(0xFFB8860B);
const Color _goldBrown = Color(0xFFA96F00);
const Color _cream = Color(0xFFFBF4E1);
const Color _ink = Color(0xFF1E1A12);

const String _logoAsset = 'assets/images/Logo.png';
const String _gstNumber = 'GST Number : 33AATCM8396D1ZX';

const String _kPresentedTo = 'THIS CERTIFICATE IS PROUDLY PRESENTED TO';
const String _kCompletingLine = 'for successfully completing the';

const String _kDescriptionA =
    'This is to certify that the recipient has successfully completed '
    'the internship at Mavepizon Technologies.';
const String _kDescriptionB =
    'During this internship, the participant demonstrated dedication, '
    'technical proficiency, problem-solving abilities, and a strong '
    'commitment to learning and has gained valuable knowledge and skills.';

// =============================================================
// LOGO
//
// Logo.png already ships as the FULL brand lockup — the coloured
// ribbon mark PLUS the "MAVEPIZON / TECHNOLOGIES" wordmark baked
// into the image itself (see assets/images/Logo.png). So it is
// rendered directly, large and centred at the top of the
// certificate, with nothing else drawn next to or behind it — no
// separate "MAVEPIZON"/"TECHNOLOGIES" text, no white card — to
// match the reference certificate layout exactly.
// =============================================================

class _TransparentLogo extends StatelessWidget {
  final double width;
  final double height;

  const _TransparentLogo({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _logoAsset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: _gold.withOpacity(0.22),
          border: Border.all(color: _goldDeep, width: 1.4),
        ),
        child: const Icon(Icons.school_rounded, color: _goldBrown, size: 28),
      ),
    );
  }
}

// =============================================================
// DATA MODEL  (only 5 values are dynamic)
// =============================================================

class CertificateData {
  final String studentName;
  final String rollNumber;
  final String program;
  final String startingDate;
  final String endingDate;
  final String recordType;

  const CertificateData({
    required this.studentName,
    required this.rollNumber,
    required this.program,
    required this.startingDate,
    required this.endingDate,
    this.recordType = 'COURSE',
  });

  /// Supports BOTH shapes returned by the backend:
  ///  - flat DTO  : studentName / studentCode / courseName / startDate / endDate
  ///  - nested    : student{name,studentId} / course{courseName,startDate,endDate}
  factory CertificateData.fromCertificateJson(Map<String, dynamic> j) {
    String safe(dynamic v) {
      if (v == null) return '';
      return v.toString().trim();
    }

    final nestedStudent =
        j['student'] is Map ? Map<String, dynamic>.from(j['student']) : null;
    final nestedCourse =
        j['course'] is Map ? Map<String, dynamic>.from(j['course']) : null;

    final studentName = safe(j['studentName']).isNotEmpty
        ? safe(j['studentName'])
        : safe(nestedStudent?['name']);

    final rollNumber = safe(j['studentCode']).isNotEmpty
        ? safe(j['studentCode'])
        : safe(nestedStudent?['studentId']);

    final program = safe(j['courseName']).isNotEmpty
        ? safe(j['courseName'])
        : safe(j['internshipName']).isNotEmpty
            ? safe(j['internshipName'])
            : safe(nestedCourse?['courseName']).isNotEmpty
                ? safe(nestedCourse?['courseName'])
                : safe(j['courseOrInternshipName']);

    var recordType = safe(j['recordType']).isNotEmpty
        ? safe(j['recordType'])
        : safe(j['type']).isNotEmpty
            ? safe(j['type'])
            : 'COURSE';

    if (safe(j['internshipName']).isNotEmpty || j['internship'] is Map) {
      recordType = 'INTERNSHIP';
    }

    String fmt(dynamic raw) {
      final s = safe(raw);
      if (s.isEmpty) return '';
      final parsed =
          DateTime.tryParse(s.length >= 10 ? s.substring(0, 10) : s);
      if (parsed == null) return s;
      final dd = parsed.day.toString().padLeft(2, '0');
      final mm = parsed.month.toString().padLeft(2, '0');
      return '$dd/$mm/${parsed.year}';
    }

    return CertificateData(
      studentName: studentName,
      rollNumber: rollNumber,
      program: program,
      recordType: recordType,
      startingDate: fmt(
        j['startingDate'] ??
            j['startDate'] ??
            nestedCourse?['startDate'] ??
            j['registrationDate'],
      ),
      endingDate: fmt(
        j['endingDate'] ??
            j['endDate'] ??
            nestedCourse?['endDate'] ??
            j['issueDate'],
      ),
    );
  }

  /// Program line as it appears on the certificate.
  /// Internship -> "Internship in <title>"
  /// Course     -> "<course title>"
  String get programText {
    final p = program.trim();
    if (p.isEmpty) return '';
    final isInternship = recordType.toUpperCase() == 'INTERNSHIP';
    final prefixed = p.toLowerCase().startsWith('internship in');
    if (isInternship && !prefixed) return 'Internship in $p';
    return p;
  }
}

// =============================================================
// CERTIFICATE TEMPLATE VIEW  (FIXED LAYOUT)
// =============================================================

class CertificateTemplateView extends StatelessWidget {
  final CertificateData data;

  // Fixed canvas size (16:9-like wide landscape)
  static const double templateWidth = 1200;
  static const double templateHeight = 820;

  const CertificateTemplateView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: templateWidth,
      height: templateHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _CertificateFramePainter()),
          Padding(
            padding: const EdgeInsets.fromLTRB(80, 34, 80, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 10),
                _buildTitle(),
                const SizedBox(height: 10),
                _buildPresentedTo(),
                const SizedBox(height: 6),
                _buildStudentName(),
                const SizedBox(height: 8),
                _buildNameDivider(),
                const SizedBox(height: 8),
                _buildRollNumber(),
                const SizedBox(height: 10),
                _buildCompletingLine(),
                const SizedBox(height: 6),
                _buildProgramLine(),
                const SizedBox(height: 14),
                _buildDescription(),
                const Spacer(),
                _buildFooterRow(),
              ],
            ),
          ),
          const Positioned(top: 34, right: 58, child: _CertificateSeal()),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // HEADER — the Logo.png asset already contains the full
  // "MAVEPIZON / TECHNOLOGIES" wordmark baked into the image, so
  // it's rendered large and centred on its own (no extra text,
  // no card background) — exactly matching the reference
  // certificate — followed by the GST line with ornaments.
  // ---------------------------------------------------------
  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Center(
          child: _TransparentLogo(width: 460, height: 96),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Expanded(child: _OrnamentalLine()),
            SizedBox(width: 14),
            Text(
              _gstNumber,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _ink,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(width: 14),
            Expanded(child: _OrnamentalLine()),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // TITLE — cursive "Certificate" + dark "OF ACHIEVEMENT"
  // ---------------------------------------------------------
  Widget _buildTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_goldLight, _gold, _goldBrown],
          ).createShader(bounds),
          child: const Text(
            'Certificate',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'serif',
              fontStyle: FontStyle.italic,
              fontSize: 54,
              fontWeight: FontWeight.w600,
              color: _gold,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Expanded(child: _OrnamentalLine()),
            SizedBox(width: 12),
            Text(
              'OF ACHIEVEMENT',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: 7,
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: _OrnamentalLine()),
          ],
        ),
        const SizedBox(height: 8),
        const _Flourish(),
      ],
    );
  }

  // ---------------------------------------------------------
  // PRESENTED TO (static)
  // ---------------------------------------------------------
  Widget _buildPresentedTo() {
    return const Text(
      _kPresentedTo,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'serif',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _ink,
        letterSpacing: 3.4,
      ),
    );
  }

  // ---------------------------------------------------------
  // DYNAMIC VALUE 1 — STUDENT NAME
  // ---------------------------------------------------------
  Widget _buildStudentName() {
    return Text(
      data.studentName.isEmpty
          ? 'STUDENT NAME'
          : data.studentName.toUpperCase(),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.visible,
      style: const TextStyle(
        fontFamily: 'serif',
        fontSize: 46,
        fontWeight: FontWeight.w800,
        color: _goldBrown,
        letterSpacing: 6,
        height: 1.1,
      ),
    );
  }

  // ---------------------------------------------------------
  // THIN DIVIDER LINE — sits BETWEEN name and roll number
  // ---------------------------------------------------------
  Widget _buildNameDivider() {
    return Center(
      child: Container(
        width: 420,
        height: 1.4,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.transparent, _gold, _goldDeep, _gold, Colors.transparent],
          ),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // DYNAMIC VALUE 2 — ROLL NUMBER
  // ---------------------------------------------------------
  Widget _buildRollNumber() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Flexible(
          child: Text(
            'Roll Number : ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
        ),
        Text(
          data.rollNumber.isEmpty ? '--------' : data.rollNumber,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _goldBrown,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // "for successfully completing the" (static)
  // ---------------------------------------------------------
  Widget _buildCompletingLine() {
    return const Text(
      _kCompletingLine,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'serif',
        fontSize: 17,
        color: _ink,
      ),
    );
  }

  // ---------------------------------------------------------
  // DYNAMIC VALUE 3 — PROGRAM TITLE (short arrow-dash ornaments,
  // NOT full-width lines — matches reference image)
  // ---------------------------------------------------------
  Widget _buildProgramLine() {
    final text = data.programText.isEmpty
        ? 'Professional Development Program'
        : data.programText;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _diamond(),
        const _ShortArrowLine(),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: const TextStyle(
              fontFamily: 'serif',
              fontStyle: FontStyle.italic,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _goldBrown,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const _ShortArrowLine(reversed: true),
        _diamond(),
      ],
    );
  }

  // ---------------------------------------------------------
  // STATIC DESCRIPTION PARAGRAPH (exact, never fetched)
  // ---------------------------------------------------------
  Widget _buildDescription() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          _kDescriptionA,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 14.5,
            height: 1.45,
            color: _ink,
          ),
        ),
        SizedBox(height: 4),
        Text(
          _kDescriptionB,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 14.5,
            height: 1.45,
            color: _ink,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // FOOTER — single row: [Dates block] | [Mentor sig] | [MD sig]
  // matches the reference image layout exactly
  // ---------------------------------------------------------
  Widget _buildFooterRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 4, child: _buildDatesBlock()),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: _VerticalOrnament(),
          ),
          Expanded(
            flex: 3,
            child: _buildSignature('SIGNATURE OF MENTOR'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: _VerticalOrnament(),
          ),
          Expanded(
            flex: 3,
            child: _buildSignature('SIGNATURE OF\nMANAGING DIRECTOR'),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesBlock() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _CalendarIcon(),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _dateLine('STARTING DATE', data.startingDate),
            const SizedBox(height: 6),
            _dateLine('ENDING DATE', data.endingDate),
          ],
        ),
      ],
    );
  }

  Widget _dateLine(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          value.isEmpty ? '- - -' : value,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _goldBrown,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildSignature(String label) {
    return Text(
      label.toUpperCase(),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: _ink,
        letterSpacing: 1.0,
        height: 1.35,
      ),
    );
  }

  Widget _diamond() {
    return Transform.rotate(
      angle: 0.7853981633974483,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: _gold,
          border: Border.all(color: _goldDeep, width: 1),
        ),
      ),
    );
  }
}

// =============================================================
// DECORATIVE STATIC PARTS
// =============================================================

/// Short arrow-headed line segment used beside the program title,
/// e.g.  ◆────➤  text  ➤────◆   (matches reference image, NOT a
/// full-width expanded line).
class _ShortArrowLine extends StatelessWidget {
  final bool reversed;
  const _ShortArrowLine({this.reversed = false});

  @override
  Widget build(BuildContext context) {
    final line = Container(
      width: 46,
      height: 1.6,
      color: _goldDeep,
    );
    final arrow = Icon(
      reversed ? Icons.arrow_left : Icons.arrow_right,
      size: 14,
      color: _goldDeep,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: reversed ? [arrow, line] : [line, arrow],
    );
  }
}

class _OrnamentalLine extends StatelessWidget {
  const _OrnamentalLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _gold, _goldDeep, _gold],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Transform.rotate(
          angle: 0.7853981633974483,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _gold,
              border: Border.all(color: _goldDeep, width: 1),
            ),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}

class _Flourish extends StatelessWidget {
  const _Flourish();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 18,
      child: CustomPaint(painter: _FlourishPainter()),
    );
  }
}

class _FlourishPainter extends CustomPainter {
  const _FlourishPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = _gold
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCenter(center: center.translate(-22, 0), width: 34, height: 20),
      3.6,
      3.1,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: center.translate(22, 0), width: 34, height: 20),
      3.5,
      3.1,
      false,
      paint,
    );
    canvas.drawCircle(center, 2.6, Paint()..color = _goldDeep);
    canvas.drawLine(
      center.translate(-8, 0),
      center.translate(8, 0),
      Paint()
        ..color = _gold
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_FlourishPainter oldDelegate) => false;
}

class _CalendarIcon extends StatelessWidget {
  const _CalendarIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_goldLight, _gold, _goldDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: _gold.withOpacity(0.4),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child:
          const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 16),
    );
  }
}

class _VerticalOrnament extends StatelessWidget {
  const _VerticalOrnament();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1.4, color: _gold);
  }
}

// =============================================================
// SEAL — medal at top-right with sunburst rays, curved lettering
// and ribbon tails attached directly under the ring (matches the
// reference certificate's badge more closely than a plain circle).
// =============================================================

class _CertificateSeal extends StatelessWidget {
  const _CertificateSeal();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 214,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 168,
            height: 168,
            child: CustomPaint(painter: _SealPainter()),
          ),
          // Ribbon tails sit flush under the medal, not floating below it.
          Transform.translate(
            offset: const Offset(0, -22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _SealRibbonTail(flip: false),
                SizedBox(width: 2),
                _SealRibbonTail(flip: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SealRibbonTail extends StatelessWidget {
  final bool flip;
  const _SealRibbonTail({required this.flip});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 56,
      child: CustomPaint(painter: _SealRibbonTailPainter(flip: flip)),
    );
  }
}

class _SealRibbonTailPainter extends CustomPainter {
  final bool flip;
  const _SealRibbonTailPainter({required this.flip});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_goldLight, _gold, _goldDeep],
      ).createShader(Offset.zero & size);

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height * 0.62)
      ..lineTo(size.width / 2, size.height * 0.8)
      ..lineTo(size.width, size.height * 0.62)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _goldDeep,
    );
  }

  @override
  bool shouldRepaint(_SealRibbonTailPainter oldDelegate) => false;
}

class _SealPainter extends CustomPainter {
  const _SealPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerR = size.width / 2 - 8;
    final innerR = outerR - 14;

    final goldPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_goldLight, _gold, _goldDeep],
      ).createShader(Rect.fromCircle(center: center, radius: outerR));

    // outer plain ring (badge base)
    canvas.drawCircle(center, outerR, goldPaint);
    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _goldDeep,
    );

    // sunburst rays radiating just outside the ring
    final rayPaint = Paint()
      ..color = _goldDeep.withOpacity(0.55)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    const rayCount = 40;
    for (var i = 0; i < rayCount; i++) {
      final a = i * (2 * math.pi / rayCount);
      final p0 = Offset(center.dx + outerR * 1.0 * math.cos(a),
          center.dy + outerR * 1.0 * math.sin(a));
      final p1 = Offset(center.dx + outerR * 1.09 * math.cos(a),
          center.dy + outerR * 1.09 * math.sin(a));
      canvas.drawLine(p0, p1, rayPaint);
    }

    // inner cream disc
    canvas.drawCircle(center, innerR, Paint()..color = _cream);
    canvas.drawCircle(
      center,
      innerR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = _goldDeep,
    );
    canvas.drawCircle(
      center,
      innerR - 7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _gold,
    );

    // stars top & bottom
    _drawStar(canvas, Offset(center.dx, center.dy - innerR + 20), 5.5, _goldBrown);
    _drawStar(canvas, Offset(center.dx, center.dy + innerR - 20), 5.5, _goldBrown);

    // laurel wreath (left + right arcs of leaves)
    final leafPaint = Paint()
      ..color = _goldBrown
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final laurelR = innerR - 24;
    for (var i = 0; i < 6; i++) {
      final t = i / 5.0;
      final a0 = -2.6 + t * 2.2;
      final a1 = -2.5 + t * 2.2;
      final p0 = Offset(center.dx + laurelR * math.cos((-a0)),
          center.dy + laurelR * math.sin((-a0)));
      final p1 = Offset(center.dx + laurelR * math.cos((-a1)) - 9,
          center.dy + laurelR * math.sin((-a1)) - 9);
      canvas.drawLine(p0, p1, leafPaint);
      final q0 = Offset(center.dx + laurelR * math.cos(a0),
          center.dy + laurelR * math.sin(a0));
      final q1 = Offset(center.dx + laurelR * math.cos(a1) + 9,
          center.dy + laurelR * math.sin(a1) + 9);
      canvas.drawLine(q0, q1, leafPaint);
    }

    // curved lettering along the top and bottom of the inner disc,
    // with "OF" sitting straight in the middle — matches the badge
    // text arrangement in the reference certificate.
    const arcTextStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: _goldBrown,
      letterSpacing: 1.0,
    );
    _paintArcText(
      canvas,
      'CERTIFICATE',
      center,
      innerR - 19,
      -2.15,
      1.30,
      arcTextStyle,
    );
    _paintArcText(
      canvas,
      'ACHIEVEMENT',
      center,
      innerR - 19,
      0.85,
      1.30,
      arcTextStyle,
      flipUpright: true,
    );

    final ofTp = TextPainter(
      text: const TextSpan(
        text: 'OF',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _goldBrown,
          letterSpacing: 2.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    ofTp.paint(canvas, Offset(center.dx - ofTp.width / 2, center.dy - ofTp.height / 2));
  }

  /// Draws [text] curved along an arc of the given [radius], centred on
  /// [center], starting at [startAngle] (radians, 0 = 3 o'clock,
  /// increasing clockwise) and sweeping [sweep] radians.
  /// Pass [flipUpright] for arcs on the bottom half of the circle so the
  /// letters don't render upside-down.
  void _paintArcText(
    Canvas canvas,
    String text,
    Offset center,
    double radius,
    double startAngle,
    double sweep,
    TextStyle style, {
    bool flipUpright = false,
  }) {
    final n = text.length;
    for (var i = 0; i < n; i++) {
      // For arcs on the bottom half (flipUpright), the letters must be
      // placed in reverse sweep order — otherwise the upright rotation
      // correction makes the word read backwards (mirrored).
      final rawT = n == 1 ? 0.5 : i / (n - 1);
      final t = flipUpright ? 1 - rawT : rawT;
      final theta = startAngle + sweep * t;
      final tp = TextPainter(
        text: TextSpan(text: text[i], style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = center.dx + radius * math.cos(theta);
      final y = center.dy + radius * math.sin(theta);
      canvas.save();
      canvas.translate(x, y);
      var rotation = theta + math.pi / 2;
      if (flipUpright) rotation += math.pi;
      canvas.rotate(rotation);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    const n = 5;
    for (var i = 0; i < n * 2; i++) {
      final rad = i.isEven ? r : r * 0.42;
      final a = (i * 3.141592653589793 / n) - 1.5707963267948966;
      final p = Offset(c.dx + rad * math.cos(a), c.dy + rad * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SealPainter oldDelegate) => false;
}

// =============================================================
// FRAME — background, double golden border, corner ornaments,
// and the curved golden ribbons (confined to the left and
// bottom-right corners so the centre stays clean and readable)
// =============================================================

class _CertificateFramePainter extends CustomPainter {
  const _CertificateFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    // background
    canvas.drawRect(bounds, Paint()..color = _cream);

    canvas.save();
    canvas.clipRect(bounds);

    // left curved golden ribbon band (clipped to the left half only)
    _paintLeftRibbon(canvas, size);
    // bottom-right curved golden ribbon band (clipped to the right half)
    _paintBottomRightRibbon(canvas, size);

    canvas.restore();

    // outer border
    final outerRect = RRect.fromRectAndRadius(
      bounds.deflate(12),
      const Radius.circular(22),
    );
    final outerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_goldLight, _gold, _goldDeep],
      ).createShader(bounds)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawRRect(outerRect, outerPaint);

    // inner double line — drawn in a darker gold so it stays visible
    // against the ivory background and the ribbon bands underneath.
    final innerRect = RRect.fromRectAndRadius(
      bounds.deflate(22),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      innerRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = _goldDeep,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds.deflate(26), const Radius.circular(14)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = _goldDeep.withOpacity(0.75),
    );

    // corner floral ornaments
    _paintCornerOrnament(canvas, innerRect.safeInnerTopLeft(bounds),
        flipX: false, flipY: false);
    _paintCornerOrnament(canvas, innerRect.safeInnerTopRight(bounds),
        flipX: true, flipY: false);
    _paintCornerOrnament(canvas, innerRect.safeInnerBottomLeft(bounds),
        flipX: false, flipY: true);
    _paintCornerOrnament(canvas, innerRect.safeInnerBottomRight(bounds),
        flipX: true, flipY: true);
  }

  /// Draws one flowing diagonal ribbon band (a thick rounded stroke
  /// along p1→p2) with a gold gradient, a soft edge highlight and a
  /// dark outline — this is the reusable building block for the
  /// corner ribbon sashes seen in the reference image.
  void _drawSashBand(
    Canvas canvas,
    Offset p1,
    Offset p2,
    double width, {
    double highlightOpacity = 0.4,
  }) {
    final rect = Rect.fromPoints(p1, p2).inflate(width);
    final basePaint = Paint()
      ..shader = const LinearGradient(
        colors: [_goldDeep, _gold, _goldLight, _gold, _goldDeep],
        stops: [0.0, 0.28, 0.5, 0.72, 1.0],
      ).createShader(rect)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;
    canvas.drawLine(p1, p2, basePaint);

    // thin darker outline on both edges for a folded-ribbon feel
    canvas.drawLine(
      p1,
      p2,
      Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.butt
        ..style = PaintingStyle.stroke
        ..color = _goldDeep.withOpacity(0.3),
    );

    // bright highlight stripe running along the middle of the band
    canvas.drawLine(
      p1,
      p2,
      Paint()
        ..strokeWidth = width * 0.2
        ..strokeCap = StrokeCap.butt
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withOpacity(highlightOpacity)
        ..blendMode = BlendMode.overlay,
    );

    canvas.drawLine(
      p1,
      p2,
      Paint()
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke
        ..color = _goldDeep.withOpacity(0.55),
    );
  }

  // Slim gold sash tucked along the left edge — kept to roughly the
  // left quarter of the canvas so it frames the card without ever
  // crossing into the centred title, name or description text.
  void _paintLeftRibbon(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w * 0.26, h));

    _drawSashBand(
      canvas,
      Offset(w * 0.015, -h * 0.05),
      Offset(w * 0.17, h * 1.04),
      w * 0.05,
    );
    _drawSashBand(
      canvas,
      Offset(-w * 0.025, h * 0.04),
      Offset(w * 0.10, h * 1.06),
      w * 0.028,
      highlightOpacity: 0.25,
    );

    canvas.restore();
  }

  // Small mirrored gold accent tucked into the bottom-right corner only
  // — clipped tightly so it never reaches up into the signature row.
  void _paintBottomRightRibbon(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(w * 0.80, h * 0.72, w * 0.20, h * 0.28));

    _drawSashBand(
      canvas,
      Offset(w * 1.02, h * 0.76),
      Offset(w * 0.78, h * 1.04),
      w * 0.045,
    );
    _drawSashBand(
      canvas,
      Offset(w * 1.03, h * 0.85),
      Offset(w * 0.84, h * 1.05),
      w * 0.026,
      highlightOpacity: 0.25,
    );

    canvas.restore();
  }

  void _paintCornerOrnament(
    Canvas canvas,
    Offset corner, {
    required bool flipX,
    required bool flipY,
  }) {
    canvas.save();
    canvas.translate(corner.dx, corner.dy);
    if (flipX) canvas.scale(-1, 1);
    if (flipY) canvas.scale(1, -1);

    final fill = Paint()..color = _gold;

    // main sweeping curve — bigger + a secondary echo curve so the
    // filigree reads clearly against the ivory background/ribbons.
    final curve = Path()
      ..moveTo(0, 46)
      ..cubicTo(19, 36, 42, 16, 46, 0);
    canvas.drawPath(
      curve,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..color = _goldDeep,
    );

    final curve2 = Path()
      ..moveTo(6, 34)
      ..cubicTo(18, 28, 28, 18, 34, 6);
    canvas.drawPath(
      curve2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = _gold,
    );

    // leaf clusters
    final leaf1 = Path()
      ..moveTo(6, 30)
      ..cubicTo(13, 24, 21, 25, 22, 33)
      ..cubicTo(16, 37, 8, 37, 6, 30);
    canvas.drawPath(leaf1, Paint()..color = _goldDeep);

    final leaf2 = Path()
      ..moveTo(30, 6)
      ..cubicTo(36, 13, 34, 21, 27, 22)
      ..cubicTo(22, 16, 22, 8, 30, 6);
    canvas.drawPath(leaf2, Paint()..color = _goldDeep.withOpacity(0.9));

    // dots
    canvas.drawCircle(const Offset(10, 31), 2.4, fill);
    canvas.drawCircle(const Offset(31, 10), 2.1, fill);
    canvas.drawCircle(const Offset(46, 0), 2.8, fill);
    canvas.drawCircle(const Offset(0, 46), 2.8, fill);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CertificateFramePainter oldDelegate) => false;
}

extension _RRectHelper on RRect {
  Offset safeInnerTopLeft(Rect bounds) => Offset(left, top);
  Offset safeInnerTopRight(Rect bounds) => Offset(right, top);
  Offset safeInnerBottomLeft(Rect bounds) => Offset(left, bottom);
  Offset safeInnerBottomRight(Rect bounds) => Offset(right, bottom);
}
import 'package:flutter/material.dart';

// =============================================================
// PROFESSIONAL CERTIFICATE TEMPLATE — clean corporate style
// Scope   : MAVEPIZON TECHNOLOGIES "CERTIFICATE OF ACHIEVEMENT"
// Dynamic : studentName, rollNumber, program title,
//           startingDate, endingDate  (5 values only)
// Static  : EVERYTHING ELSE
// =============================================================

// ----- palette: navy + gold on a clean off-white card -----
const Color _navy = Color(0xFF16243D);
const Color _navySoft = Color(0xFF3B4A64);
const Color _gold = Color(0xFFB8912F);
const Color _goldLight = Color(0xFFD8B65C);
const Color _paper = Color(0xFFFFFFFF);
const Color _hairline = Color(0xFFE3DED0);
const Color _bodyText = Color(0xFF4A4A4A);

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
// LOGO — Logo.png already ships as the full brand lockup, so it
// is rendered on its own, centred, with nothing else drawn next
// to it.
// =============================================================

class _Logo extends StatelessWidget {
  final double width;
  final double height;
  const _Logo({required this.width, required this.height});

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
          border: Border.all(color: _gold, width: 1.2),
        ),
        child: const Icon(Icons.school_rounded, color: _navy, size: 26),
      ),
    );
  }
}

// =============================================================
// DATA MODEL  (only 5 values are dynamic) — unchanged shape, so
// this file is a drop-in replacement wherever CertificateData /
// CertificateTemplateView are used elsewhere in the app.
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
// CERTIFICATE TEMPLATE VIEW — professional / corporate layout
//
// Everything sits on a single centred vertical axis (a strict
// Column with mainAxisAlignment.center children), so every line
// lines up on the same centre-line from the logo down to the
// footer. No diagonal ribbons, no gradients on the border — just
// a clean double hairline frame, generous whitespace, and one
// accent colour (gold) used sparingly for rules and key words.
// =============================================================

class CertificateTemplateView extends StatelessWidget {
  final CertificateData data;

  static const double templateWidth = 1200;
  static const double templateHeight = 820;

  const CertificateTemplateView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: templateWidth,
      height: templateHeight,
      color: _paper,
      padding: const EdgeInsets.all(28),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: _navy, width: 1.6),
        ),
        padding: const EdgeInsets.all(6),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _gold, width: 1.1),
          ),
          padding: const EdgeInsets.fromLTRB(70, 42, 70, 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 22),
              _buildTitle(),
              const SizedBox(height: 22),
              _buildPresentedTo(),
              const SizedBox(height: 10),
              _buildStudentName(),
              const SizedBox(height: 10),
              _buildRollNumber(),
              const SizedBox(height: 20),
              _buildCompletingLine(),
              const SizedBox(height: 8),
              _buildProgramLine(),
              const SizedBox(height: 22),
              _buildDescription(),
              const Spacer(),
              _buildFooterRow(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // HEADER — logo centred, GST line centred underneath a single
  // thin gold hairline (full width, no ornaments).
  // ---------------------------------------------------------
  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _Logo(width: 300, height: 68),
        const SizedBox(height: 14),
        Container(height: 1, width: 340, color: _hairline),
        const SizedBox(height: 8),
        const Text(
          _gstNumber,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _navySoft,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // TITLE — plain, confident, all-caps serif in navy with a
  // short gold rule beneath it. No script font, no shader.
  // ---------------------------------------------------------
  Widget _buildTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          'CERTIFICATE OF ACHIEVEMENT',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: _navy,
            letterSpacing: 3.2,
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          width: 90,
          child: Divider(color: _gold, thickness: 2, height: 2),
        ),
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
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _navySoft,
        letterSpacing: 2.6,
      ),
    );
  }

  // ---------------------------------------------------------
  // DYNAMIC VALUE 1 — STUDENT NAME, with a clean underline that
  // matches the text width rather than a fixed-width divider.
  // ---------------------------------------------------------
  Widget _buildStudentName() {
    final name =
        data.studentName.isEmpty ? 'STUDENT NAME' : data.studentName;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: const TextStyle(
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
            fontSize: 42,
            fontWeight: FontWeight.w600,
            color: _navy,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Container(height: 1.4, width: 300, color: _gold),
      ],
    );
  }

  // ---------------------------------------------------------
  // DYNAMIC VALUE 2 — ROLL NUMBER
  // ---------------------------------------------------------
  Widget _buildRollNumber() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _bodyText,
        ),
        children: [
          const TextSpan(text: 'Roll Number:  '),
          TextSpan(
            text: data.rollNumber.isEmpty ? '--------' : data.rollNumber,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _navy,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // "for successfully completing the" (static)
  // ---------------------------------------------------------
  Widget _buildCompletingLine() {
    return const Text(
      _kCompletingLine,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 15, color: _bodyText),
    );
  }

  // ---------------------------------------------------------
  // DYNAMIC VALUE 3 — PROGRAM TITLE
  // ---------------------------------------------------------
  Widget _buildProgramLine() {
    final text = data.programText.isEmpty
        ? 'Professional Development Program'
        : data.programText;
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: const TextStyle(
        fontFamily: 'serif',
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: _gold,
      ),
    );
  }

  // ---------------------------------------------------------
  // STATIC DESCRIPTION PARAGRAPH
  // ---------------------------------------------------------
  Widget _buildDescription() {
    return SizedBox(
      width: 760,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            _kDescriptionA,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, height: 1.5, color: _bodyText),
          ),
          SizedBox(height: 4),
          Text(
            _kDescriptionB,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, height: 1.5, color: _bodyText),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // FOOTER — three equal columns, each capped with a thin
  // hairline above its label, so dates and both signatures sit
  // on exactly the same baseline.
  // ---------------------------------------------------------
  Widget _buildFooterRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildDatesColumn()),
        _buildSignatureColumn('Signature of Mentor'),
        _buildSignatureColumn('Signature of\nManaging Director'),
      ],
    );
  }

  Widget _buildDatesColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 1, width: 150, color: _navy),
        const SizedBox(height: 8),
        _dateLine('STARTING DATE', data.startingDate),
        const SizedBox(height: 8),
        _dateLine('ENDING DATE', data.endingDate),
      ],
    );
  }

  Widget _dateLine(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: _navySoft,
          letterSpacing: 0.8,
        ),
        children: [
          TextSpan(text: '$label   '),
          TextSpan(
            text: value.isEmpty ? '—' : value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _navy,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureColumn(String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, width: 150, color: _navy),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _navySoft,
              letterSpacing: 0.6,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
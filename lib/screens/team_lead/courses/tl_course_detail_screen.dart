import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/course_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/status_badge.dart';

class TlCourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;
  const TlCourseDetailScreen({super.key, required this.courseId});
  @override
  ConsumerState<TlCourseDetailScreen> createState() => _TlCourseDetailScreenState();
}

class _TlCourseDetailScreenState extends ConsumerState<TlCourseDetailScreen> {
  dynamic _course;

  // initState is enough. Refresh happens via .then() after push.
  void _refreshCourse() {
    if (!mounted) return;
    final prov = ref.read(courseProvider.notifier);

    // Use try-catch instead of orElse: null
    // because CourseModel is non-nullable so orElse: () => null won't compile
    try {
      final updated = ref.read(courseProvider).list.firstWhere((c) => c.id == widget.courseId);
      setState(() => _course = updated);
    } catch (_) {
      // Not in cache � fetch from server
      prov.fetch().then((_) {
        if (!mounted) return;
        try {
          final found = ref.read(courseProvider).list.firstWhere((c) => c.id == widget.courseId);
          setState(() => _course = found);
        } catch (_) {
          // Course deleted � go back
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshCourse();
  }

  Future<void> _toggleStatus() async {
    final s = _course.status == 'OPEN' ? 'CLOSED' : 'OPEN';
    await ref.read(courseProvider.notifier).toggleStatus(widget.courseId, s);
    _refreshCourse();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Course'),
        content: const Text('This will permanently delete this course.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(courseProvider.notifier).delete(widget.courseId);
      if (mounted) Navigator.pop(context);
    }
  }

  void _edit() {
    Navigator.pushNamed(
      context,
      AppRoutes.tlEditCourse,
      arguments: {'courseId': widget.courseId},
    ).then((_) => _refreshCourse());
  }

  @override
  Widget build(BuildContext context) {
    if (_course == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 8, 20, 28),
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20))),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.more_vert_rounded,
                          color: Colors.white, size: 20)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) {
                    if (v == 'edit') _edit();
                    if (v == 'toggle') _toggleStatus();
                    if (v == 'delete') _delete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_rounded,
                            color: AppColors.accent, size: 18),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ]),
                    ),
                    PopupMenuItem(
                        value: 'toggle',
                        child: Text(_course.status == 'OPEN'
                            ? 'Close Course'
                            : 'Open Course')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ]),
              const SizedBox(height: 20),
              StatusBadge(status: _course.status),
              const SizedBox(height: 8),
              Text(_course.courseName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(_course.courseCode,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 13)),
              const SizedBox(height: 14),
              Text('?${_course.totalFees.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900)),
              Text(
                  'Registration: ?${_course.registrationFees.toStringAsFixed(0)}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.65), fontSize: 12)),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
              delegate: SliverChildListDelegate([
            Row(children: [
              _SeatCard('Online', _course.availableSeatsOnline,
                  _course.totalSeatsOnline, AppColors.card1),
              const SizedBox(width: 12),
              _SeatCard('Offline', _course.availableSeatsOffline,
                  _course.totalSeatsOffline, AppColors.card3),
            ]),
            const SizedBox(height: 20),
            _InfoCard(context, 'Details', [
              _row(context, Icons.timer_rounded, 'Duration', _course.duration),
              _row(context, Icons.group_rounded, 'Batch ID', _course.batchId),
              _row(context, 
                  Icons.calendar_today_rounded,
                  'Start',
                  _course.startDate.length >= 10
                      ? _course.startDate.substring(0, 10)
                      : _course.startDate),
              _row(context, 
                  Icons.event_rounded,
                  'End',
                  _course.endDate.length >= 10
                      ? _course.endDate.substring(0, 10)
                      : _course.endDate),
              if (_course.zoomLink != null && _course.zoomLink!.isNotEmpty)
                _row(context, Icons.link_rounded, 'Zoom Link', _course.zoomLink!),
            ]),
            const SizedBox(height: 16),
            if (_course.description.isNotEmpty)
              _InfoCard(context, 'Description', [
                Text(_course.description,
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSec(context),
                        height: 1.5)),
              ]),
            const SizedBox(height: 24),
          ])),
        ),
      ]),
    );
  }
}

Widget _SeatCard(String label, int available, int total, Color color) =>
    Expanded(
        child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        Text('$available/$total',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 2),
        Text('$label Seats',
            style:
                TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
      ]),
    ));

Widget _InfoCard(BuildContext context, String title, List<Widget> children) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPri(context))),
        const SizedBox(height: 16),
        ...children,
      ]),
    );

Widget _row(BuildContext context, IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(children: [
      Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.accent, size: 18)),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: AppColors.textHi(context))),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPri(context))),
      ])),
    ]));

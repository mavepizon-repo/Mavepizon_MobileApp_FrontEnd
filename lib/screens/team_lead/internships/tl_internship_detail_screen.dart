import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/internship_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/status_badge.dart';

class TlInternshipDetailScreen extends ConsumerStatefulWidget {
  final String internshipId;
  const TlInternshipDetailScreen({super.key, required this.internshipId});
  @override
  ConsumerState<TlInternshipDetailScreen> createState() =>
      _TlInternshipDetailScreenState();
}

class _TlInternshipDetailScreenState extends ConsumerState<TlInternshipDetailScreen> {
  dynamic _intern;

  // ? FIX: Removed didChangeDependencies � caused infinite fetch loop.
  // ? FIX: Use try-catch instead of orElse: null
  // because InternshipModel is non-nullable so orElse: () => null won't compile
  void _refreshInternship() {
    if (!mounted) return;
    final prov = ref.read(internshipProvider.notifier);
    try {
      final updated = ref.read(internshipProvider).list.firstWhere((i) => i.id == widget.internshipId);
      setState(() => _intern = updated);
    } catch (_) {
      prov.fetch().then((_) {
        if (!mounted) return;
        try {
          final found =
              ref.read(internshipProvider).list.firstWhere((i) => i.id == widget.internshipId);
          setState(() => _intern = found);
        } catch (_) {
          // Internship deleted � go back
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshInternship();
  }

  Future<void> _toggleStatus() async {
    final s = _intern.status.toUpperCase() == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    // ? FIX: Use toggleStatus instead of update � correct method
    await ref
        .read(internshipProvider.notifier)
        .toggleStatus(widget.internshipId, s);
    _refreshInternship();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Internship'),
        content: const Text('Delete this internship permanently?'),
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
      await ref.read(internshipProvider.notifier).delete(widget.internshipId);
      if (mounted) Navigator.pop(context);
    }
  }

  void _edit() {
    Navigator.pushNamed(
      context,
      AppRoutes.tlEditInternship,
      arguments: {'internshipId': widget.internshipId},
    ).then((_) => _refreshInternship());
  }

  Widget _seatCard(String label, int available, int total, Color color) =>
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
                style: TextStyle(
                    fontSize: 11, color: Colors.white.withOpacity(0.8))),
          ]),
        ),
      );

  Widget _infoCard(String title, List<Widget> children) => Container(
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

  Widget _infoRow(IconData icon, String label, String value) => Padding(
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
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textHi(context))),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPri(context))),
              ])),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    if (_intern == null) {
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
                        child: Text(
                            _intern.status.toUpperCase() == 'ACTIVE'
                                ? 'Deactivate Internship'
                                : 'Activate Internship')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ]),
              const SizedBox(height: 20),
              StatusBadge(status: _intern.status),
              const SizedBox(height: 8),
              Text(_intern.internshipName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(_intern.internshipCode,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 13)),
              const SizedBox(height: 14),
              Text('?${_intern.fees.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900)),
              Text(
                  'Registration: ?${_intern.registrationFees.toStringAsFixed(0)}',
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
                _seatCard('Online', _intern.availableSeatsOnline,
                    _intern.totalSeatsOnline, AppColors.card2),
                const SizedBox(width: 12),
                _seatCard('Offline', _intern.availableSeatsOffline,
                    _intern.totalSeatsOffline, AppColors.card6),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _seatCard('Tirunelveli', _intern.availableSeatsTirunelveli,
                    _intern.totalSeatsTirunelveli, AppColors.card4),
                const SizedBox(width: 12),
                _seatCard('Tisaiyanvilai', _intern.availableSeatsTisaiyanvilai,
                    _intern.totalSeatsTisaiyanvilai, AppColors.card5),
              ]),
              const SizedBox(height: 20),
              _infoCard('Details', [
                _infoRow(Icons.timer_rounded, 'Duration', _intern.duration),
                _infoRow(Icons.person_rounded, 'Created By', _intern.trainerName),
                _infoRow(Icons.group_rounded, 'Batch Code', _intern.batchCode),
                _infoRow(
                    Icons.calendar_today_rounded,
                    'Start Date',
                    _intern.startDate.length >= 10
                        ? _intern.startDate.substring(0, 10)
                        : _intern.startDate),
                _infoRow(
                    Icons.event_rounded,
                    'End Date',
                    _intern.endDate.length >= 10
                        ? _intern.endDate.substring(0, 10)
                        : _intern.endDate),
                if (_intern.zoomLink != null && _intern.zoomLink!.isNotEmpty)
                  _infoRow(Icons.link_rounded, 'Zoom Link', _intern.zoomLink!),
              ]),
              const SizedBox(height: 16),
              if (_intern.description.isNotEmpty)
                _infoCard('Description', [
                  Text(_intern.description,
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSec(context),
                          height: 1.5)),
                ]),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ]),
    );
  }
}

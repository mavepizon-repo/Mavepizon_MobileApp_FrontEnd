import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/internship_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/status_badge.dart';

class AdminInternshipListScreen extends ConsumerStatefulWidget {
  const AdminInternshipListScreen({super.key});
  @override
  ConsumerState<AdminInternshipListScreen> createState() =>
      _AdminInternshipListScreenState();
}

class _AdminInternshipListScreenState
    extends ConsumerState<AdminInternshipListScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(internshipProvider.notifier).fetch());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleStatus(dynamic internship) async {
    final newStatus =
        internship.status.toUpperCase() == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    await ref
        .read(internshipProvider.notifier)
        .toggleStatus(internship.id.toString(), newStatus);
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(internshipProvider);
    final list = p.list;

    var filtered = list.where((internship) {
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty &&
          !internship.internshipName.toLowerCase().contains(q) &&
          !internship.internshipCode.toLowerCase().contains(q) &&
          !internship.trainerName.toLowerCase().contains(q))
        return false;
      if (_statusFilter.isNotEmpty &&
          !internship.status.toUpperCase().contains(_statusFilter))
        return false;
      return true;
    }).toList();

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Internships'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.adminInternshipCreate)
                    .then((_) => p.fetch()),
          ),
        ],
      ),
      body: Column(children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by name, code, trainer...',
              prefixIcon:
                  Icon(Icons.search_rounded, color: AppColors.textHi(context)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      })
                  : null,
            ),
          ),
        ),
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FChip(context, 'All', '', _statusFilter, (v) {
                setState(() => _statusFilter = v);
              }),
              _FChip(context, 'Active', 'ACTIVE', _statusFilter, (v) {
                setState(() => _statusFilter = v);
              }),
              _FChip(context, 'Inactive', 'INACTIVE', _statusFilter, (v) {
                setState(() => _statusFilter = v);
              }),
            ]),
          ),
        ),
        Expanded(
          child: p.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : p.error != null
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          Text(p.error!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 14)),
                          const SizedBox(height: 12),
                          TextButton(
                              onPressed: () => p.fetch(),
                              child: const Text('Retry'))
                        ]))
                  : filtered.isEmpty
                      ? Center(
                          child: Text('No internships',
                              style: TextStyle(color: AppColors.textHi(context))))
                      : RefreshIndicator(
                          onRefresh: () => p.fetch(),
                          color: AppColors.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final internship = filtered[i];
                              return GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.adminInternshipDetail,
                                    arguments: {'internshipId': internship.id}),
                                child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                          child: Text(
                                              internship.internshipName,
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPri(context))),
                                        ),
                                        StatusBadge(status: internship.status),
                                      ]),
                                      const SizedBox(height: 4),
                                      Text(
                                          'Code: ${internship.internshipCode}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textHi(context))),
                                      Text(
                                          'Trainer: ${internship.trainerName}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textHi(context))),
                                      Text(
                                          'Duration: ${internship.duration}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textHi(context))),
                                      const SizedBox(height: 6),
                                      Wrap(spacing: 8, runSpacing: 6, children: [
                                        _SeatChip('Online',
                                            internship.availableSeatsOnline, internship.totalSeatsOnline),
                                        _SeatChip('Offline',
                                            internship.availableSeatsOffline, internship.totalSeatsOffline),
                                        _SeatChip('Tirunelveli',
                                            internship.availableSeatsTirunelveli, internship.totalSeatsTirunelveli),
                                        _SeatChip('Tisaiyanvilai',
                                            internship.availableSeatsTisaiyanvilai, internship.totalSeatsTisaiyanvilai),
                                      ]),
                                      const SizedBox(height: 10),
                                      Row(children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 32,
                                            child: ElevatedButton.icon(
                                              onPressed: () =>
                                                  _toggleStatus(internship),
                                              icon: Icon(
                                                  internship.status
                                                              .toUpperCase() ==
                                                          'ACTIVE'
                                                      ? Icons.close_rounded
                                                      : Icons.check_circle_rounded,
                                                  size: 16),
                                              label: Text(
                                                  internship.status
                                                              .toUpperCase() ==
                                                          'ACTIVE'
                                                      ? 'Deactivate'
                                                      : 'Activate',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    internship.status
                                                                .toUpperCase() ==
                                                            'ACTIVE'
                                                        ? AppColors.error
                                                        : AppColors.success,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(8)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(Icons.edit_rounded,
                                              color: AppColors.textHi(context), size: 20),
                                          onPressed: () => Navigator.pushNamed(
                                              context, AppRoutes.adminInternshipEdit,
                                              arguments: {'internshipId': internship.id}),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_rounded,
                                              color: AppColors.error, size: 20),
                                          onPressed: () async {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                    'Delete Internship'),
                                                content: Text(
                                                    'Delete "${internship.internshipName}"?'),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(ctx, false),
                                                      child: const Text('Cancel')),
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(ctx, true),
                                                      child: const Text('Delete',
                                                          style: TextStyle(
                                                              color:
                                                                  AppColors.error))),
                                                ],
                                              ),
                                            );
                                            if (ok == true) {
                                              await ref
                                                  .read(internshipProvider.notifier)
                                                  .delete(internship.id.toString());
                                            }
                                          },
                                        ),
                                      ]),
                                    ]),
                                ),
                            );
                          },
                        ),
                      ),
        ),
      ]),
    );
  }
}

Widget _SeatChip(String label, int available, int total) {
  final fill = total > 0 ? available / total : 1.0;
  final color = fill > 0.5 ? AppColors.success : (fill > 0.2 ? AppColors.warning : AppColors.error);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text('$label: $available/$total',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}

Widget _FChip(BuildContext context, String label, String value, String current, void Function(String) onSelected) {
  final selected = current == value;
  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: GestureDetector(
      onTap: () => onSelected(selected ? '' : value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSec(context))),
      ),
    ),
  );
}

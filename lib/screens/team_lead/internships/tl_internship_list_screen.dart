import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/internship_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_widget.dart';
import '../../../widgets/status_badge.dart';

class TlInternshipListScreen extends ConsumerStatefulWidget {
  const TlInternshipListScreen({super.key});

  @override
  ConsumerState<TlInternshipListScreen> createState() =>
      _TlInternshipListScreenState();
}

class _TlInternshipListScreenState
    extends ConsumerState<TlInternshipListScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(internshipProvider.notifier).fetch());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(internshipProvider);

    var filtered = prov.list.where((intern) {
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty &&
          !intern.internshipName.toLowerCase().contains(q) &&
          !intern.internshipCode.toLowerCase().contains(q) &&
          !intern.trainerName.toLowerCase().contains(q))
        return false;
      if (_statusFilter.isNotEmpty &&
          !intern.status.toUpperCase().contains(_statusFilter))
        return false;
      return true;
    }).toList();

    return Scaffold(
      
      body: Column(
        children: [
          // --- Header ------------------------------------------
          Container(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 16, 20, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Internships',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.tlCreateInternship)
                          .then((_) => prov.fetch()),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Search bar ---------------------------------------
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
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

          // --- Status filter chips ------------------------------
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
                _FChip(context, 'Closed', 'CLOSED', _statusFilter, (v) {
                  setState(() => _statusFilter = v);
                }),
              ]),
            ),
          ),

          // --- List ---------------------------------------------
          Expanded(
            child: ResponsiveCentered(
              child: prov.isLoading
                  ? const LoadingWidget(message: 'Loading internships...')
                  : filtered.isEmpty
                      ? EmptyWidget(
                          message: prov.list.isEmpty
                              ? 'No internships yet'
                              : 'No internships match filter',
                          icon: Icons.work_outline,
                          actionLabel: '+ Create Internship',
                          onAction: () => Navigator.pushNamed(
                              context, AppRoutes.tlCreateInternship),
                        )
                      : RefreshIndicator(
                          onRefresh: () => prov.fetch(),
                          color: AppColors.accent,
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 20),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final intern = filtered[i];
                              return _InternshipCard(
                                internship: intern,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.tlInternshipDetail,
                                  arguments: {'internshipId': intern.id},
                                ).then((_) => prov.fetch()),
                              );
                            },
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Internship Card --------------------------------------------
class _InternshipCard extends StatelessWidget {
  final dynamic internship;
  final VoidCallback onTap;

  const _InternshipCard({
    required this.internship,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.card2.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.work_rounded,
                color: AppColors.card2,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    internship.internshipName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPri(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    internship.internshipCode,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHi(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    _SeatChip('Online',
                        internship.availableSeatsOnline, internship.totalSeatsOnline),
                    _SeatChip('Offline',
                        internship.availableSeatsOffline, internship.totalSeatsOffline),
                    _SeatChip('Tirunelveli',
                        internship.availableSeatsTirunelveli, internship.totalSeatsTirunelveli),
                    _SeatChip('Tisaiyanvilai',
                        internship.availableSeatsTisaiyanvilai, internship.totalSeatsTisaiyanvilai),
                  ]),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '?${internship.fees.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.card2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      StatusBadge(status: internship.status),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHi(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _SeatChip(String label, int available, int total) {
  final fill = total > 0 ? available / total : 1.0;
  final color =
      fill > 0.5 ? AppColors.success : (fill > 0.2 ? AppColors.warning : AppColors.error);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text('$label: $available/$total',
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color)),
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

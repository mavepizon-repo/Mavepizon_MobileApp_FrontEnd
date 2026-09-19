import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/staff_model.dart';
import '../../../providers/staff_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_widget.dart';
import '../../../widgets/status_badge.dart';

class TlStaffListScreen extends ConsumerStatefulWidget {
  const TlStaffListScreen({super.key});

  @override
  ConsumerState<TlStaffListScreen> createState() => _TlStaffListScreenState();
}

class _TlStaffListScreenState extends ConsumerState<TlStaffListScreen> {
  final _categories = [
    'ALL',
    'DEVELOPER',
    'DEVELOPER_TRAINER',
    'TELECOM_SERVICE',
    'DESIGNER',
    'FREELANCER',
  ];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(staffProvider.notifier).fetch(),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(staffProvider);

    var filtered = prov.list.where((s) {
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty &&
          !s.name.toLowerCase().contains(q) &&
          !s.email.toLowerCase().contains(q) &&
          !s.role.toLowerCase().contains(q))
        return false;
      return true;
    }).toList();

    return Scaffold(
      
      body: Column(
        children: [
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Staff Directory',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                              context, AppRoutes.tlCreateStaff)
                          .then((_) => ref.read(staffProvider.notifier).fetch()),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.person_add_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ref.read(staffProvider.notifier).fetch(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // -- Category filter chips ------------------------------
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final sel = prov.filterCategory == cat;
                  final label = cat == 'ALL' ? 'All' : cat.replaceAll('_', ' ');
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => prov.setFilter(cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.accent
                              : AppColors.accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name, email, role...',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text('${filtered.length} staff members',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSec(context),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Expanded(
            child: ResponsiveCentered(
              child: prov.isLoading
                  ? const LoadingWidget(message: 'Loading staff...')
                  : filtered.isEmpty
                      ? const EmptyWidget(
                          message: 'No staff found', icon: Icons.people_outline)
                      : RefreshIndicator(
                          onRefresh: () => prov.fetch(),
                          color: AppColors.accent,
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 20),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final s = filtered[i];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context,
                                          AppRoutes.tlStaffDetail,
                                          arguments: {'staffId': s.id})
                                      .then((_) => prov.fetch());
                                },
                                child: _StaffCard(staff: s),
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

class _StaffCard extends StatelessWidget {
  final StaffModel staff;
  const _StaffCard({required this.staff});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            radius: 24,
            backgroundImage: staff.profilePhoto != null &&
                    staff.profilePhoto!.isNotEmpty
                ? NetworkImage(staff.profilePhoto!)
                : null,
            child: staff.profilePhoto == null ||
                    staff.profilePhoto!.isEmpty
                ? Text(
                    staff.name.isNotEmpty
                        ? staff.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.name,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context))),
                const SizedBox(height: 4),
                Text(staff.role,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSec(context))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusBadge(status: staff.status, fontSize: 10),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(staff.email,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textHi(context))),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textHi(context)),
        ],
      ),
    );
  }
}

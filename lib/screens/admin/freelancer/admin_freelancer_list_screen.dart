import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_freelancer_provider.dart';
import '../../../routes/app_routes.dart';

class AdminFreelancerListScreen extends ConsumerStatefulWidget {
  const AdminFreelancerListScreen({super.key});
  @override
  ConsumerState<AdminFreelancerListScreen> createState() =>
      _AdminFreelancerListScreenState();
}

class _AdminFreelancerListScreenState
    extends ConsumerState<AdminFreelancerListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(adminFreelancerProvider.notifier).fetch());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(adminFreelancerProvider);
    final all = p.list;

    var filtered = all.where((f) {
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty &&
          !f.name.toLowerCase().contains(q) &&
          !f.email.toLowerCase().contains(q) &&
          !f.district.toLowerCase().contains(q))
        return false;
      return true;
    }).toList();

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Freelancers'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.adminFreelancerCreate)
                    .then((_) => p.fetch()),
          ),
        ],
      ),
      body: Column(children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by name, email, district...',
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
        Expanded(
          child: p.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : p.error != null
                  ? Center(child: Text(p.error!))
                  : filtered.isEmpty
                      ? Center(
                          child: Text('No freelancers found',
                              style: TextStyle(color: AppColors.textHi(context))))
                      : RefreshIndicator(
                          onRefresh: () =>
                              ref.read(adminFreelancerProvider.notifier).fetch(),
                          color: AppColors.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final f = filtered[i];
                              return Container(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppColors.primary
                                              .withOpacity(0.1),
                                          child: Text(
                                            f.initials,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(f.name,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .textPrimary)),
                                                const SizedBox(height: 2),
                                                Text(f.email.isEmpty
                                                    ? f.mobileNo
                                                    : f.email,
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors
                                                            .textHint)),
                                              ]),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                              Icons.visibility_rounded,
                                              color: AppColors.textHi(context)),
                                          onPressed: () => Navigator
                                              .pushNamed(
                                            context,
                                            AppRoutes.adminFreelancerDetail,
                                            arguments: {'id': f.id},
                                          ),
                                          visualDensity:
                                              VisualDensity.compact,
                                        ),
                                        IconButton(
                                          icon: Icon(
                                              Icons.edit_rounded,
                                              color: AppColors.textHi(context)),
                                          onPressed: () => Navigator
                                              .pushNamed(
                                            context,
                                            AppRoutes.adminFreelancerEdit,
                                            arguments: {'id': f.id},
                                          )
                                              .then((_) => p.fetch()),
                                          visualDensity:
                                              VisualDensity.compact,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_rounded,
                                              color: AppColors.error),
                                          onPressed: () async {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                    'Delete Freelancer'),
                                                content: Text(
                                                    'Delete "${f.name}"?'),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx, false),
                                                      child:
                                                          const Text('Cancel')),
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx, true),
                                                      child: const Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                              color: AppColors
                                                                  .error))),
                                                ],
                                              ),
                                            );
                                            if (ok == true) {
                                              await ref
                                                  .read(adminFreelancerProvider
                                                      .notifier)
                                                  .delete(f.id);
                                            }
                                          },
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ]),
                                      const SizedBox(height: 8),
                                      Row(children: [
                                        _InfoChip(Icons.location_city_rounded,
                                            f.district, AppColors.accent),
                                        const SizedBox(width: 8),
                                        _InfoChip(Icons.school_rounded,
                                            f.yearOfPassing, AppColors.card2),
                                        const SizedBox(width: 8),
                                        _InfoChip(Icons.work_rounded,
                                            '${f.experience} yrs',
                                            AppColors.card3),
                                      ]),
                                      if (f.techStackNames.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: f.techStackNames
                                              .map((t) => Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                                horizontal: 8,
                                                                vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.card6
                                                          .withOpacity(0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Text(t,
                                                        style: const TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppColors
                                                                .card6)),
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                    ]),
                              );
                            },
                          ),
                        ),
        ),
      ]),
    );
  }
}

Widget _InfoChip(IconData icon, String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ]),
  );
}

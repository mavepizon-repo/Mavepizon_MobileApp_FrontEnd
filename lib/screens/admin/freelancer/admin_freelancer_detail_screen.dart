import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_freelancer_provider.dart';
import '../../../providers/freelancer_provider.dart';
import '../../../routes/app_routes.dart';

class AdminFreelancerDetailScreen extends ConsumerStatefulWidget {
  final String freelancerId;
  const AdminFreelancerDetailScreen({super.key, required this.freelancerId});
  @override
  ConsumerState<AdminFreelancerDetailScreen> createState() =>
      _AdminFreelancerDetailScreenState();
}

class _AdminFreelancerDetailScreenState
    extends ConsumerState<AdminFreelancerDetailScreen> {
  dynamic _freelancer;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final f = await ref
        .read(adminFreelancerProvider.notifier)
        .getById(widget.freelancerId);
    if (f != null && mounted) {
      setState(() => _freelancer = f);
    } else if (mounted) {
      setState(() => _error = 'Failed to load freelancer');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Freelancer Detail'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? Center(child: Text(_error!))
              : _freelancer == null
                  ? const Center(child: Text('Not found'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _ProfileHeader(freelancer: _freelancer!),
                        const SizedBox(height: 16),
                        _InfoCard(freelancer: _freelancer!),
                        const SizedBox(height: 16),
                        _TasksCard(
                          freelancerId: widget.freelancerId,
                        ),
                      ],
                    ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic freelancer;
  const _ProfileHeader({required this.freelancer});

  @override
  Widget build(BuildContext context) {
    final name = freelancer['name']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              if ((freelancer['email']?.toString() ?? '').isNotEmpty)
                Text(freelancer['email'].toString(),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 12)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final dynamic freelancer;
  const _InfoCard({required this.freelancer});

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSec(context))),
          ),
          Expanded(
            child: Text(value.isEmpty ? '-' : value,
                style: TextStyle(
                    fontSize: 13, color: AppColors.textPri(context))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal Details',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppColors.textPri(context))),
          const Divider(height: 20),
          _row(context, 'Mobile', freelancer['mobileNo']?.toString() ?? ''),
          _row(context, 'District', freelancer['district']?.toString() ?? ''),
          _row(context, 'Address', freelancer['address']?.toString() ?? ''),
          _row(context, 'Year of Passing', freelancer['yearOfPassing']?.toString() ?? ''),
          _row(context, 'Experience', '${freelancer['experience']?.toString() ?? ''} yrs'),
          _row(context, 'Aadhaar', freelancer['aadhaar']?.toString() ?? ''),
          if ((freelancer['techStackNames'] as List? ?? []).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Tech Stacks',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSec(context))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (freelancer['techStackNames'] as List)
                  .map((t) => Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.card6.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(t.toString(),
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.card6)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TasksCard extends ConsumerStatefulWidget {
  final String freelancerId;
  const _TasksCard({required this.freelancerId});
  @override
  ConsumerState<_TasksCard> createState() => _TasksCardState();
}

class _TasksCardState extends ConsumerState<_TasksCard> {
  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(adminFreelancerTasksProvider).tasks
        .where((t) => t.freelancerIds.contains(widget.freelancerId))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Assigned Tasks',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPri(context))),
              TextButton(
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.adminFreelancerTaskCreate),
                child: const Text('Assign'),
              ),
            ],
          ),
          const Divider(height: 8),
          if (tasks.isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('No tasks assigned',
                    style: TextStyle(color: AppColors.textHi(context))),
              ),
            )
          else
            for (final t in tasks)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.business_center_rounded,
                    color: AppColors.accent),
                title: Text(t.orgName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(t.domain),
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.adminFreelancerTaskDetail,
                        arguments: {'id': t.id}),
              ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context)
                  .pushNamed(AppRoutes.adminFreelancerTaskList),
              icon: const Icon(Icons.task_alt_rounded, size: 18),
              label: const Text('View All Freelancer Tasks'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

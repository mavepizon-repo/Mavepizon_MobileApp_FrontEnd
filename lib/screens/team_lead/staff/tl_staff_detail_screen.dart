import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/staff_model.dart';
import '../../../providers/staff_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/task_service.dart';
import '../../../widgets/loading_widget.dart';

class TlStaffDetailScreen extends ConsumerStatefulWidget {
  final String staffId;
  const TlStaffDetailScreen({super.key, required this.staffId});

  @override
  ConsumerState<TlStaffDetailScreen> createState() => _TlStaffDetailScreenState();
}

class _TlStaffDetailScreenState extends ConsumerState<TlStaffDetailScreen> {
  StaffModel? _staff;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStaff());
  }

  Future<void> _refreshStaff() async {
    if (!mounted) return;
    await ref.read(staffProvider.notifier).fetchById(widget.staffId);
    if (!mounted) return;

    StaffModel? s = ref.read(staffProvider).selected;
    if (s != null) {
      final result = await TaskService.getAll(staffId: widget.staffId);
      if (result['success'] == true && result['data'] is List) {
        final tasks = result['data'] as List;
        int assigned = 0, completed = 0, pending = 0;
        for (final t in tasks) {
          if (t is Map) {
            final st = (t['status'] ?? '').toString().toUpperCase();
            if (st == 'COMPLETED' || st == 'APPROVED') {
              completed++;
            } else if (st == 'ASSIGNED' || st == 'IN_PROGRESS' || st == 'PENDING') {
              pending++;
            }
            assigned++;
          }
        }
        s = s.copyWith(
          totalAssignedTasks: assigned,
          totalCompletedTasks: completed,
          totalPendingTasks: pending,
        );
      }
    }

    if (mounted) setState(() => _staff = s);
  }

  Future<void> _toggleStatus() async {
    if (_staff == null || _actionLoading) return;

    setState(() => _actionLoading = true);

    final newStatus = _staff!.status == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    final ok = await ref
        .read(staffProvider.notifier)
        .toggleStatus(widget.staffId, newStatus);

    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (ok) {
      await _refreshStaff();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Staff ${newStatus == 'ACTIVE' ? 'activated' : 'deactivated'} successfully'),
        backgroundColor:
            newStatus == 'ACTIVE' ? AppColors.success : AppColors.warning,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else {
      final err = ref.read(staffProvider).error ?? 'Failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _deleteStaff() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Staff'),
        content: const Text(
            'This action cannot be undone. Delete this staff member?'),
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
      final deleted = await ref.read(staffProvider.notifier).delete(widget.staffId);
      if (mounted) {
        if (deleted) {
          Navigator.pop(context);
        } else {
          final err = ref.read(staffProvider).error ?? 'Failed to delete staff';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(err),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(staffProvider);

    if (prov.isLoading && _staff == null) {
      return const Scaffold(
        
        body: LoadingWidget(),
      );
    }

    if (_staff == null) {
      return Scaffold(
        
        appBar: AppBar(
          backgroundColor: const Color(0xFF0EA5E9),
          iconTheme: const IconThemeData(color: Colors.white),
          title:
              const Text('Staff Detail', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: Text('Staff not found')),
      );
    }

    final isActive = _staff!.status == 'ACTIVE';

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
                  bottomRight: Radius.circular(32)),
            ),
            child: Column(children: [
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
                    if (v == 'edit') {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.tlEditStaff,
                        arguments: {'staffId': widget.staffId},
                      ).then((_) => _refreshStaff());
                    }
                    if (v == 'toggle') _toggleStatus();
                    if (v == 'delete') _deleteStaff();
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
                      child: Row(children: [
                        Icon(
                            isActive
                                ? Icons.block_rounded
                                : Icons.check_circle_rounded,
                            color: isActive
                                ? AppColors.warning
                                : AppColors.success,
                            size: 18),
                        const SizedBox(width: 10),
                        Text(isActive ? 'Deactivate' : 'Activate'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded,
                            color: AppColors.error, size: 18),
                        SizedBox(width: 10),
                        Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ]),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 20),
              // -- Profile Photo --
              if (_staff!.profilePhoto != null &&
                  _staff!.profilePhoto!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: Image.network(
                    _staff!.profilePhoto!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarPlaceholder(),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return _avatarPlaceholder();
                    },
                  ),
                )
              else
                _avatarPlaceholder(),
              const SizedBox(height: 12),
              Text(_staff!.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(_staff!.employeeId,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 13)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(_staff!.role,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isActive
                            ? AppColors.success.withOpacity(0.5)
                            : AppColors.error.withOpacity(0.5)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color:
                                isActive ? AppColors.success : AppColors.error,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(isActive ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                            color:
                                isActive ? AppColors.success : AppColors.error,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
            ]),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(children: [
                _PerfBox('${_staff!.performanceScore.toInt()}%', 'Score',
                    AppColors.card1),
                const SizedBox(width: 10),
                _PerfBox('${_staff!.totalAssignedTasks}', 'Assigned',
                    AppColors.card2),
                const SizedBox(width: 10),
                _PerfBox(
                    '${_staff!.totalCompletedTasks}', 'Done', AppColors.card3),
                const SizedBox(width: 10),
                _PerfBox(
                    '${_staff!.totalPendingTasks}', 'Pending', AppColors.card5),
              ]),
              const SizedBox(height: 20),

              _infoSection(context, 'Personal Information', [
                _infoItem(context, Icons.alternate_email_rounded, 'Email Address',
                    _staff!.email),
                _infoItem(context, 
                    Icons.phone_rounded, 'Mobile Number', _staff!.mobileNumber),
                _infoItem(context, 
                    Icons.bloodtype_rounded,
                    'Blood Group',
                    _staff!.bloodGroup?.isNotEmpty == true
                        ? _staff!.bloodGroup!
                        : 'Not specified'),
              ]),
              const SizedBox(height: 16),

              _infoSection(context, 'Work Details', [
                _infoItem(context, Icons.location_on_rounded, 'Branch', _staff!.branch),
                if (_staff!.joiningDate.isNotEmpty)
                  _infoItem(context, 
                      Icons.calendar_today_rounded,
                      'Joining Date',
                      _staff!.joiningDate.length >= 10
                          ? _staff!.joiningDate.substring(0, 10)
                          : _staff!.joiningDate),
                if (_staff!.skills.isNotEmpty)
                  _infoItem(context, Icons.psychology_rounded, 'Skills',
                      _staff!.skills.join(', ')),
              ]),
              const SizedBox(height: 16),

              _infoSection(context, 'Qualifications', [
                _infoItem(context, Icons.school_rounded, 'Degree', _staff!.degree),
                _infoItem(context, 
                    Icons.history_edu_rounded,
                    'Experience',
                    _staff!.experience != null
                        ? '${_staff!.experience} Years'
                        : 'Fresher'),
                _infoItem(context, 
                    Icons.business_rounded,
                    'Previous Company',
                    _staff!.previousCompany?.isNotEmpty == true
                        ? _staff!.previousCompany!
                        : 'None'),
              ]),
              const SizedBox(height: 16),

              // -- Documents --
              _infoSection(context, 'Documents', [
                if (_staff!.resume != null && _staff!.resume!.isNotEmpty)
                  _linkItem(context, Icons.description_rounded, 'Resume',
                      _staff!.resume!),
                if (_staff!.aadhar != null && _staff!.aadhar!.isNotEmpty)
                  _linkItem(context, Icons.badge_rounded, 'Aadhar Card',
                      _staff!.aadhar!),
                if (_staff!.experienceCertificate != null &&
                    _staff!.experienceCertificate!.isNotEmpty)
                  _linkItem(context, Icons.verified_rounded, 'Experience Certificate',
                      _staff!.experienceCertificate!),
                if ((_staff!.resume == null || _staff!.resume!.isEmpty) &&
                    (_staff!.aadhar == null || _staff!.aadhar!.isEmpty) &&
                    (_staff!.experienceCertificate == null ||
                        _staff!.experienceCertificate!.isEmpty))
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('No documents uploaded',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textHi(context),
                            fontStyle: FontStyle.italic)),
                  ),
              ]),
              const SizedBox(height: 16),

              // -- Meta Info --
              _infoSection(context, 'Meta', [
                if (_staff!.createdByAdmin != null &&
                    _staff!.createdByAdmin!.isNotEmpty)
                  _infoItem(context, Icons.admin_panel_settings_rounded,
                      'Created By', _staff!.createdByAdmin!),
                if (_staff!.createdAt.isNotEmpty)
                  _infoItem(context, Icons.access_time_rounded, 'Created At',
                      _staff!.createdAt.length >= 10
                          ? _staff!.createdAt.substring(0, 10)
                          : _staff!.createdAt),
                if (_staff!.updatedAt != null &&
                    _staff!.updatedAt!.isNotEmpty)
                  _infoItem(context, Icons.update_rounded, 'Updated At',
                      _staff!.updatedAt!.length >= 10
                          ? _staff!.updatedAt!.substring(0, 10)
                          : _staff!.updatedAt!),
              ]),
              const SizedBox(height: 24),

              GestureDetector(
                onTap: _actionLoading ? null : _toggleStatus,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.warning.withOpacity(0.08)
                        : AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isActive
                            ? AppColors.warning.withOpacity(0.3)
                            : AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_actionLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.accent),
                        )
                      else
                        Icon(
                            isActive
                                ? Icons.block_rounded
                                : Icons.check_circle_rounded,
                            color: isActive
                                ? AppColors.warning
                                : AppColors.success,
                            size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _actionLoading
                            ? 'Updating...'
                            : (isActive
                                ? 'Deactivate Staff'
                                : 'Activate Staff'),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? AppColors.warning
                                : AppColors.success),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.3),
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withOpacity(0.4), width: 3)),
      child: Center(
          child: Text(
              _staff!.name.isNotEmpty
                  ? _staff!.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800))),
    );
  }
}

Widget _PerfBox(String val, String label, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(children: [
          Text(val,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );

Widget _infoSection(BuildContext context, String title, List<Widget> items) => Container(
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
        const SizedBox(height: 14),
        ...items,
      ]),
    );

Widget _infoItem(BuildContext context, IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHi(context),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPri(context))),
        ])),
      ]),
    );

Widget _linkItem(BuildContext context, IconData icon, String label, String url) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHi(context),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          InkWell(
            onTap: () async {
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(
              url,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
                decoration: TextDecoration.underline,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ])),
      ]),
    );

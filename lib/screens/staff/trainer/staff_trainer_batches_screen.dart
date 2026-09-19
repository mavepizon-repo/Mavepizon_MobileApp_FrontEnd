import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../services/trainer_service.dart';
import '../../../routes/app_routes.dart';

class StaffTrainerBatchesScreen extends ConsumerStatefulWidget {
  const StaffTrainerBatchesScreen({super.key});

  @override
  ConsumerState<StaffTrainerBatchesScreen> createState() =>
      _StaffTrainerBatchesScreenState();
}

class _StaffTrainerBatchesScreenState
    extends ConsumerState<StaffTrainerBatchesScreen> {
  String _staffId = '';
  List<dynamic> _batches = [];
  bool _loading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _staffId = await StorageHelper.getStaffId() ?? '';
    if (mounted && _staffId.isNotEmpty) await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = _tabIndex == 0
          ? await TrainerService.getBatches(_staffId)
          : _tabIndex == 1
              ? await TrainerService.getOnlineBatches(_staffId)
              : await TrainerService.getOfflineBatches(_staffId);
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          _batches = data;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load batches: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('My Batches',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.dashboard_rounded,
                color: AppColors.textSec(context)),
            onPressed: () => Navigator.pushNamed(
                context, AppRoutes.trainerBatches),
          ),
        ],
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            _Tab('All', 0),
            _Tab('Online', 1),
            _Tab('Offline', 2),
          ]),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.accent,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 2))
                : _batches.isEmpty
                    ? ListView(children: [
                        SizedBox(
                          height:
                              MediaQuery.of(context).size.height * 0.3,
                          child: Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.groups_rounded,
                                      size: 60,
                                      color: AppColors.textHi(context)
                                          .withOpacity(0.4)),
                                  const SizedBox(height: 16),
                                  Text('No batches assigned',
                                      style: TextStyle(
                                          color: AppColors.textHi(context))),
                                ]),
                          ),
                        ),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _batches.length,
                        itemBuilder: (ctx, i) {
                          final b = _batches[i];
                          return GestureDetector(
                            onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.trainerBatchDetail,
                                arguments: {
                                  'batchId':
                                      b['batchId']?.toString() ?? '',
                                  'batchName':
                                      b['batchName']?.toString() ?? '',
                                  'zoomLink':
                                      b['zoomLink']?.toString() ?? '',
                                }),
                            child: Container(
                              margin:
                                  const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2))
                                  ]),
                              child: Row(children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                      child: Icon(
                                          Icons.groups_rounded,
                                          color: AppColors.accent,
                                          size: 22)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            b['batchName']
                                                    ?.toString() ??
                                                'Unnamed Batch',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color:
                                                    AppColors.textPri(context))),
                                        const SizedBox(height: 2),
                                        Text(
                                            '${b['studentCount'] ?? 0} students',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors
                                                    .textSecondary)),
                                      ]),
                                ),
                                Icon(Icons.chevron_right_rounded,
                                    size: 20,
                                    color: AppColors.textHi(context)),
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

  Widget _Tab(String label, int index) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _tabIndex = index;
          _load();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : AppColors.textSec(context))),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/file_opener.dart';
import '../../../services/college_staff_service.dart';

class CollegeStaffMyFilesScreen extends ConsumerStatefulWidget {
  const CollegeStaffMyFilesScreen({super.key});

  @override
  ConsumerState<CollegeStaffMyFilesScreen> createState() =>
      _CollegeStaffMyFilesScreenState();
}

class _CollegeStaffMyFilesScreenState
    extends ConsumerState<CollegeStaffMyFilesScreen> {
  bool _loading = true;
  List<dynamic> _files = [];
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
    final result = await CollegeStaffService.getMyFiles();
    if (mounted) {
      setState(() {
        _loading = false;
        if (result['success'] == true && result['data'] is List) {
          _files = result['data'] as List;
        } else {
          _files = [];
          _error = result['message']?.toString() ?? 'Failed to load files';
        }
      });
    }
  }

  Future<void> _open(String? url) async {
    final link = url?.toString().trim() ?? '';
    if (link.isEmpty) return;
    openFileInApp(context, link, title: 'Course File');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('My Files'),
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.accent,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null && _files.isEmpty) ...[
                    const SizedBox(height: 60),
                    Icon(Icons.error_outline_rounded,
                        size: 56, color: AppColors.textHi(context).withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Center(
                        child: Text(_error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textSec(context)))),
                    const SizedBox(height: 20),
                  ] else if (_files.isEmpty) ...[
                    const SizedBox(height: 60),
                    Icon(Icons.folder_open_rounded,
                        size: 56, color: AppColors.textHi(context).withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Center(
                        child: Text(
                            'No files sent yet.\nSyllabus & proposal sent by admin will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textHi(context)))),
                    const SizedBox(height: 20),
                  ] else
                    ..._files.map((f) {
                      final staffName = f['staffName']?.toString() ?? '';
                      final collegeName = f['collegeName']?.toString() ?? '';
                      final syllabusURL = f['syllabusURL']?.toString() ?? '';
                      final proposalURL = f['proposalURL']?.toString() ?? '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
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
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                      Icons.menu_book_rounded,
                                      color: AppColors.accent,
                                      size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          staffName.isNotEmpty
                                              ? staffName
                                              : 'Course Files',
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPri(context)),
                                        ),
                                        if (collegeName.isNotEmpty)
                                          Text(collegeName,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textHi(context))),
                                      ]),
                                ),
                              ]),
                              const SizedBox(height: 14),
                              _FileRow(
                                icon: Icons.description_rounded,
                                label: 'Syllabus',
                                url: syllabusURL,
                                onTap: syllabusURL.isNotEmpty
                                    ? () => _open(syllabusURL)
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              _FileRow(
                                icon: Icons.article_rounded,
                                label: 'Proposal',
                                url: proposalURL,
                                onTap: proposalURL.isNotEmpty
                                    ? () => _open(proposalURL)
                                    : null,
                              ),
                            ]),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _FileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final VoidCallback? onTap;

  const _FileRow({
    required this.icon,
    required this.label,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPri(context)),
            ),
          ),
          if (url.isNotEmpty)
            const Icon(Icons.open_in_new_rounded,
                size: 16, color: AppColors.accent)
          else
            Text('Not sent',
                style: TextStyle(fontSize: 12, color: AppColors.textHi(context))),
        ]),
      ),
    );
  }
}

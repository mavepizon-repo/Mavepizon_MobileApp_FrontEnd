import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_college_staff_provider.dart';
import '../../../services/admin_college_staff_service.dart';

class AdminCollegeStaffDetailScreen extends ConsumerStatefulWidget {
  final String collegeStaffId;
  const AdminCollegeStaffDetailScreen(
      {super.key, required this.collegeStaffId});
  @override
  ConsumerState<AdminCollegeStaffDetailScreen> createState() =>
      _AdminCollegeStaffDetailScreenState();
}

class _AdminCollegeStaffDetailScreenState
    extends ConsumerState<AdminCollegeStaffDetailScreen> {
  ({Uint8List bytes, String name})? _syllabusFile;
  ({Uint8List bytes, String name})? _proposalFile;
  String? _syllabusName;
  String? _proposalName;
  bool _uploading = false;
  String? _uploadMsg;
  bool _uploadOk = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(adminCollegeStaffProvider.notifier)
        .fetchById(widget.collegeStaffId));
  }

  Future<void> _pickSyllabus() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        final f = result.files.single;
        setState(() {
          _syllabusFile = (bytes: f.bytes!, name: f.name);
          _syllabusName = f.name;
          _uploadMsg = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick syllabus: $e')));
      }
    }
  }

  Future<void> _pickProposal() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        final f = result.files.single;
        setState(() {
          _proposalFile = (bytes: f.bytes!, name: f.name);
          _proposalName = f.name;
          _uploadMsg = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick proposal: $e')));
      }
    }
  }

  Future<void> _upload() async {
    if (_syllabusFile == null || _proposalFile == null) {
      setState(() {
        _uploadMsg = 'Please select both Syllabus and Proposal files';
        _uploadOk = false;
      });
      return;
    }
    setState(() {
      _uploading = true;
      _uploadMsg = null;
    });

    final result = await AdminCollegeStaffService.uploadSyllabus(
      widget.collegeStaffId,
      syllabus: _syllabusFile!,
      proposal: _proposalFile!,
    );

    if (mounted) {
      setState(() {
        _uploading = false;
        _uploadOk = result['success'] == true;
        _uploadMsg = _uploadOk
            ? 'Syllabus & proposal sent successfully!'
            : result['message']?.toString() ?? 'Upload failed';
        if (_uploadOk) {
          _syllabusFile = null;
          _proposalFile = null;
          _syllabusName = null;
          _proposalName = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(adminCollegeStaffProvider);
    final s = p.selected;

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('College Staff Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: p.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : p.error != null
              ? Center(child: Text(p.error!))
              : s == null
                  ? const Center(child: Text('Not found'))
                  : RefreshIndicator(
                      onRefresh: () => p.fetchById(widget.collegeStaffId),
                      child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
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
                              child: Column(children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor:
                                      AppColors.card6.withOpacity(0.1),
                                  child: Text(
                                    s.name.isNotEmpty
                                        ? s.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.card6),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(s.name,
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPri(context))),
                              ]),
                            ),
                            const SizedBox(height: 16),
                            Container(
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Details',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPri(context))),
                                    const SizedBox(height: 12),
                                    _DetailRow(context, 'College', s.collegeName),
                                    _DetailRow(context, 'Department', s.department),
                                    _DetailRow(context, 'Gender', s.gender),
                                    _DetailRow(context, 'Mobile', s.mobileNumber),
                                    _DetailRow(context, 'Email', s.email),
                                    _DetailRow(context, 'Uploaded Students',
                                        '${s.uploadedStudentsCount}'),
                                  ]),
                            ),
                            const SizedBox(height: 16),
                            Container(
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Send Syllabus & Proposal',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPri(context))),
                                    const SizedBox(height: 4),
                                    Text(
                                        'PDF / Word files. The college staff will see them in their My Files.',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textHi(context))),
                                    const SizedBox(height: 14),
                                    _FilePickerTile(
                                        icon: Icons.menu_book_rounded,
                                        label: 'Syllabus',
                                        fileName: _syllabusName,
                                        onTap: _pickSyllabus),
                                    const SizedBox(height: 10),
                                    _FilePickerTile(
                                        icon: Icons.description_rounded,
                                        label: 'Proposal',
                                        fileName: _proposalName,
                                        onTap: _pickProposal),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 46,
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _uploading ? null : _upload,
                                        icon: _uploading
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white))
                                            : const Icon(Icons.send_rounded,
                                                size: 18),
                                        label: Text(_uploading
                                            ? 'Uploading...'
                                            : 'Send to College Staff'),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.accent,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12))),
                                      ),
                                    ),
                                    if (_uploadMsg != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: (_uploadOk
                                                  ? AppColors.success
                                                  : AppColors.error)
                                              .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          _uploadMsg!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _uploadOk
                                                ? AppColors.success
                                                : AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ]),
                            ),
                          ]),
                    ),
    );
  }
}

Widget _DetailRow(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHi(context))),
          ),
          Expanded(
            child: Text(value.isNotEmpty ? value : '-',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPri(context))),
          ),
        ]),
  );
}

class _FilePickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? fileName;
  final VoidCallback onTap;

  const _FilePickerTile({
    required this.icon,
    required this.label,
    required this.fileName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderC(context)),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName ?? 'Tap to select $label file',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: fileName != null
                    ? AppColors.textPri(context)
                    : AppColors.textHi(context),
              ),
            ),
          ),
          if (fileName != null)
            const Icon(Icons.check_circle_rounded,
                size: 18, color: AppColors.success),
        ]),
      ),
    );
  }
}

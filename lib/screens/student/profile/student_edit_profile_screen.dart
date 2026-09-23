import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../services/student_service.dart';

class StudentEditProfileScreen extends ConsumerStatefulWidget {
  const StudentEditProfileScreen({super.key});
  @override
  ConsumerState<StudentEditProfileScreen> createState() =>
      _StudentEditProfileScreenState();
}

class _StudentEditProfileScreenState
    extends ConsumerState<StudentEditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  Uint8List? _selectedImage;
  String _profilePhoto = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await StorageHelper.getUserName() ?? '';
    _profilePhoto = await StorageHelper.getUserProfile() ?? '';
    _nameCtrl.text = name;
    if (mounted) setState(() {});
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _selectedImage = bytes);
    }
  }

  Future<void> _save() async {
    final studentId = await StorageHelper.getUserId();
    if (studentId == null) return;

    setState(() => _loading = true);

    String uploadedPhoto = _profilePhoto;
    if (_selectedImage != null) {
      final fileResult = await StudentService.updateFiles({
        'profile': (bytes: _selectedImage!, name: 'profile.jpg'),
      });
      final fileData = fileResult['data'];
      if (fileResult['success'] == true && fileData is Map) {
        uploadedPhoto = fileData['profile']?.toString() ??
            fileData['profilePhoto']?.toString() ??
            uploadedPhoto;
      }
    }

    final result = await StudentService.updateProfile({
      'name': _nameCtrl.text.trim(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true
              ? 'Profile updated'
              : result['message'] ?? 'Update failed'),
          backgroundColor: result['success'] == true
              ? AppColors.success
              : AppColors.error,
        ),
      );
      if (result['success'] == true) {
        await StorageHelper.saveLoginData(
          token: await StorageHelper.getToken() ?? '',
          role: 'STUDENT',
          userId: studentId,
          userName: _nameCtrl.text.trim(),
          userEmail: await StorageHelper.getUserEmail() ?? '',
          userProfile: uploadedPhoto,
        );
        if (mounted) Navigator.pop(context);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Edit Profile',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ]),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: AppColors.accent.withOpacity(0.12),
                    backgroundImage:
                        _selectedImage != null
                            ? MemoryImage(_selectedImage!) as ImageProvider
                            : (_profilePhoto.isNotEmpty
                                ? NetworkImage(_profilePhoto)
                                : null),
                    child: _selectedImage == null &&
                            _profilePhoto.isEmpty
                        ? const Icon(Icons.person_rounded,
                            color: AppColors.accent, size: 40)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: AppColors.accent,
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _selectedImage != null
                    ? 'Photo selected - tap to change'
                    : 'Tap to add a profile photo',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSec(context),
                    fontWeight: FontWeight.w500),
              ),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _selectedImage = null),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Remove selected photo'),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text('Full Name',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPri(context))),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
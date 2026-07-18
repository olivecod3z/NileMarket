import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nilemarket/core/theme/app_colors.dart';
import 'package:nilemarket/core/theme/app_text_styles.dart';
import 'package:nilemarket/core/widgets/app_shell.dart';
import 'package:nilemarket/core/supabase/supabase_client.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _newAvatar;
  String? _existingAvatarUrl;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data != null && mounted) {
        _usernameController.text = data['username'] ?? '';
        _fullNameController.text = data['full_name'] ?? '';
        _bioController.text = data['bio'] ?? '';
        setState(() => _existingAvatarUrl = data['avatar_url']);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 800,
    );
    if (image != null) setState(() => _newAvatar = image);
  }

  Future<String?> _uploadAvatarIfNeeded(String userId) async {
    if (_newAvatar == null) return _existingAvatarUrl;

    final bytes = await _newAvatar!.readAsBytes();
    final fileExt = _newAvatar!.name.split('.').last;
    final path = '$userId/avatar.$fileExt';

    await supabase.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    // cache-bust so the new image actually shows instead of a cached old one
    return '${supabase.storage.from('avatars').getPublicUrl(path)}?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = supabase.auth.currentUser!.id;
      final avatarUrl = await _uploadAvatarIfNeeded(userId);

      await supabase
          .from('profiles')
          .update({
            'username': _usernameController.text.trim(),
            'full_name': _fullNameController.text.trim(),
            'bio': _bioController.text.trim(),
            'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
        context.pop();
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        final message = e.code == '23505'
            ? 'That username is already taken'
            : e.message;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/edit-profile',
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(context),
                          const SizedBox(height: 24),
                          Center(child: _avatarPicker()),
                          const SizedBox(height: 28),
                          _label('Username'),
                          TextFormField(
                            controller: _usernameController,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Username is required';
                              if (v.contains(' '))
                                return 'Username cannot contain spaces';
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          _label('Full Name'),
                          TextFormField(
                            controller: _fullNameController,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Full name is required'
                                : null,
                          ),
                          const SizedBox(height: 18),
                          _label('Bio'),
                          TextFormField(
                            controller: _bioController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'A short intro about yourself',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton(
                            onPressed: _isSaving ? null : _handleSave,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 10),
        Text('Edit Profile', style: AppTextStyles.heading3),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _avatarPicker() {
    return GestureDetector(
      onTap: _pickAvatar,
      child: Stack(
        children: [
          ClipOval(
            child: _newAvatar != null
                ? FutureBuilder<Uint8List>(
                    future: _newAvatar!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container(
                          width: 96,
                          height: 96,
                          color: AppColors.divider,
                        );
                      }
                      return Image.memory(
                        snapshot.data!,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : _existingAvatarUrl != null
                ? Image.network(
                    _existingAvatarUrl!,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 96,
                    height: 96,
                    color: AppColors.divider,
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.nileBlue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

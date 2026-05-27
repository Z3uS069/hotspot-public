import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _confirmPasswordCtrl;

  String? _avatarUrl;
  String _email = '';

  // ── BACKEND (all unchanged) ───────────────────

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _confirmPasswordCtrl = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      _email = _supabase.auth.currentUser?.email ?? '';
      final res = await _supabase
          .from('users')
          .select('name, phone, avatar_url')
          .eq('id', userId)
          .single();
      setState(() {
        _nameCtrl.text = res['name'] ?? '';
        _phoneCtrl.text = res['phone'] ?? '';
        _avatarUrl = res['avatar_url'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Load profile error: $e');
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final source =
    await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(24))),
      builder: (_) => Padding(
        padding:
        const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('Profile Photo',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(
                      context, ImageSource.gallery),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDEFF6E)
                          .withOpacity(0.08),
                      borderRadius:
                      BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFDEFF6E)
                              .withOpacity(0.25)),
                    ),
                    child: Column(children: [
                      Text('Gallery',
                          style: GoogleFonts.inter(
                              color: const Color(
                                  0xFFDEFF6E),
                              fontSize: 14,
                              fontWeight:
                              FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(
                      context, ImageSource.camera),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color:
                      Colors.white.withOpacity(0.05),
                      borderRadius:
                      BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white
                              .withOpacity(0.1)),
                    ),
                    child: Column(children: [
                      Text('Camera',
                          style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight:
                              FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final image = await _picker.pickImage(
          source: source,
          imageQuality: 75,
          maxWidth: 512);
      if (image == null) return;

      setState(() => _isUploadingPhoto = true);

      final userId = _supabase.auth.currentUser!.id;
      final bytes = await image.readAsBytes();
      String ext = 'jpg';
      final pathParts = image.path.split('.');
      if (pathParts.length > 1) {
        final rawExt = pathParts.last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'webp']
            .contains(rawExt)) ext = rawExt;
      }

      final fileName = '$userId/avatar.$ext';
      await _supabase.storage
          .from('user-avatars')
          .uploadBinary(fileName, bytes,
          fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg'));

      final publicUrl = _supabase.storage
          .from('user-avatars')
          .getPublicUrl(fileName);

      await _supabase.from('users').update(
          {'avatar_url': publicUrl}).eq('id', userId);

      setState(() {
        _avatarUrl = publicUrl;
        _isUploadingPhoto = false;
      });
      _snack('Profile photo updated');
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      _snack('Upload failed: $e', isError: true);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Name cannot be empty', isError: true);
      return;
    }
    if (_phoneCtrl.text.isNotEmpty && _phoneCtrl.text.length != 10) {
      _snack('Phone number must be exactly 10 digits', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('users').update({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      }).eq('id', userId);
      _snack('Profile saved');
    } catch (e) {
      _snack('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

  }

  Future<void> _changePassword() async {
    final pw = _passwordCtrl.text.trim();
    final cpw = _confirmPasswordCtrl.text.trim();
    if (pw.isEmpty) {
      _snack('Enter a new password', isError: true);
      return;
    }
    if (pw.length < 6) {
      _snack('Password must be at least 6 characters',
          isError: true);
      return;
    }
    if (pw != cpw) {
      _snack('Passwords do not match', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _supabase.auth
          .updateUser(UserAttributes(password: pw));
      if (mounted) {
        _passwordCtrl.clear();
        _confirmPasswordCtrl.clear();
        setState(() {});
        _snack('Password changed');
      }
    } catch (e) {
      _snack('Password change failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(24))),
      builder: (_) => Padding(
        padding:
        const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Sign out?',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
            const SizedBox(height: 6),
            Text('You\'ll need to sign back in to access your account.',
                style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 13,
                    height: 1.4)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pop(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    decoration: BoxDecoration(
                      color:
                      Colors.white.withOpacity(0.06),
                      borderRadius:
                      BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white
                              .withOpacity(0.08)),
                    ),
                    child: Center(
                        child: Text('Cancel',
                            style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight:
                                FontWeight.w600))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pop(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444)
                          .withOpacity(0.12),
                      borderRadius:
                      BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFEF4444)
                              .withOpacity(0.4)),
                    ),
                    child: Center(
                        child: Text('Sign out',
                            style: GoogleFonts.inter(
                                color:
                                const Color(0xFFEF4444),
                                fontSize: 14,
                                fontWeight:
                                FontWeight.w700))),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await _supabase.auth.signOut();
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.inter(
              color: isError ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600)),
      backgroundColor: isError
          ? const Color(0xFFEF4444)
          : const Color(0xFFDEFF6E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── BUILD ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(
              color: Color(0xFFDEFF6E),
              strokeWidth: 2))
          : Column(children: [

        // ── Fixed header ───────────────────
        Container(
          color: const Color(0xFF111111),
          padding: EdgeInsets.fromLTRB(
              20, topPad + 16, 20, 16),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text('Profile',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                  Text('Manage your account',
                      style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 13)),
                ],
              ),
            ),
            // Save button in header
            GestureDetector(
              onTap: _isSaving ? null : _saveProfile,
              child: AnimatedContainer(
                duration:
                const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: _isSaving
                      ? const Color(0xFFDEFF6E)
                      .withOpacity(0.5)
                      : const Color(0xFFDEFF6E),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: _isSaving
                    ? const SizedBox(
                    width: 14, height: 14,
                    child:
                    CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2))
                    : Text('Save',
                    style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w700)),
              ),
            ),
          ]),
        ),

        // ── Scrollable content ─────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                20, 8, 20, 40),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                // ── Avatar section ───────────
                _buildAvatarSection(),
                const SizedBox(height: 28),

                // ── Personal info ────────────
                _sectionLabel('Personal Info'),
                const SizedBox(height: 12),
                _buildInfoCard(),
                const SizedBox(height: 28),

                // ── Change password ──────────
                _sectionLabel('Change Password'),
                const SizedBox(height: 12),
                _buildPasswordCard(),
                const SizedBox(height: 12),
                _buildPasswordButton(),
                const SizedBox(height: 28),

                // ── Sign out ─────────────────
                _buildSignOutButton(),
                SizedBox(
                  height: MediaQuery.of(context)
                      .padding.bottom +
                      100,
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ── Avatar ────────────────────────────────────

  Widget _buildAvatarSection() {
    final initials = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text[0].toUpperCase()
        : _email.isNotEmpty
        ? _email[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(children: [

        // Avatar circle
        GestureDetector(
          onTap: _isUploadingPhoto
              ? null
              : _pickAndUploadPhoto,
          child: Stack(children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDEFF6E)
                    .withOpacity(0.1),
                border: Border.all(
                    color: const Color(0xFFDEFF6E)
                        .withOpacity(0.4),
                    width: 2),
              ),
              child: _isUploadingPhoto
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFDEFF6E),
                      strokeWidth: 2))
                  : ClipOval(
                child: _avatarUrl != null &&
                    _avatarUrl!.isNotEmpty
                    ? Image.network(
                  _avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _initialsWidget(
                          initials),
                )
                    : _initialsWidget(initials),
              ),
            ),
            // Edit dot
            Positioned(
              bottom: 2, right: 2,
              child: Container(
                width: 20, height: 20,
                decoration: const BoxDecoration(
                    color: Color(0xFFDEFF6E),
                    shape: BoxShape.circle),
                child: const Icon(Icons.edit_rounded,
                    color: Colors.black, size: 11),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 16),

        // Name + email
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _nameCtrl.text.isNotEmpty
                    ? _nameCtrl.text
                    : 'Your Name',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(_email,
                  style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEFF6E)
                      .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFDEFF6E)
                          .withOpacity(0.25)),
                ),
                child: Text('Space Seeker',
                    style: GoogleFonts.inter(
                        color: const Color(0xFFDEFF6E),
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _initialsWidget(String initials) => Center(
    child: Text(initials,
        style: GoogleFonts.inter(
            color: const Color(0xFFDEFF6E),
            fontSize: 26,
            fontWeight: FontWeight.w800)),
  );

  // ── Info card ─────────────────────────────────

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(children: [

        // Email read-only
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text('Email',
                      style: GoogleFonts.inter(
                          color: Colors.white24,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 3),
                  Text(_email,
                      style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 14)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Read only',
                  style: GoogleFonts.inter(
                      color: Colors.white24,
                      fontSize: 9,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 10),

        // Name field
        _darkField(
          controller: _nameCtrl,
          label: 'Full Name',
          hint: 'Enter your name',
        ),
        const SizedBox(height: 10),

        // Phone field
        _darkField(
          controller: _phoneCtrl,
          label: 'Phone Number',
          hint: 'Enter your phone',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
      ]),
    );
  }

  // ── Password card ─────────────────────────────

  Widget _buildPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(children: [
        _darkField(
          controller: _passwordCtrl,
          label: 'New Password',
          hint: 'Min. 8 characters',
          obscure: !_showPassword,
          suffix: GestureDetector(
            onTap: () => setState(
                    () => _showPassword = !_showPassword),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                  _showPassword ? 'Hide' : 'Show',
                  style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _darkField(
          controller: _confirmPasswordCtrl,
          label: 'Confirm Password',
          hint: 'Repeat new password',
          obscure: !_showConfirmPassword,
          suffix: GestureDetector(
            onTap: () => setState(() =>
            _showConfirmPassword =
            !_showConfirmPassword),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                  _showConfirmPassword ? 'Hide' : 'Show',
                  style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildPasswordButton() => GestureDetector(
    onTap: _isSaving ? null : _changePassword,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.white.withOpacity(0.09)),
      ),
      child: Center(
        child: Text('Update Password',
            style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ),
    ),
  );

  // ── Sign out ──────────────────────────────────

  Widget _buildSignOutButton() => GestureDetector(
    onTap: _signOut,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFEF4444)
                .withOpacity(0.25)),
      ),
      child: Center(
        child: Text('Sign Out',
            style: GoogleFonts.inter(
                color: const Color(0xFFEF4444),
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ),
    ),
  );

  // ── Shared field ──────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: GoogleFonts.inter(
        color: Colors.white54,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4),
  );

  Widget _darkField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            obscureText: obscure,
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                  color: Colors.white24, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }
}
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../utils/constants.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import 'auth/login_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // ── Profile Tab Controllers ────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  final _birthdayCtrl = TextEditingController();

  // ── Health Tab Controllers ─────────────────────────────────────────────────
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  // ── Separate edit modes for each tab ──────────────────────────────────────
  bool _editModeProfile = false;
  bool _editModeHealth = false;

  // ── Web photo handling ─────────────────────────────────────────────────────
  Uint8List? _webImageBytes;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _populateFields());
  }

  void _populateFields() {
    final u = context.read<AuthViewModel>().currentUser;
    if (u == null) return;
    _nameCtrl.text = u.displayName ?? '';
    _phoneCtrl.text = u.phone ?? '';
    _bioCtrl.text = u.bio ?? '';
    _locationCtrl.text = u.location ?? '';
    _jobCtrl.text = u.jobTitle ?? '';
    _birthdayCtrl.text = u.birthday ?? '';
    _ageCtrl.text = u.age?.toString() ?? '';
    _weightCtrl.text = u.weight?.toString() ?? '';

    // ── FIX 5: On web, restore photo from saved base64 photoUrl ───────────
    if (kIsWeb) {
      final photoUrl = u.photoUrl;
      if (photoUrl != null && photoUrl.startsWith('data:')) {
        try {
          final base64Data = photoUrl.split(',').last;
          _webImageBytes = base64Decode(base64Data);
        } catch (_) {
          _webImageBytes = null;
        }
      }
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _jobCtrl.dispose();
    _birthdayCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // ── Photo picker ───────────────────────────────────────────────────────────
  Future<void> _showPhotoPicker() async {
    final auth = context.read<AuthViewModel>();
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Change Photo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (!kIsWeb)
              _SheetTile(
                icon: Icons.camera_alt_rounded,
                color: cs.primary,
                label: 'Take Photo',
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.camera, auth);
                },
              ),
            _SheetTile(
              icon: Icons.photo_library_rounded,
              color: cs.secondary,
              label: 'Choose from Gallery',
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery, auth);
              },
            ),
            if (auth.currentUser?.localPhotoPath != null ||
                auth.currentUser?.photoUrl != null ||
                _webImageBytes != null)
              _SheetTile(
                icon: Icons.delete_outline_rounded,
                color: Colors.red,
                label: 'Remove Photo',
                onTap: () async {
                  Navigator.pop(context);
                  setState(() => _webImageBytes = null);
                  await auth.removeLocalPhoto();
                },
              ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource src, AuthViewModel auth) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: src,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;

      if (kIsWeb) {
        // ── FIX 5: Web — encode as base64 and persist to Firestore ────────
        final bytes = await picked.readAsBytes();
        setState(() => _webImageBytes = bytes);

        // Save as base64 data URL so it persists across sessions
        final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        await auth.updatePhotoUrl(base64Str);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo updated!')),
          );
        }
      } else {
        // ── Mobile: save file path ─────────────────────────────────────────
        await auth.updateLocalPhoto(picked.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
    }
  }

  // ── Save profile info ──────────────────────────────────────────────────────
  Future<void> _saveProfileInfo() async {
    await context.read<AuthViewModel>().updatePersonalInfo(
          displayName: _nameCtrl.text,
          phone: _phoneCtrl.text,
          bio: _bioCtrl.text,
          location: _locationCtrl.text,
          jobTitle: _jobCtrl.text,
          birthday: _birthdayCtrl.text,
        );
    if (!mounted) return;
    setState(() => _editModeProfile = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profile info updated!')));
  }

  // ── Save health info ───────────────────────────────────────────────────────
  Future<void> _saveHealthInfo() async {
    final age = int.tryParse(_ageCtrl.text);
    final weight = double.tryParse(_weightCtrl.text);

    if (age == null || age < 5 || age > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid age (5-120)')),
      );
      return;
    }
    if (weight == null || weight < 10 || weight > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight (kg)')),
      );
      return;
    }

    await context.read<AuthViewModel>().updatePersonalInfo(
          age: age,
          weight: weight,
        );
    if (!mounted) return;
    setState(() => _editModeHealth = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Health stats updated!')));
  }

  // ── FIX 5: Avatar builder — web shows base64, mobile shows file ───────────
  Widget _buildAvatar(user, cs, String initials) {
    const size = 96.0;

    // Web: show from memory first (newly picked), then fall back to saved photoUrl
    if (kIsWeb) {
      if (_webImageBytes != null) {
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: MemoryImage(_webImageBytes!),
        );
      }
      // Restore from saved base64 photoUrl
      if (user.photoUrl != null && user.photoUrl!.startsWith('data:')) {
        try {
          final base64Data = user.photoUrl!.split(',').last;
          final bytes = base64Decode(base64Data);
          return CircleAvatar(
            radius: size / 2,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (_) {
          // Fall through to default
        }
      }
      // Google profile photo (network URL)
      if (user.photoUrl != null) {
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: NetworkImage(user.photoUrl!),
        );
      }
    }

    // Mobile: show file image
    if (!kIsWeb && user.localPhotoPath != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: FileImage(File(user.localPhotoPath!)),
      );
    }

    // Network photo (Google profile photo on mobile)
    if (user.photoUrl != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(user.photoUrl!),
      );
    }

    // Default initials avatar
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: cs.primary,
      child: Text(initials,
          style: const TextStyle(
              fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final themeVm = context.watch<ThemeViewModel>();
    final user = auth.currentUser;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }

    final initials =
        (user.displayName?.isNotEmpty == true ? user.displayName! : user.email)
            .substring(0, 1)
            .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.person_rounded), text: 'Profile'),
            Tab(icon: Icon(Icons.monitor_heart_rounded), text: 'Health'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // ── Tab 1: Profile ───────────────────────────────────────────────
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            children: [
              // Avatar
              Center(
                child: GestureDetector(
                  onTap: _showPhotoPicker,
                  child: Stack(children: [
                    _buildAvatar(user, cs, initials),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: isDark ? Colors.black : Colors.white,
                              width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 12),
              Center(
                child: Text(
                  user.displayName ?? user.email,
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              Center(
                child: Text(user.email,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black45)),
              ),

              const SizedBox(height: 24),

              // ── Appearance ───────────────────────────────────────────────
              _SectionHeader(title: 'Appearance', icon: Icons.palette_rounded),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: Text(themeVm.mode == ThemeMode.dark
                        ? 'Currently dark'
                        : 'Currently light'),
                    secondary: Icon(
                        themeVm.mode == ThemeMode.dark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: cs.primary),
                    value: themeVm.mode == ThemeMode.dark,
                    onChanged: (_) => themeVm.toggle(),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Security ─────────────────────────────────────────────────
              _SectionHeader(title: 'Security', icon: Icons.security_rounded),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Fingerprint Login'),
                      subtitle: const Text('Use fingerprint to unlock'),
                      secondary:
                          Icon(Icons.fingerprint_rounded, color: cs.primary),
                      value: user.biometricsEnabled,
                      onChanged: auth.isBusy
                          ? null
                          : (v) => auth.setBiometricsEnabled(v),
                    ),
                    Divider(
                        height: 1,
                        color: isDark ? Colors.white12 : Colors.black12),
                    SwitchListTile(
                      title: const Text('Face ID Login'),
                      subtitle: const Text('Use face recognition to unlock'),
                      secondary: Icon(Icons.face_rounded, color: cs.primary),
                      value: user.biometricsEnabled,
                      onChanged: auth.isBusy
                          ? null
                          : (v) => auth.setBiometricsEnabled(v),
                    ),
                    if (user.biometricsEnabled)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: cs.primary.withOpacity(0.2)),
                          ),
                          child: Row(children: [
                            Icon(Icons.info_outline,
                                size: 14, color: cs.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Both Fingerprint and Face ID use the same toggle. '
                                'Your device will use whichever is available.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Personal Info ────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionHeader(
                      title: 'Personal Info', icon: Icons.badge_rounded),
                  TextButton.icon(
                    onPressed: _editModeProfile
                        ? _saveProfileInfo
                        : () {
                            setState(() => _editModeProfile = true);
                          },
                    icon: Icon(
                      _editModeProfile
                          ? Icons.check_rounded
                          : Icons.edit_rounded,
                      size: 16,
                      color: _editModeProfile ? Colors.green : cs.primary,
                    ),
                    label: Text(
                      _editModeProfile ? 'Save' : 'Edit',
                      style: TextStyle(
                        color: _editModeProfile ? Colors.green : cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _InfoField(
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      ctrl: _nameCtrl,
                      enabled: _editModeProfile,
                    ),
                    _InfoField(
                      label: 'Phone',
                      icon: Icons.phone_outlined,
                      ctrl: _phoneCtrl,
                      enabled: _editModeProfile,
                      type: TextInputType.phone,
                    ),
                    _InfoField(
                      label: 'Bio',
                      icon: Icons.info_outline_rounded,
                      ctrl: _bioCtrl,
                      enabled: _editModeProfile,
                      maxLines: 3,
                    ),
                    _InfoField(
                      label: 'Location',
                      icon: Icons.location_on_outlined,
                      ctrl: _locationCtrl,
                      enabled: _editModeProfile,
                    ),
                    _InfoField(
                      label: 'Job Title',
                      icon: Icons.work_outline_rounded,
                      ctrl: _jobCtrl,
                      enabled: _editModeProfile,
                    ),
                    _InfoField(
                      label: 'Birthday',
                      icon: Icons.cake_outlined,
                      ctrl: _birthdayCtrl,
                      enabled: _editModeProfile,
                    ),
                    if (_editModeProfile)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _editModeProfile = false);
                              _populateFields();
                            },
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey,
                              side: const BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),

              const SizedBox(height: 20),

              // ── Logout ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<AuthViewModel>().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginView()),
                        (_) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ),

          // ── Tab 2: Health ────────────────────────────────────────────────
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            children: [
              // ── Body Stats ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionHeader(
                      title: 'Body Stats', icon: Icons.monitor_weight_outlined),
                  TextButton.icon(
                    onPressed: _editModeHealth
                        ? _saveHealthInfo
                        : () {
                            setState(() => _editModeHealth = true);
                          },
                    icon: Icon(
                      _editModeHealth
                          ? Icons.check_rounded
                          : Icons.edit_rounded,
                      size: 16,
                      color: _editModeHealth ? Colors.green : cs.primary,
                    ),
                    label: Text(
                      _editModeHealth ? 'Save' : 'Edit',
                      style: TextStyle(
                        color: _editModeHealth ? Colors.green : cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                        child: _InfoField(
                          label: 'Age',
                          icon: Icons.cake_outlined,
                          ctrl: _ageCtrl,
                          enabled: _editModeHealth,
                          type: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoField(
                          label: 'Weight (kg)',
                          icon: Icons.monitor_weight_outlined,
                          ctrl: _weightCtrl,
                          enabled: _editModeHealth,
                          type: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                    ]),
                    if (_editModeHealth)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _editModeHealth = false);
                              _populateFields();
                            },
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey,
                              side: const BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    if (user.age != null && user.weight != null) ...[
                      const SizedBox(height: 16),
                      _BmiWidget(age: user.age!, weight: user.weight!),
                    ],
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // ── Age group card ───────────────────────────────────────────
              if (user.age != null)
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: Row(children: [
                            Icon(Icons.people_outline_rounded,
                                color: cs.primary, size: 20),
                            const SizedBox(width: 8),
                            const Text('Age Group',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Icon(Icons.accessibility_new_rounded,
                                color: cs.primary, size: 36),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.age! < 18
                                      ? 'Youth (< 18)'
                                      : user.age! < 50
                                          ? 'Adult (18–49)'
                                          : 'Senior (50+)',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: cs.primary),
                                ),
                                Text(
                                  user.age! < 50
                                      ? 'High-intensity activities recommended'
                                      : 'Low-impact activities recommended',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ]),
                        ),
                      ]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── BMI Widget ────────────────────────────────────────────────────────────────
class _BmiWidget extends StatelessWidget {
  final int age;
  final double weight;
  const _BmiWidget({required this.age, required this.weight});

  @override
  Widget build(BuildContext context) {
    String category;
    Color color;
    if (weight < 50) {
      category = 'Underweight';
      color = Colors.blue;
    } else if (weight < 75) {
      category = 'Normal';
      color = Colors.green;
    } else if (weight < 100) {
      category = 'Overweight';
      color = Colors.orange;
    } else {
      category = 'Obese';
      color = Colors.red;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(Icons.monitor_heart_rounded, color: color, size: 32),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Weight Category',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          Text(category,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text('${weight.toStringAsFixed(1)} kg',
              style: TextStyle(fontSize: 12, color: color)),
        ]),
      ]),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 6),
        Text(title,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.primary,
                letterSpacing: 0.5)),
      ]),
    );
  }
}

// ── Info Field ────────────────────────────────────────────────────────────────
class _InfoField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController ctrl;
  final bool enabled;
  final TextInputType type;
  final int maxLines;

  const _InfoField({
    required this.label,
    required this.icon,
    required this.ctrl,
    required this.enabled,
    this.type = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          enabled: enabled,
          keyboardType: type,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            filled: !enabled,
          ),
        ),
      );
}

// ── Sheet Tile ────────────────────────────────────────────────────────────────
class _SheetTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _SheetTile(
      {required this.icon,
      required this.color,
      required this.label,
      required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: color == Colors.red ? color : null,
            )),
        onTap: onTap,
      );
}

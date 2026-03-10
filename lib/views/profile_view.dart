import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../utils/constants.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../viewmodels/todo_viewmodel.dart';
import 'login_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _bioCtrl      = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _jobCtrl      = TextEditingController();
  final _birthdayCtrl = TextEditingController();
  bool _editMode      = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _populateFields());
  }

  void _populateFields() {
    final u = context.read<AuthViewModel>().currentUser;
    if (u == null) return;
    _nameCtrl.text     = u.displayName ?? '';
    _phoneCtrl.text    = u.phone       ?? '';
    _bioCtrl.text      = u.bio         ?? '';
    _locationCtrl.text = u.location    ?? '';
    _jobCtrl.text      = u.jobTitle    ?? '';
    _birthdayCtrl.text = u.birthday    ?? '';
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
    super.dispose();
  }

  // ── Photo picker ───────────────────────────────────────────────────────────
  Future<void> _showPhotoPicker() async {
    final auth = context.read<AuthViewModel>();
    final cs   = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color:        Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Change Photo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _SheetTile(
              icon: Icons.camera_alt_rounded, color: cs.primary,
              label: 'Take Photo',
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera, auth);
              },
            ),
            _SheetTile(
              icon: Icons.photo_library_rounded, color: cs.secondary,
              label: 'Choose from Gallery',
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery, auth);
              },
            ),
            if (auth.currentUser?.localPhotoPath != null ||
                auth.currentUser?.photoUrl != null)
              _SheetTile(
                icon: Icons.delete_outline_rounded, color: Constants.prioHigh,
                label: 'Remove Photo',
                onTap: () async {
                  Navigator.pop(context);
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
        source: src, maxWidth: 512, maxHeight: 512, imageQuality: 80,
      );
      if (picked == null) return;
      await auth.updateLocalPhoto(picked.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
    }
  }

  // ── Save personal info ─────────────────────────────────────────────────────
  Future<void> _saveInfo() async {
    await context.read<AuthViewModel>().updatePersonalInfo(
      displayName: _nameCtrl.text,
      phone:       _phoneCtrl.text,
      bio:         _bioCtrl.text,
      location:    _locationCtrl.text,
      jobTitle:    _jobCtrl.text,
      birthday:    _birthdayCtrl.text,
    );
    if (!mounted) return;
    setState(() => _editMode = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profile updated!')));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthViewModel>();
    final themeVm = context.watch<ThemeViewModel>();
    final todoVm  = context.watch<TodoViewModel>();
    final user    = auth.currentUser;
    final cs      = Theme.of(context).colorScheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }

    final initials = (user.displayName?.isNotEmpty == true
            ? user.displayName! : user.email)
        .substring(0, 1).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.person_rounded),    text: 'Profile'),
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Analytics'),
          ],
        ),
      ),

      // FAB: Edit / Save — only on Profile tab
      floatingActionButton: _tabs.index == 0
          ? FloatingActionButton.extended(
              heroTag:  'profile_edit_fab',
              onPressed: _editMode
                  ? _saveInfo
                  : () => setState(() => _editMode = true),
              icon:  Icon(_editMode ? Icons.check_rounded : Icons.edit_rounded),
              label: Text(_editMode ? 'Save' : 'Edit Profile'),
              backgroundColor: _editMode ? Constants.prioLow : cs.primary,
            ).animate().scale(duration: 300.ms, curve: Curves.elasticOut)
          : null,

      body: TabBarView(
        controller: _tabs,
        physics:    const NeverScrollableScrollPhysics(),
        children: [

          // ── Tab 1: Profile ────────────────────────────────────────────────
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
                      bottom: 0, right: 0,
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color:  cs.primary,
                          shape:  BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Constants.dsBlack : Colors.white,
                            width: 3,
                          ),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ]),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

              const SizedBox(height: 12),
              Center(
                child: Text(
                  user.displayName ?? user.email.split('@').first,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Center(
                child: Text(user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white60 : Colors.black54,
                    )),
              ),
              if (user.isGoogleUser) ...[
                const SizedBox(height: 6),
                Center(
                  child: Chip(
                    avatar: Icon(Icons.g_mobiledata_rounded,
                        size: 18,
                        color: isDark ? Colors.white : const Color(0xFF333333)),
                    label: Text('Google Account',
                        style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF333333),
                        )),
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.12)
                        : const Color(0xFFEEEEEE),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Appearance ───────────────────────────────────────────────
              _SectionCard(
                title: 'Appearance',
                icon:  Icons.palette_rounded,
                children: [

                  // Dark mode toggle
                  SwitchListTile(
                    value:     themeVm.isDark,
                    onChanged: (v) => themeVm.setDark(v),
                    secondary: Icon(
                      themeVm.isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: cs.secondary, size: 24,
                    ),
                    title: const Text('Dark Mode'),
                    subtitle: Text(
                      themeVm.isDark ? 'Dark theme active' : 'Light theme active',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),

                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // ── Font style — stacked label + full-width dropdown ──────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label row
                        Row(children: [
                          Icon(Icons.text_fields_rounded,
                              color: cs.secondary, size: 22),
                          const SizedBox(width: 10),
                          const Text('Font Style',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 10),

                        // Full-width dropdown container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.07)
                                : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<AppFont>(
                              value:         themeVm.font,
                              isExpanded:    true, // ← key: fills container width
                              isDense:       false,
                              icon: Icon(Icons.keyboard_arrow_down_rounded,
                                  color: cs.secondary, size: 22),
                              dropdownColor: isDark
                                  ? const Color(0xFF1E1E2A)
                                  : Colors.white,
                              borderRadius:  BorderRadius.circular(14),
                              onChanged: (f) {
                                if (f != null) themeVm.setFont(f);
                              },

                              // What shows when dropdown is closed
                              selectedItemBuilder: (ctx) =>
                                  AppFont.values.map((f) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        f.label,
                                        style: GoogleFonts.getFont(
                                          f.googleFontsKey,
                                          textStyle: TextStyle(
                                            fontSize:   15,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0D0D0D),
                                          ),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),

                              // Dropdown list items
                              items: AppFont.values.map((f) {
                                final isSel = themeVm.font == f;
                                return DropdownMenuItem<AppFont>(
                                  value: f,
                                  child: Row(children: [
                                    // Aa preview box
                                    Container(
                                      width: 40, height: 40,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? cs.primary.withOpacity(0.12)
                                            : (isDark
                                                ? Colors.white10
                                                : Colors.black.withOpacity(0.06)),
                                        borderRadius: BorderRadius.circular(8),
                                        border: isSel
                                            ? Border.all(
                                                color: cs.primary.withOpacity(0.4))
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Aa',
                                        style: GoogleFonts.getFont(
                                          f.googleFontsKey,
                                          textStyle: TextStyle(
                                            fontSize:   16,
                                            fontWeight: FontWeight.w800,
                                            color: isSel
                                                ? cs.primary
                                                : (isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0D0D0D)),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Font name + description
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            f.label,
                                            style: GoogleFonts.getFont(
                                              f.googleFontsKey,
                                              textStyle: TextStyle(
                                                fontSize:   14,
                                                fontWeight: FontWeight.w700,
                                                color: isSel
                                                    ? cs.primary
                                                    : (isDark
                                                        ? Colors.white
                                                        : const Color(0xFF0D0D0D)),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            f.description,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.black38,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Checkmark
                                    if (isSel)
                                      Icon(Icons.check_rounded,
                                          color: cs.primary, size: 18),
                                  ]),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 16),

              // ── Security ─────────────────────────────────────────────────
              _SectionCard(
                title: 'Security',
                icon:  Icons.security_rounded,
                children: [
                  SwitchListTile(
                    value:     user.biometricsEnabled,
                    onChanged: (v) => auth.setBiometricsEnabled(v),
                    secondary: Icon(Icons.fingerprint_rounded,
                        color: cs.secondary, size: 24),
                    title: const Text('Biometric Unlock'),
                    subtitle: Text(
                      auth.biometricsAvailable
                          ? 'Use fingerprint to unlock'
                          : 'Not available on this device',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 16),

              // ── Personal info ─────────────────────────────────────────────
              _SectionCard(
                title: 'Personal Info',
                icon:  Icons.edit_note_rounded,
                children: [
                  _InfoField(label: 'Display Name', controller: _nameCtrl,
                      icon: Icons.person_outline_rounded, enabled: _editMode),
                  _InfoField(label: 'Phone',         controller: _phoneCtrl,
                      icon: Icons.phone_outlined,        enabled: _editMode,
                      keyboard: TextInputType.phone),
                  _InfoField(label: 'Job Title',     controller: _jobCtrl,
                      icon: Icons.work_outline_rounded,  enabled: _editMode),
                  _InfoField(label: 'Location',      controller: _locationCtrl,
                      icon: Icons.location_on_outlined,  enabled: _editMode),
                  _InfoField(label: 'Birthday',      controller: _birthdayCtrl,
                      icon: Icons.cake_outlined,         enabled: _editMode,
                      hint: 'e.g. Jan 1, 1990'),
                  _InfoField(label: 'Bio',           controller: _bioCtrl,
                      icon: Icons.notes_rounded,         enabled: _editMode,
                      maxLines: 3),
                  const SizedBox(height: 8),
                ],
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),

              // Sign out
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        icon: const Icon(Icons.logout_rounded,
                            color: Constants.prioHigh, size: 36),
                        title: const Text('Sign Out?',
                            textAlign: TextAlign.center),
                        content: const Text(
                          'You will need to log in again to access your tasks.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13),
                        ),
                        actionsAlignment: MainAxisAlignment.center,
                        actions: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 12),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Constants.prioHigh,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            icon: const Icon(Icons.logout_rounded,
                                size: 18, color: Colors.white),
                            label: const Text('Sign Out',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !mounted) return;
                    await auth.logout();
                    if (!mounted) return;
                    Navigator.of(context, rootNavigator: true)
                        .pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const LoginView()),
                      (_) => false,
                    );
                  },
                  icon:  const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Constants.prioHigh,
                    side: const BorderSide(color: Constants.prioHigh),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms),
            ],
          ),

          // ── Tab 2: Analytics ──────────────────────────────────────────────
          _AnalyticsTab(todoVm: todoVm),
        ],
      ),
    );
  }

  Widget _buildAvatar(user, ColorScheme cs, String initials) {
    if (user.localPhotoPath != null) {
      return CircleAvatar(radius: 54,
          backgroundImage: FileImage(File(user.localPhotoPath!)),
          backgroundColor: cs.primary);
    }
    if (user.photoUrl != null) {
      return CircleAvatar(radius: 54,
          backgroundImage: NetworkImage(user.photoUrl!),
          backgroundColor: cs.primary);
    }
    return CircleAvatar(
      radius: 54,
      backgroundColor: cs.primary,
      child: Text(initials,
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800,
              color: Colors.white)),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String       title;
  final IconData     icon;
  final List<Widget> children;
  const _SectionCard({
    required this.title, required this.icon, required this.children,
  });
  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Constants.dsSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.07),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Icon(icon, size: 20, color: cs.secondary),
            const SizedBox(width: 8),
            Text(title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ]),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        ...children,
      ]),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String               label;
  final TextEditingController controller;
  final IconData             icon;
  final bool                 enabled;
  final TextInputType?       keyboard;
  final int                  maxLines;
  final String?              hint;
  const _InfoField({
    required this.label, required this.controller,
    required this.icon,  required this.enabled,
    this.keyboard, this.maxLines = 1, this.hint,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: TextField(
        controller:   controller,
        enabled:      enabled,
        keyboardType: keyboard,
        maxLines:     maxLines,
        style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF0D0D0D),
        ),
        decoration: InputDecoration(
          labelText:  label,
          hintText:   hint,
          prefixIcon: Icon(icon, size: 20),
          filled:     true,
          fillColor: enabled
              ? (isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFF0F0F0))
              : Colors.transparent,
          border: enabled
              ? OutlineInputBorder(borderRadius: BorderRadius.circular(14))
              : InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon; final Color color;
  final String label;  final VoidCallback onTap;
  const _SheetTile({required this.icon, required this.color,
      required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label,
            style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 15,
              color: color == Constants.prioHigh ? color : null,
            )),
        onTap: onTap,
      );
}

// ── Analytics tab ─────────────────────────────────────────────────────────────

class _AnalyticsTab extends StatelessWidget {
  final TodoViewModel todoVm;
  const _AnalyticsTab({required this.todoVm});

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total  = todoVm.totalCount;
    double pct(int n) => total == 0 ? 0 : n / total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        Row(children: [
          _StatCard(label: 'Total',   value: total.toString(),
              color: cs.primary,     icon: Icons.list_rounded),
          const SizedBox(width: 10),
          _StatCard(label: 'Done',
              value: todoVm.completedCount.toString(),
              color: Constants.prioLow, icon: Icons.check_circle_rounded),
          const SizedBox(width: 10),
          _StatCard(label: 'Pending',
              value: todoVm.pendingCount.toString(),
              color: Constants.prioMedium, icon: Icons.pending_rounded),
        ]).animate().fadeIn(delay: 50.ms),

        const SizedBox(height: 10),

        Row(children: [
          _StatCard(label: 'Overdue',
              value: todoVm.overdueCount.toString(),
              color: Constants.prioHigh, icon: Icons.warning_amber_rounded),
          const SizedBox(width: 10),
          _StatCard(label: 'Pinned',
              value: todoVm.pinnedCount.toString(),
              color: cs.secondary, icon: Icons.push_pin_rounded),
          const SizedBox(width: 10),
          const Expanded(child: SizedBox()),
        ]).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 20),

        _SectionCard(
          title: 'Completion',
          icon:  Icons.donut_large_rounded,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${todoVm.completedCount} of $total completed',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(
                        total == 0 ? '—'
                            : '${(pct(todoVm.completedCount) * 100).round()}%',
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700, color: cs.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value:           pct(todoVm.completedCount),
                      minHeight:       10,
                      backgroundColor: isDark ? Colors.white12 : Colors.black12,
                      valueColor: const AlwaysStoppedAnimation(
                          Constants.prioLow),
                    ),
                  ),
                  if (todoVm.overdueCount > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value:           pct(todoVm.overdueCount),
                        minHeight:       10,
                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                        valueColor: const AlwaysStoppedAnimation(
                            Constants.prioHigh),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('overdue',
                        style: TextStyle(fontSize: 12,
                            color: Constants.prioHigh,
                            fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ],
        ).animate().fadeIn(delay: 150.ms),

        const SizedBox(height: 16),

        _SectionCard(
          title: 'By Priority',
          icon:  Icons.flag_rounded,
          children: [
            _PriorityRow(label: 'High',   color: Constants.prioHigh,
                count: todoVm.todos.where((t) => t.priority == 'High').length,
                total: total),
            _PriorityRow(label: 'Medium', color: Constants.prioMedium,
                count: todoVm.todos.where((t) => t.priority == 'Medium').length,
                total: total),
            _PriorityRow(label: 'Low',    color: Constants.prioLow,
                count: todoVm.todos.where((t) => t.priority == 'Low').length,
                total: total),
            const SizedBox(height: 8),
          ],
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label; final String value;
  final Color color;  final IconData icon;
  const _StatCard({required this.label, required this.value,
      required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 24,
              fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black54)),
        ]),
      ),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  final String label; final Color color;
  final int count;    final int total;
  const _PriorityRow({required this.label, required this.color,
      required this.count, required this.total});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct    = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(children: [
        SizedBox(width: 56,
            child: Text(label, style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: color))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct, minHeight: 8,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$count', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}
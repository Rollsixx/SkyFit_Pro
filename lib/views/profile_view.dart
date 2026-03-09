import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/todo_model.dart';
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
  late TabController _tabController;

  // ── Edit form controllers ──────────────────────────────────────────────────
  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _bioCtrl      = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _jobCtrl      = TextEditingController();
  String? _selectedBirthday;
  bool    _editMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserIntoForm();
  }

  void _loadUserIntoForm() {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return;
    _nameCtrl.text     = user.displayName ?? '';
    _phoneCtrl.text    = user.phone       ?? '';
    _bioCtrl.text      = user.bio         ?? '';
    _locationCtrl.text = user.location    ?? '';
    _jobCtrl.text      = user.jobTitle    ?? '';
    _selectedBirthday  = user.birthday;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _jobCtrl.dispose();
    super.dispose();
  }

  // ── Save profile ───────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    await context.read<AuthViewModel>().updatePersonalInfo(
      displayName: _nameCtrl.text,
      phone:       _phoneCtrl.text,
      bio:         _bioCtrl.text,
      location:    _locationCtrl.text,
      jobTitle:    _jobCtrl.text,
      birthday:    _selectedBirthday ?? '',
    );
    setState(() => _editMode = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
    }
  }

  // ── Pick birthday ──────────────────────────────────────────────────────────
  Future<void> _pickBirthday() async {
    final initial = _selectedBirthday != null
        ? DateTime.tryParse(_selectedBirthday!) ?? DateTime(1995)
        : DateTime(1995);

    final picked = await showDatePicker(
      context:   context,
      initialDate: initial,
      firstDate:   DateTime(1900),
      lastDate:    DateTime.now(),
      helpText:    'Select Birthday',
    );
    if (picked != null) {
      setState(() => _selectedBirthday = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Constants.prioHigh),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthViewModel>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  // ── Analytics helpers ──────────────────────────────────────────────────────

  /// Todos completed this week (Mon–Sun)
  int _completedThisWeek(List<TodoModel> todos) {
    final now       = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start     = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return todos.where((t) =>
      t.completed && t.updatedAt.isAfter(start),
    ).length;
  }

  /// Todos created this week
  int _createdThisWeek(List<TodoModel> todos) {
    final now       = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start     = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return todos.where((t) => t.createdAt.isAfter(start)).length;
  }

  /// Completion rate 0.0–1.0
  double _completionRate(List<TodoModel> todos) {
    if (todos.isEmpty) return 0;
    return todos.where((t) => t.completed).length / todos.length;
  }

  /// Count by priority
  Map<String, int> _byPriority(List<TodoModel> todos) {
    final pending = todos.where((t) => !t.completed).toList();
    return {
      'High':   pending.where((t) => t.priority == 'High').length,
      'Medium': pending.where((t) => t.priority == 'Medium').length,
      'Low':    pending.where((t) => t.priority == 'Low').length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthViewModel>();
    final themeVm = context.watch<ThemeViewModel>();
    final todoVm  = context.watch<TodoViewModel>();
    final user    = auth.currentUser;
    final cs      = Theme.of(context).colorScheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final todos   = todoVm.todos;

    final name  = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    final email = user?.email ?? '';
    final photo = user?.photoUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_editMode)
            IconButton(
              icon:     const Icon(Icons.edit_rounded),
              tooltip:  'Edit profile',
              onPressed: () => setState(() => _editMode = true),
            )
          else ...[
            TextButton(
              onPressed: () {
                _loadUserIntoForm();
                setState(() => _editMode = false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _saveProfile,
              child: Text('Save', style: TextStyle(color: cs.secondary, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline_rounded),  text: 'Profile'),
            Tab(icon: Icon(Icons.bar_chart_rounded),        text: 'Analytics'),
          ],
          indicatorColor: cs.primary,
          labelColor:     cs.primary,
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          // ════════════════════════════════════════
          //  TAB 1 — PROFILE
          // ════════════════════════════════════════
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Avatar ───────────────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.secondary],
                          begin:  Alignment.topLeft,
                          end:    Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: cs.primary.withOpacity(0.4), blurRadius: 20),
                        ],
                      ),
                      child: photo != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl:    photo,
                                fit:         BoxFit.cover,
                                placeholder: (_, __) => const Icon(Icons.person_rounded, size: 50, color: Colors.white),
                                errorWidget: (_, __, ___) => const Icon(Icons.person_rounded, size: 50, color: Colors.white),
                              ),
                            )
                          : const Icon(Icons.person_rounded, size: 50, color: Colors.white),
                    ),
                    if (user?.isGoogleUser == true)
                      Positioned(
                        bottom: 2, right: 2,
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color:  Colors.white,
                            shape:  BoxShape.circle,
                            border: Border.all(color: cs.secondary, width: 2),
                          ),
                          child: Icon(Icons.g_mobiledata_rounded, size: 14, color: cs.secondary),
                        ),
                      ),
                  ],
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

              const SizedBox(height: 8),

              // Member since badge
              if (user?.memberSince != null)
                Center(
                  child: Text(
                    'Member since ${DateFormat('MMMM yyyy').format(user!.memberSince!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // ── Personal info ─────────────────────────────────────────
              _sectionLabel('Personal Information', isDark),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoField(
                        icon:       Icons.badge_outlined,
                        label:      'Display Name',
                        value:      user?.displayName,
                        controller: _nameCtrl,
                        editMode:   _editMode,
                        hint:       'Your full name',
                      ),
                      _divider(),
                      _InfoField(
                        icon:       Icons.work_outline_rounded,
                        label:      'Job Title',
                        value:      user?.jobTitle,
                        controller: _jobCtrl,
                        editMode:   _editMode,
                        hint:       'e.g. Software Developer',
                      ),
                      _divider(),
                      _InfoField(
                        icon:       Icons.location_on_outlined,
                        label:      'Location',
                        value:      user?.location,
                        controller: _locationCtrl,
                        editMode:   _editMode,
                        hint:       'City, Country',
                      ),
                      _divider(),
                      _InfoField(
                        icon:       Icons.phone_outlined,
                        label:      'Phone',
                        value:      user?.phone,
                        controller: _phoneCtrl,
                        editMode:   _editMode,
                        hint:       '+63 912 345 6789',
                        keyboardType: TextInputType.phone,
                      ),
                      _divider(),

                      // Birthday (special: uses date picker)
                      _editMode
                          ? ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.cake_outlined, color: cs.primary),
                              title: const Text('Birthday'),
                              subtitle: Text(
                                _selectedBirthday != null
                                    ? DateFormat('MMMM d, yyyy').format(DateTime.parse(_selectedBirthday!))
                                    : 'Tap to set birthday',
                                style: TextStyle(
                                  color: _selectedBirthday != null
                                      ? (isDark ? Colors.white70 : Colors.black87)
                                      : Colors.grey,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: _pickBirthday,
                            )
                          : _InfoField(
                              icon:  Icons.cake_outlined,
                              label: 'Birthday',
                              value: user?.birthday != null
                                  ? DateFormat('MMMM d, yyyy').format(DateTime.parse(user!.birthday!))
                                  : null,
                              controller: TextEditingController(),
                              editMode:   false,
                              hint:       'Not set',
                            ),

                      _divider(),
                      _InfoField(
                        icon:       Icons.info_outline_rounded,
                        label:      'Bio',
                        value:      user?.bio,
                        controller: _bioCtrl,
                        editMode:   _editMode,
                        hint:       'Tell something about yourself...',
                        maxLines:   3,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 20),

              // ── Account info ──────────────────────────────────────────
              _sectionLabel('Account', isDark),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.alternate_email_rounded, color: cs.primary),
                      title:   const Text('Email'),
                      subtitle: Text(email, style: const TextStyle(fontSize: 12)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.shield_outlined, color: cs.primary),
                      title:   const Text('Encryption'),
                      subtitle: const Text('AES-256-GCM • PBKDF2', style: TextStyle(fontSize: 12)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.lock_clock_outlined, color: cs.primary),
                      title:   const Text('Auto-lock'),
                      subtitle: Text(
                        'After ${Constants.inactivityTimeoutSeconds}s of inactivity',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 20),

              // ── Preferences ───────────────────────────────────────────
              _sectionLabel('Preferences', isDark),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: cs.primary,
                      ),
                      title:    const Text('Dark Mode'),
                      value:    themeVm.isDark,
                      onChanged: themeVm.setDark,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Icon(Icons.fingerprint_rounded, color: cs.primary),
                      title:    const Text('Biometric Unlock'),
                      subtitle: Text(
                        user?.hasLoggedInOnce == true
                            ? 'Unlock without password'
                            : 'Complete one login first',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value:    user?.biometricsEnabled ?? false,
                      onChanged: user?.hasLoggedInOnce == true
                          ? (v) => auth.setBiometricsEnabled(v)
                          : null,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),

              // ── Logout ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon:      const Icon(Icons.logout_rounded),
                  label:     const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Constants.prioHigh,
                    side:    const BorderSide(color: Constants.prioHigh),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 32),
            ],
          ),

          // ════════════════════════════════════════
          //  TAB 2 — ANALYTICS
          // ════════════════════════════════════════
          ListView(
            padding: const EdgeInsets.all(20),
            children: [

              // ── This week summary ─────────────────────────────────────
              _sectionLabel('This Week', isDark),
              Row(
                children: [
                  Expanded(
                    child: _BigStatCard(
                      value: _createdThisWeek(todos).toString(),
                      label: 'Created',
                      icon:  Icons.add_task_rounded,
                      color: cs.secondary,
                    ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.15, end: 0),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BigStatCard(
                      value: _completedThisWeek(todos).toString(),
                      label: 'Completed',
                      icon:  Icons.task_alt_rounded,
                      color: Constants.prioLow,
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.15, end: 0),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Overall stats ─────────────────────────────────────────
              _sectionLabel('Overall', isDark),
              GridView.count(
                crossAxisCount:   2,
                shrinkWrap:       true,
                physics:          const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing:  12,
                childAspectRatio: 1.6,
                children: [
                  _StatCard(
                    value: todoVm.totalCount.toString(),
                    label: 'Total Tasks',
                    icon:  Icons.list_alt_rounded,
                    color: cs.primary,
                  ),
                  _StatCard(
                    value: todoVm.completedCount.toString(),
                    label: 'Completed',
                    icon:  Icons.check_circle_outline_rounded,
                    color: Constants.prioLow,
                  ),
                  _StatCard(
                    value: todoVm.pendingCount.toString(),
                    label: 'Pending',
                    icon:  Icons.pending_outlined,
                    color: Colors.blueGrey,
                  ),
                  _StatCard(
                    value: todoVm.overdueCount.toString(),
                    label: 'Overdue',
                    icon:  Icons.warning_amber_rounded,
                    color: Constants.prioHigh,
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 20),

              // ── Completion rate ───────────────────────────────────────
              _sectionLabel('Completion Rate', isDark),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(_completionRate(todos) * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize:   36,
                              fontWeight: FontWeight.w900,
                              color:      cs.primary,
                            ),
                          ),
                          Text(
                            '${todoVm.completedCount} of ${todoVm.totalCount} tasks',
                            style: TextStyle(
                              color:    isDark ? Colors.white54 : Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value:           _completionRate(todos),
                          minHeight:       14,
                          backgroundColor: isDark ? Colors.white12 : Colors.black12,
                          valueColor:      AlwaysStoppedAnimation<Color>(cs.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _completionRate(todos) >= 0.8
                            ? '🎉 Excellent work! Keep it up!'
                            : _completionRate(todos) >= 0.5
                                ? '👍 Good progress! You\'re halfway there.'
                                : todoVm.totalCount == 0
                                    ? '📝 Start adding tasks to track your progress.'
                                    : '💪 Keep going! You can do it.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 20),

              // ── Pending by priority ───────────────────────────────────
              _sectionLabel('Pending by Priority', isDark),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _byPriority(todos).entries.map((e) {
                      final color = e.key == 'High'
                          ? Constants.prioHigh
                          : e.key == 'Medium'
                              ? Constants.prioMedium
                              : Constants.prioLow;
                      final total = todoVm.pendingCount;
                      final ratio = total == 0 ? 0.0 : e.value / total;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 10, height: 10,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color:  color,
                                        shape:  BoxShape.circle,
                                      ),
                                    ),
                                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                Text(
                                  '${e.value} task${e.value == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value:           ratio,
                                minHeight:       8,
                                backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
                                valueColor:      AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 20),

              // ── Recent activity ───────────────────────────────────────
              _sectionLabel('Recent Activity', isDark),
              Card(
                child: todos.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child:   Center(
                          child: Text(
                            'No tasks yet.\nAdd your first todo to see activity here.',
                            textAlign: TextAlign.center,
                            style:     TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : Column(
                        children: todos.take(5).toList().asMap().entries.map((e) {
                          final i    = e.key;
                          final todo = e.value;
                          return Column(
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: todo.completed
                                      ? Constants.prioLow.withOpacity(0.15)
                                      : cs.primary.withOpacity(0.12),
                                  child: Icon(
                                    todo.completed
                                        ? Icons.check_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size:  16,
                                    color: todo.completed ? Constants.prioLow : cs.primary,
                                  ),
                                ),
                                title: Text(
                                  todo.title,
                                  style: TextStyle(
                                    fontSize:   13,
                                    fontWeight: FontWeight.w600,
                                    decoration: todo.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: todo.completed
                                        ? (isDark ? Colors.white38 : Colors.black38)
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  _timeAgo(todo.updatedAt),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:        _priorityColor(todo.priority).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    todo.priority,
                                    style: TextStyle(
                                      fontSize:   10,
                                      fontWeight: FontWeight.w700,
                                      color:      _priorityColor(todo.priority),
                                    ),
                                  ),
                                ),
                              ),
                              if (i < todos.take(5).length - 1) const Divider(height: 1),
                            ],
                          );
                        }).toList(),
                      ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String title, bool isDark) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize:      11,
            fontWeight:    FontWeight.w700,
            letterSpacing: 1.2,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      );

  Widget _divider() => const Divider(height: 16, indent: 32);

  Color _priorityColor(String p) => p == 'High'
      ? Constants.prioHigh
      : p == 'Medium'
          ? Constants.prioMedium
          : Constants.prioLow;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

// ── Reusable widgets ───────────────────────────────────────────────────────

class _InfoField extends StatelessWidget {
  final IconData             icon;
  final String               label;
  final String?              value;
  final TextEditingController controller;
  final bool                 editMode;
  final String               hint;
  final int                  maxLines;
  final TextInputType?       keyboardType;

  const _InfoField({
    required this.icon,
    required this.label,
    required this.value,
    required this.controller,
    required this.editMode,
    required this.hint,
    this.maxLines    = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (editMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: TextField(
          controller:   controller,
          maxLines:     maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText:  label,
            prefixIcon: Icon(icon, size: 18),
            hintText:   hint,
            isDense:    true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: cs.primary, size: 20),
      title:   Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(
        value?.isNotEmpty == true ? value! : hint,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: value?.isNotEmpty == true
              ? (isDark ? Colors.white : Colors.black87)
              : Colors.grey,
        ),
      ),
      dense: true,
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color  color;
  const _BigStatCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String   value;
  final String   label;
  final IconData icon;
  final Color    color;
  const _StatCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color:        color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment:  MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
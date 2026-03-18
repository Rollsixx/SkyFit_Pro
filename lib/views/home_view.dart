import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import 'login_view.dart';
import 'profile_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final themeVm = context.watch<ThemeViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Icon(Icons.fitness_center_rounded, color: cs.primary, size: 22),
          const SizedBox(width: 8),
          const Text('SkyFit Pro',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        actions: [
          IconButton(
            icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: themeVm.toggle,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileView()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome Card ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${user?.displayName ?? user?.email ?? 'Athlete'}! 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ready for your workout today?',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Weather Card ───────────────────────────────────────────────
            Text('Today\'s Weather',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.blue.shade100,
                ),
              ),
              child: const Row(children: [
                Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 40),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weather coming soon...',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    Text('OpenWeatherMap integration pending',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ]),
            ),

            const SizedBox(height: 24),

            // ── Activity Card ──────────────────────────────────────────────
            Text('Suggested Activity',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.green.shade100,
                ),
              ),
              child: const Row(children: [
                Icon(Icons.directions_run_rounded,
                    color: Colors.green, size: 40),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Activity coming soon...',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    Text('Based on weather + your profile',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ]),
            ),

            const SizedBox(height: 32),

            // ── Logout ─────────────────────────────────────────────────────
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
      ),
    );
  }
}

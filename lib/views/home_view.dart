import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/activity_model.dart';
import '../models/weather_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../viewmodels/weather_viewmodel.dart';
import 'login_view.dart';
import 'profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWeather());
  }

  Future<void> _loadWeather() async {
    final user = context.read<AuthViewModel>().currentUser;
    final weatherVm = context.read<WeatherViewModel>();
    await weatherVm.fetchWeather(user);
  }

  Future<void> _refreshWeather() async {
    final user = context.read<AuthViewModel>().currentUser;
    final weatherVm = context.read<WeatherViewModel>();
    await weatherVm.refresh(user);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final themeVm = context.watch<ThemeViewModel>();
    final weatherVm = context.watch<WeatherViewModel>();
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
          // ── Refresh weather ──────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: weatherVm.isBusy ? null : _refreshWeather,
            tooltip: 'Refresh weather',
          ),
          // ── Theme toggle ─────────────────────────────────────────────
          IconButton(
            icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: themeVm.toggle,
          ),
          // ── Profile ──────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileView()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshWeather,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome Card ───────────────────────────────────────────
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
                      'Hello, ${user?.displayName ?? user?.email?.split('@')[0] ?? 'Athlete'}! 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.age != null && user?.weight != null
                          ? 'Age: ${user!.age} • Weight: ${user.weight} kg'
                          : 'Set your age & weight in Profile for better suggestions!',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // ── Weather Section ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Today\'s Weather',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  if (weatherVm.isBusy)
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (weatherVm.isBusy)
                _LoadingCard(isDark: isDark)
              else if (weatherVm.error != null)
                _ErrorCard(
                  error: weatherVm.error!,
                  isDark: isDark,
                  onRetry: _refreshWeather,
                )
              else if (weatherVm.weather != null)
                _WeatherCard(
                  weather: weatherVm.weather!,
                  isDark: isDark,
                  cs: cs,
                ).animate().fadeIn(delay: 200.ms)
              else
                _EmptyWeatherCard(isDark: isDark),

              const SizedBox(height: 24),

              // ── Activity Section ───────────────────────────────────────
              Text('Suggested Activity',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              if (weatherVm.isBusy)
                _LoadingCard(isDark: isDark)
              else if (weatherVm.activity != null)
                _ActivityCard(
                  activity: weatherVm.activity!,
                  isDark: isDark,
                  cs: cs,
                ).animate().fadeIn(delay: 300.ms)
              else
                _NoActivityCard(
                  isDark: isDark,
                  hasProfile: user?.age != null && user?.weight != null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Weather Card ──────────────────────────────────────────────────────────────
class _WeatherCard extends StatelessWidget {
  final WeatherModel weather;
  final bool isDark;
  final ColorScheme cs;
  const _WeatherCard({
    required this.weather,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.blue.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text(weather.weatherEmoji,
                    style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(weather.cityName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(weather.description.toUpperCase(),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : Colors.black45,
                            letterSpacing: 1)),
                  ],
                ),
              ]),
              Text('${weather.temperature.round()}°C',
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: cs.primary)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeatherStat(
                icon: Icons.thermostat_rounded,
                label: 'Feels Like',
                value: '${weather.feelsLike.round()}°C',
                color: Colors.orange,
              ),
              _WeatherStat(
                icon: Icons.water_drop_rounded,
                label: 'Humidity',
                value: '${weather.humidity}%',
                color: Colors.blue,
              ),
              _WeatherStat(
                icon: Icons.air_rounded,
                label: 'Wind',
                value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
                color: Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Weather Stat ──────────────────────────────────────────────────────────────
class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _WeatherStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]);
}

// ── Activity Card ─────────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  final bool isDark;
  final ColorScheme cs;
  const _ActivityCard({
    required this.activity,
    required this.isDark,
    required this.cs,
  });

  Color get _intensityColor {
    switch (activity.intensity) {
      case 'High':
        return Colors.red;
      case 'Moderate':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.green.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(activity.icon, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _intensityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: _intensityColor.withOpacity(0.4)),
                      ),
                      child: Text(activity.intensity,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _intensityColor)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(children: [
                        const Icon(Icons.timer_outlined,
                            size: 11, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(activity.duration,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ]),
                    ),
                  ]),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(activity.description,
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.5)),
        ],
      ),
    );
  }
}

// ── Loading Card ──────────────────────────────────────────────────────────────
class _LoadingCard extends StatelessWidget {
  final bool isDark;
  const _LoadingCard({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Fetching weather...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
}

// ── Error Card ────────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String error;
  final bool isDark;
  final VoidCallback onRetry;
  const _ErrorCard({
    required this.error,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 36),
          const SizedBox(height: 8),
          const Text('Could not load weather',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red)),
          const SizedBox(height: 4),
          Text(error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ]),
      );
}

// ── Empty Weather Card ────────────────────────────────────────────────────────
class _EmptyWeatherCard extends StatelessWidget {
  final bool isDark;
  const _EmptyWeatherCard({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(children: [
          Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 36),
          SizedBox(width: 12),
          Text('Pull down to refresh weather',
              style: TextStyle(color: Colors.grey)),
        ]),
      );
}

// ── No Activity Card ──────────────────────────────────────────────────────────
class _NoActivityCard extends StatelessWidget {
  final bool isDark;
  final bool hasProfile;
  const _NoActivityCard({
    required this.isDark,
    required this.hasProfile,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.green.shade100,
          ),
        ),
        child: Row(children: [
          const Icon(Icons.directions_run_rounded,
              color: Colors.green, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasProfile
                  ? 'Waiting for weather data...'
                  : 'Set your age & weight in Profile\nto get personalized suggestions!',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ]),
      );
}

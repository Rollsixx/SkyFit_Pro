class ActivityModel {
  final String title;
  final String description;
  final String intensity; // Low, Moderate, High
  final String icon; // emoji
  final String duration; // e.g. "30-45 mins"
  final String? videoUrl; // YouTube embed or direct video URL

  const ActivityModel({
    required this.title,
    required this.description,
    required this.intensity,
    required this.icon,
    required this.duration,
    this.videoUrl,
  });
}

// ── Activity Suggestion Engine ─────────────────────────────────────────────
class ActivitySuggestionEngine {
  static ActivityModel suggest({
    required String weatherCondition,
    required double temperature,
    required int age,
    required double weight,
  }) {
    final isSenior = age >= 50;
    final isOverweight = weight >= 90;
    final isHot = temperature > 35;
    final isRain = weatherCondition == 'Rain' || weatherCondition == 'Drizzle';
    final isSnow = weatherCondition == 'Snow';
    final isClear = weatherCondition == 'Clear';
    final isExtreme =
        weatherCondition == 'Thunderstorm' || weatherCondition == 'Tornado';

    // ── Extreme weather ────────────────────────────────────────────────────
    if (isExtreme) {
      return const ActivityModel(
        title: 'Indoor Rest & Stretching',
        description: 'Severe weather outside. Stay safe indoors '
            'with light stretching and breathing exercises.',
        intensity: 'Low',
        icon: '🏠',
        duration: '20-30 mins',
        videoUrl:
            'https://www.youtube.com/embed/g_tea8ZNk5A', // Gentle stretching
      );
    }

    // ── Rain or Snow ───────────────────────────────────────────────────────
    if (isRain || isSnow) {
      if (isSenior) {
        return const ActivityModel(
          title: 'Indoor Chair Yoga',
          description: 'Gentle yoga poses with a chair for support. '
              'Great for flexibility and balance.',
          intensity: 'Low',
          icon: '🧘',
          duration: '20-30 mins',
          videoUrl: 'https://www.youtube.com/embed/KEjiXUZOvh0', // Chair yoga
        );
      }
      if (isOverweight) {
        return const ActivityModel(
          title: 'Indoor Bodyweight Circuit',
          description: 'Low-impact exercises: wall push-ups, '
              'seated leg raises, and standing marches.',
          intensity: 'Moderate',
          icon: '💪',
          duration: '30-40 mins',
          videoUrl:
              'https://www.youtube.com/embed/ml6cT4AZdqI', // Low impact workout
        );
      }
      return const ActivityModel(
        title: 'Indoor Yoga / Bodyweight Circuit',
        description: 'Full bodyweight circuit: push-ups, squats, '
            'lunges, planks, and core work.',
        intensity: 'Moderate',
        icon: '🏋️',
        duration: '30-45 mins',
        videoUrl:
            'https://www.youtube.com/embed/UItWltVZZmE', // Full body workout
      );
    }

    // ── Extreme Heat ───────────────────────────────────────────────────────
    if (isHot) {
      if (isOverweight) {
        return const ActivityModel(
          title: 'Swimming / Light Stretching',
          description: 'Swimming is ideal in extreme heat. '
              'Stay hydrated and avoid peak sun hours.',
          intensity: 'Low',
          icon: '🏊',
          duration: '30-45 mins',
          videoUrl:
              'https://www.youtube.com/embed/zh-VDMKdNpQ', // Swimming workout
        );
      }
      return const ActivityModel(
        title: 'Early Morning Run or Swim',
        description: 'Exercise before 8am or after 6pm to avoid heat. '
            'Stay hydrated and wear light clothing.',
        intensity: 'Moderate',
        icon: '🌅',
        duration: '30-40 mins',
        videoUrl:
            'https://www.youtube.com/embed/kZDvg92tTMc', // Morning run tips
      );
    }

    // ── Clear / Sunny ──────────────────────────────────────────────────────
    if (isClear) {
      if (isSenior) {
        return const ActivityModel(
          title: 'Morning Walk / Tai Chi in the Park',
          description: 'A gentle morning walk or Tai Chi session. '
              'Perfect for balance and fresh air.',
          intensity: 'Low',
          icon: '🌳',
          duration: '30-45 mins',
          videoUrl: 'https://www.youtube.com/embed/cEOS_zanycs', // Tai Chi
        );
      }
      if (isOverweight) {
        return const ActivityModel(
          title: 'Brisk Walking / Light Jogging',
          description: 'Start with a brisk 20-min walk then attempt '
              'light jogging intervals. Stay hydrated.',
          intensity: 'Moderate',
          icon: '🚶',
          duration: '30-45 mins',
          videoUrl:
              'https://www.youtube.com/embed/njeZ29umqVE', // Brisk walk workout
        );
      }
      return const ActivityModel(
        title: 'Outdoor Running / HIIT',
        description: 'Great weather for high-intensity training! '
            'Try a 5K run or a 20-min HIIT session outdoors.',
        intensity: 'High',
        icon: '🏃',
        duration: '30-45 mins',
        videoUrl: 'https://www.youtube.com/embed/ml6cT4AZdqI', // HIIT workout
      );
    }

    // ── Cloudy / Default ───────────────────────────────────────────────────
    if (isSenior) {
      return const ActivityModel(
        title: 'Light Walk & Stretching',
        description: 'A comfortable walk with gentle stretching. '
            'Ideal for cloudy mild weather.',
        intensity: 'Low',
        icon: '🚶',
        duration: '20-30 mins',
        videoUrl: 'https://www.youtube.com/embed/g_tea8ZNk5A', // Stretching
      );
    }
    return const ActivityModel(
      title: 'Outdoor Cycling / Jogging',
      description: 'Cloudy weather is perfect for moderate cardio. '
          'Try cycling or a steady-paced jog.',
      intensity: 'Moderate',
      icon: '🚴',
      duration: '30-45 mins',
      videoUrl: 'https://www.youtube.com/embed/kZDvg92tTMc', // Cycling/jogging
    );
  }
}

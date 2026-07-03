import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/play_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/play/:id',
      builder: (context, state) =>
          PlayScreen(levelNumber: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
  ],
);

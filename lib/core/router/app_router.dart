import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/walk/screens/walk_screen.dart';
import '../../features/meal/screens/meal_camera_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';

class AppRouter {
  AppRouter._();

  static final _supabase = Supabase.instance.client;

  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final session = _supabase.auth.currentSession;
      final isAuth = session != null;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/home';
      return null;
    },
    refreshListenable: GoRouterRefreshStream(
      _supabase.auth.onAuthStateChange,
    ),
    routes: [
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home',     builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/walk',     builder: (_, __) => const WalkScreen()),
      GoRoute(path: '/meal',     builder: (_, __) => const MealCameraScreen()),
      GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
    ],
  );
}

/// Bridges Supabase auth stream to GoRouter's Listenable
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

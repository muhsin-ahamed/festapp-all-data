import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../providers/app_providers.dart';
import '../../features/auth/login_screen.dart';
import '../../features/public/public_portal_screen.dart';
import '../../features/public/scan_and_qr_screen.dart';
import '../../features/controller/controller_portal_screen.dart';
import '../../features/leader/leader_portal_screen.dart';
import '../../features/jury/jury_portal_screen.dart';
import '../../features/tv/tv_portal_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/public',
    routes: [
      GoRoute(
        path: '/public',
        builder: (context, state) => const PublicPortalScreen(),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'];
          return ScanAndQrScreen(initialQuery: query);
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/controller',
        builder: (context, state) => const ControllerPortalScreen(),
      ),
      GoRoute(
        path: '/leader',
        builder: (context, state) => const LeaderPortalScreen(),
      ),
      GoRoute(
        path: '/jury',
        builder: (context, state) => const JuryPortalScreen(),
      ),
      GoRoute(
        path: '/tv',
        builder: (context, state) => const TvPortalScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final loc = state.matchedLocation;

      // Public, Scan, and Login do not require login
      if (loc == '/public' || loc == '/scan' || loc == '/login') {
        return null;
      }

      final user = authService.currentUser;
      if (user == null) {
        return '/login';
      }

      // Check role permissions
      final hasAccess = authService.canAccessRoute(loc, user.role);
      if (!hasAccess) {
        switch (user.role) {
          case UserRole.festController:
            return '/controller';
          case UserRole.teamLeader:
            return '/leader';
          case UserRole.jury:
            return '/jury';
          case UserRole.tvOperator:
            return '/tv';
        }
      }

      return null;
    },
  );
});

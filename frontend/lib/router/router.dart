import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../screens/auth/forgot_password_page.dart';
import '../core/callbacks/auth_callback_page.dart';
import '../screens/auth/landing_page.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/register_page.dart';
import '../screens/home/home.dart';
import '../screens/settings/settings_page.dart';
import '../screens/profile/profile_page.dart';
import '../screens/awards/awards_page.dart';
import '../screens/settings/settings_options_page.dart';

final GoRouter router = GoRouter(
  redirect: (context, state) {
    final uri = state.uri;
    final authState = context.read<AuthBloc>().state;
    final String currentPath = state.uri.toString();

    if (authState is! AuthAuthenticated && currentPath == '/home') {
      return '/login';
    }

    if (authState is AuthAuthenticated &&
        (currentPath == '/login' || currentPath == '/register')) {
      return '/home';
    }

    if (uri.scheme == 'ride' && uri.host == 'uber') {
      final query = uri.query;
      return query.isNotEmpty ? "/auth?$query" : "/auth";
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      name: 'auth-callback',
      builder: (context, state) {
        return AuthCallbackPage(queryParameters: state.uri.queryParameters);
      },
    ),
    GoRoute(
      path: '/',
      name: 'landing-page',
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/awards',
      name: 'awards',
      builder: (context, state) => const AwardsPage(),
    ),
    GoRoute(
      path: '/settings-options',
      name: 'settings-options',
      builder: (context, state) => const SettingsOptionsPage(),
    ),
  ],
);

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

final GoRouter router = GoRouter(
  redirect: (context, state) {
    final uri = state.uri;
    final authState = context.read<AuthBloc>().state;
    final String currentPath = state.uri.toString();

    // If user is not authenticated and trying to go to /home -> redirect to /login
    if (authState is! AuthAuthenticated && currentPath == '/home') {
      return '/login';
    }

    // If user is already authenticated, prevent going back to login/register
    if (authState is AuthAuthenticated &&
        (currentPath == '/login' || currentPath == '/register')) {
      return '/home';
    }

    if (uri.scheme == 'ride' && uri.host == 'uber') {
      final query = uri.query;
      return query.isNotEmpty ? "/auth?$query" : "/auth";
    }

    return null; // No redirect, proceed normally
  },
  routes: [
    GoRoute(
      path: '/auth',
      name: 'auth-callback',
      builder: (context, state) {
        // Pass query parameters to the AuthCallbackPage
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
  ],
);

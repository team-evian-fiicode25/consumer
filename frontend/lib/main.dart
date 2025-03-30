import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/auth_service.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_state.dart';
import 'bloc/theme/theme_bloc.dart';
import 'bloc/settings/settings_bloc.dart';
import 'router/router.dart';
import 'core/theme/app_theme.dart';

void main() {
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => AuthBloc(AuthService())),
            BlocProvider(create: (context) {
              final themeBloc = ThemeBloc();
              // Load saved theme on app start
              themeBloc.add(ThemeLoaded());
              return themeBloc;
            }),
            BlocProvider(create: (context) {
              final settingsBloc = SettingsBloc();
              // Load all saved settings on app start
              settingsBloc.add(SettingsLoaded());
              return settingsBloc;
            }),
          ],
          child: BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              return BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  return MaterialApp.router(
                    title: 'Consumer App',
                    routerConfig: router,
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: themeState.themeMode,
                  );
                },
              );
            },
          ),
        );
    }
}

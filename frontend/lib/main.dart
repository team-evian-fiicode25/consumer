import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/auth_service.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_state.dart';
import 'router/router.dart';
import 'core/theme/app_theme.dart';

void main() {
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
        return BlocProvider(
          create: (context) => AuthBloc(AuthService()),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return MaterialApp.router(
                title: 'Consumer App',
                routerConfig: router,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: ThemeMode.system,
              );
            },
          ),
        );
    }
}

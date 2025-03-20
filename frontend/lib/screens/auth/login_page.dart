import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/gradient_background.dart';
import '../widgets/back_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginRequested(_emailController.text, _passwordController.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final isSmallScreen = screenSize.width < 600;
    final contentPadding = isSmallScreen ? 16.0 : 24.0;
    final backgroundHeight = isLandscape ? screenSize.height : (isSmallScreen ? 220.0 : 280.0);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          GradientBackground(height: backgroundHeight),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(contentPadding),
              child: Form(
                key: _formKey,
                child: BlocConsumer<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is AuthAuthenticated) {
                      context.goNamed('home');
                    } else if (state is AuthFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.error), behavior: SnackBarBehavior.floating)
                      );
                    }
                  },
                  builder: (context, state) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isLandscape ? 900 : 450,
                        ),
                        child: isLandscape
                            ? Stack(
                              children: [
                                Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildHeader(context),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Card(
                                          elevation: 8,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(contentPadding),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _buildLoginForm(context, state),
                                                const SizedBox(height: 24),
                                                _buildRegisterLink(context),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      CustomBackButton(path: 'landing-page'),
                                    ],
                                  ),
                                ],
                              )
                            : Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 100),
                                      _buildHeader(context),
                                      const SizedBox(height: 180),
                                      Card(
                                        elevation: 8,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(contentPadding),
                                          child: Column(
                                            children: [
                                              _buildLoginForm(context, state),
                                              const SizedBox(height: 24),
                                              _buildRegisterLink(context),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  CustomBackButton(path: 'landing-page'),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome Back!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthState state) {
    return Column(
      children: [
        CustomTextField(
          controller: _emailController,
          label: 'Email or Username',
          icon: Icons.email_outlined,
          validator: (value) =>
          value!.isEmpty ? 'Please enter your email or username' : null,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outlined,
          isPassword: true,
          isPasswordVisible: _isPasswordVisible,
          onToggleVisibility: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
          validator: (value) =>
          value!.isEmpty ? 'Please enter your password' : null,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.goNamed('forgot-password'),
            child: const Text('Forgot Password?'),
          ),
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: 'Sign In',
          isLoading: state is AuthLoading,
          onPressed: () => _onLogin(context),
        ),
      ],
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account?"),
        TextButton(
          onPressed: () => context.goNamed('register'),
          child: const Text('Sign Up'),
        ),
      ],
    );
  }
}

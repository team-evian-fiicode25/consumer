import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libphonenumber_plugin/libphonenumber_plugin.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../core/models/user_register.dart';
import '../widgets/custom_text_field.dart';
import 'terms_policies_page.dart';
import '../widgets/gradient_background.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _currentStep = 0;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  
  bool _isEmailFocused = false;
  bool _isUsernameFocused = false;
  bool _isPhoneFocused = false;
  bool _isPasswordFocused = false;
  bool _isConfirmPasswordFocused = false;
  
  String? _phoneError;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isValidatingPhone = false;

  final RegExp _usernamePattern = RegExp(r'^[a-z0-9_]+$');
  
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _setupFocusListeners();
    _setupPasswordListener();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePasswordCriteria(_passwordController.text);
    });
  }
  
  void _setupFocusListeners() {
    _emailFocus.addListener(() {
      setState(() {
        _isEmailFocused = _emailFocus.hasFocus;
      });
    });
    
    _usernameFocus.addListener(() {
      setState(() {
        _isUsernameFocused = _usernameFocus.hasFocus;
      });
    });
    
    _phoneFocus.addListener(() {
      setState(() {
        _isPhoneFocused = _phoneFocus.hasFocus;
      });
    });
    
    _passwordFocus.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocus.hasFocus;
      });
    });
    
    _confirmPasswordFocus.addListener(() {
      setState(() {
        _isConfirmPasswordFocused = _confirmPasswordFocus.hasFocus;
      });
    });
  }
  
  void _setupPasswordListener() {
    _passwordController.addListener(() {
      _updatePasswordCriteria(_passwordController.text);
    });
  }
  
  void _updatePasswordCriteria(String password) {
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(password);
      _hasNumber = RegExp(r'[0-9]').hasMatch(password);
      _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _usernameFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        _showTermsPoliciesPage();
      }
    } else {
      if (_formKey.currentState!.validate()) {
        final user = UserRegister(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
        );
        context.read<AuthBloc>().add(RegisterRequested(user));
      }
    }
  }

  void _showTermsPoliciesPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TermsPoliciesPage(
          onAccept: () {
            setState(() {
              _currentStep = 1;
            });
            Navigator.of(context).pop();
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _onCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep = 0;
      });
      _showTermsPoliciesPage();
    } else {
      context.goNamed('landing-page');
    }
  }

  Future<bool> _validatePhoneNumber(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      return true;
    }
    
    try {
      setState(() {
        _isValidatingPhone = true;
      });
      
      final isValid = await PhoneNumberUtil.isValidPhoneNumber(
        phoneNumber, 
        'RO'
      );
      
      return isValid ?? false;
    } catch (e) {
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isValidatingPhone = false;
        });
      }
    }
  }

  String? _getPasswordStrengthMessage(String password) {
    if (password.isEmpty) {
      return 'Please enter your password';
    }
    
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }

  void _validatePhone() async {
    final phoneNumber = _phoneController.text;
    if (phoneNumber.isEmpty) {
      setState(() {
        _phoneError = null;
      });
      return;
    }

    final isValid = await _validatePhoneNumber(phoneNumber);
    
    if (mounted) {
      setState(() {
        _phoneError = isValid ? null : 'Please enter a valid phone number (E.164 format)';
      });
      
      if (_currentStep == 1) {
        _formKey.currentState?.validate();
      }
    }
  }

  Widget _buildHeader() {
    final title = _currentStep == 0 ? 'Create an Account' : 'Complete Your Profile';
    final subtitle = _currentStep == 0 ? 'Enter your email' : 'Fill out the rest of your details';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocus,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: const Icon(Icons.email_outlined),
        helperText: _isEmailFocused ? 'Enter a valid email address' : null,
        helperMaxLines: 2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
        if (!emailRegex.hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildAdditionalFieldsStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _usernameController,
          focusNode: _usernameFocus,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a username';
            }
            
            if (!_usernamePattern.hasMatch(value)) {
              return 'Username can only contain lowercase letters, numbers, and underscores';
            }
            
            if (value.length < 3 || value.length > 20) {
              return 'Username must be between 3 and 20 characters';
            }
            
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Username',
            prefixIcon: const Icon(Icons.person_outline),
            helperText: _isUsernameFocused ? 'Lowercase letters, numbers, and underscores only' : null,
            helperMaxLines: 2,
            errorMaxLines: 3,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          autocorrect: false,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _phoneController,
          focusNode: _phoneFocus,
          decoration: InputDecoration(
            labelText: 'Phone Number (optional)',
            prefixIcon: const Icon(Icons.phone),
            helperText: _isPhoneFocused ? 'E.164 format (e.g., +40723456789)' : null,
            helperMaxLines: 2,
            errorText: _phoneError,
            errorMaxLines: 2,
            suffixIcon: _isValidatingPhone 
              ? const SizedBox(
                  height: 15, 
                  width: 15, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                ) 
              : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (value) {
            _validatePhone();
          },
          validator: (value) {
            return _phoneError;
          },
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: !_isPasswordVisible,
          validator: (value) => _getPasswordStrengthMessage(value ?? ''),

          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outlined),
            helperText: _isPasswordFocused ? null : 'Min 8 chars with uppercase, lowercase, number, and special char',
            helperMaxLines: 2,
            errorMaxLines: 3,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _isPasswordVisible = !_isPasswordVisible);
              },
            ),
          ),
        ),
        if (_isPasswordFocused) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPasswordCriteria('At least 8 characters', _hasMinLength),
                _buildPasswordCriteria('At least one uppercase letter', _hasUppercase),
                _buildPasswordCriteria('At least one lowercase letter', _hasLowercase),
                _buildPasswordCriteria('At least one number', _hasNumber),
                _buildPasswordCriteria('At least one special character', _hasSpecialChar),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          obscureText: !_isConfirmPasswordVisible,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_outlined),
            helperText: _isConfirmPasswordFocused ? 'Must match the password entered above' : null,
            helperMaxLines: 2,
            errorMaxLines: 2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_currentStep == 0) _buildEmailStep(),
          if (_currentStep == 1) _buildAdditionalFieldsStep(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _onContinue,
                  child: Text(_currentStep == 0 ? 'Continue' : 'Sign Up'),
                ),
              ),
              const SizedBox(width: 12),
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _onCancel,
                    child: const Text('Back'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSignInLink(context),
        ],
      ),
    );
  }

  Widget _buildSignInLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account?"),
        TextButton(
          onPressed: () => context.goNamed('login'),
          child: const Text('Sign In'),
        ),
      ],
    );
  }

  Widget _buildPasswordCriteria(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isMet ? Colors.green : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isMet ? Colors.green : Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFormActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentStep == 0 ? 'Continue' : 'Sign Up',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            if (_currentStep > 0) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Already have an account?"),
            TextButton(
              onPressed: () => context.goNamed('login'),
              child: const Text('Sign In'),
            ),
          ],




        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final isSmallScreen = screenSize.width < 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final contentPadding = isSmallScreen ? 16.0 : 24.0;
    final backgroundHeight = isLandscape ? screenSize.height : (isSmallScreen ? 220.0 : 280.0);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.goNamed('home');
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            fit: StackFit.expand,
            children: [
              GradientBackground(height: backgroundHeight),              
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(contentPadding),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: isSmallScreen ? 40 : 60,
                      bottom: padding.bottom + 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isLandscape ? 900 : 450,
                        ),
                        child: isLandscape && _currentStep == 1
                            ? Form(
                                key: _formKey,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildHeader(),
                                          const SizedBox(height: 16),
                                          Card(
                                            elevation: 8,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(contentPadding),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextFormField(
                                                    controller: _usernameController,
                                                    focusNode: _usernameFocus,
                                                    validator: (value) {
                                                      if (value == null || value.isEmpty) {
                                                        return 'Please enter a username';
                                                      }
                                                      
                                                      if (!_usernamePattern.hasMatch(value)) {
                                                        return 'Username can only contain lowercase letters, numbers, and underscores';
                                                      }
                                                      
                                                      if (value.length < 3 || value.length > 20) {
                                                        return 'Username must be between 3 and 20 characters';
                                                      }
                                                      
                                                      return null;
                                                    },
                                                    decoration: InputDecoration(
                                                      labelText: 'Username',
                                                      prefixIcon: const Icon(Icons.person_outline),
                                                      helperText: _isUsernameFocused ? 'Lowercase letters, numbers, and underscores only' : null,
                                                      helperMaxLines: 2,
                                                      errorMaxLines: 3,
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                    autocorrect: false,
                                                    textInputAction: TextInputAction.next,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  TextFormField(
                                                    controller: _phoneController,
                                                    focusNode: _phoneFocus,
                                                    decoration: InputDecoration(
                                                      labelText: 'Phone Number (optional)',
                                                      prefixIcon: const Icon(Icons.phone),
                                                      helperText: _isPhoneFocused ? 'E.164 format (e.g., +40723456789)' : null,
                                                      helperMaxLines: 2,
                                                      errorText: _phoneError,
                                                      errorMaxLines: 2,
                                                      suffixIcon: _isValidatingPhone 
                                                        ? const SizedBox(
                                                            height: 15, 
                                                            width: 15, 
                                                            child: CircularProgressIndicator(strokeWidth: 2)
                                                          ) 
                                                        : null,
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                    keyboardType: TextInputType.phone,
                                                    onChanged: (value) {
                                                      _validatePhone();
                                                    },
                                                    validator: (value) {
                                                      return _phoneError;
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
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
                                              TextFormField(
                                                controller: _passwordController,
                                                focusNode: _passwordFocus,
                                                obscureText: !_isPasswordVisible,
                                                validator: (value) => _getPasswordStrengthMessage(value ?? ''),
                                                decoration: InputDecoration(
                                                  labelText: 'Password',
                                                  prefixIcon: const Icon(Icons.lock_outlined),
                                                  helperText: _isPasswordFocused ? null : 'Min 8 chars with uppercase, lowercase, number, and special char',
                                                  helperMaxLines: 2,
                                                  errorMaxLines: 3,
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                                    ),
                                                    onPressed: () {
                                                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                                                    },
                                                  ),
                                                ),
                                              ),
                                              if (_isPasswordFocused) ...[
                                                const SizedBox(height: 8),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      _buildPasswordCriteria('At least 8 characters', _hasMinLength),
                                                      _buildPasswordCriteria('At least one uppercase letter', _hasUppercase),
                                                      _buildPasswordCriteria('At least one lowercase letter', _hasLowercase),
                                                      _buildPasswordCriteria('At least one number', _hasNumber),
                                                      _buildPasswordCriteria('At least one special character', _hasSpecialChar),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 16),
                                              TextFormField(
                                                controller: _confirmPasswordController,
                                                focusNode: _confirmPasswordFocus,
                                                obscureText: !_isConfirmPasswordVisible,
                                                validator: (value) {
                                                  if (value == null || value.isEmpty) {
                                                    return 'Please confirm your password';
                                                  }
                                                  
                                                  if (value != _passwordController.text) {
                                                    return 'Passwords do not match';
                                                  }
                                                  
                                                  return null;
                                                },
                                                decoration: InputDecoration(
                                                  labelText: 'Confirm Password',
                                                  prefixIcon: const Icon(Icons.lock_outlined),
                                                  helperText: _isConfirmPasswordFocused ? 'Must match the password entered above' : null,
                                                  helperMaxLines: 2,
                                                  errorMaxLines: 2,
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                      _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                                    ),
                                                    onPressed: () {
                                                      setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                                                    },
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              _buildFormActions(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildHeader(),
                                  SizedBox(height: isSmallScreen ? 32 : 48),
                                  Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(contentPadding),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_currentStep == 0) _buildEmailStep(),
                                            if (_currentStep == 1) _buildAdditionalFieldsStep(),
                                            const SizedBox(height: 24),
                                            _buildFormActions(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              
              if (state is AuthLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

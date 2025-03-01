import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'terms_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptedTerms = false;
  int _currentStep = 0;
  
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'RO');

  final Map<String, bool> _passwordRequirements = {
    'length': false,
    'uppercase': false,
    'lowercase': false,
    'number': false,
    'special': false,
  };

  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _nicknameFocus = FocusNode();
  final _phoneFocus = FocusNode();

  final Map<String, bool> _fieldTouched = {
    'username': false,
    'email': false,
    'password': false,
    'confirmPassword': false,
    'nickname': false,
    'phone': false,
  };

  @override
  void initState() {
    super.initState();
    
    _usernameFocus.addListener(_onUsernameFocusChange);
    _emailFocus.addListener(_onEmailFocusChange);
    _passwordFocus.addListener(_onPasswordFocusChange);
    _confirmPasswordFocus.addListener(_onConfirmPasswordFocusChange);
    _nicknameFocus.addListener(_onNicknameFocusChange);
    _phoneFocus.addListener(_onPhoneFocusChange);
  }

  @override
  void dispose() {
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _nicknameFocus.dispose();
    _phoneFocus.dispose();
    
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _onUsernameFocusChange() {
    setState(() {
      if (!_usernameFocus.hasFocus) {
        _fieldTouched['username'] = true;
        _formKey.currentState?.validate();
      }
    });
  }

  void _onEmailFocusChange() {
    setState(() {
      if (!_emailFocus.hasFocus) {
        _fieldTouched['email'] = true;
        if (_formKey.currentState != null) {
          _formKey.currentState!.validate();
        }
      }
    });
  }

  void _onPasswordFocusChange() {
    if (!_passwordFocus.hasFocus) {
      setState(() => _fieldTouched['password'] = true);
    }
    setState(() {});
  }

  void _onConfirmPasswordFocusChange() {
    setState(() {
      if (!_confirmPasswordFocus.hasFocus) {
        _fieldTouched['confirmPassword'] = true;
        if (_formKey.currentState != null) {
          _formKey.currentState!.validate();
        }
      }
    });
  }

  void _onNicknameFocusChange() {
    setState(() {
      if (!_nicknameFocus.hasFocus) {
        _fieldTouched['nickname'] = true;
        if (_formKey.currentState != null) {
          _formKey.currentState!.validate();
        }
      }
    });
  }

  void _onPhoneFocusChange() {
    setState(() {
      if (!_phoneFocus.hasFocus) {
        _fieldTouched['phone'] = true;
        if (_formKey.currentState != null) {
          _formKey.currentState!.validate();
        }
      }
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    
    if (value.length < 8 || 
        !value.contains(RegExp(r'[A-Z]')) ||
        !value.contains(RegExp(r'[a-z]')) ||
        !value.contains(RegExp(r'[0-9]')) ||
        !value.contains(RegExp(r'[!@#\$&*~]'))) {
      return 'Invalid password';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    if (!RegExp(r'^[a-z][a-z0-9_-]*$').hasMatch(value)) {
      return 'Username can only contain lowercase letters, numbers, _ or -';
    }
    return null;
  }

  String? _validateNickname(String? value) {
    if (value != null && value.length > 32) {
      return 'Nickname cannot be longer than 32 characters';
    }
    return null;
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      return _usernameController.text.isNotEmpty &&
          _validateUsername(_usernameController.text) == null &&
          _validateEmail(_emailController.text) == null &&
          _validatePassword(_passwordController.text) == null &&
          _passwordController.text == _confirmPasswordController.text;
    } else {
      return _validateNickname(_nicknameController.text) == null;
    }
  }

  void _onStepContinue() {
    if (_currentStep < 1) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep += 1;
        });
      }
    } else {
      if (_validateCurrentStep() && _acceptedTerms) {
        // TODO (mihaescuvlad): Implement register
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Widget _buildPasswordRequirements() {
    if (!_passwordFocus.hasFocus) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRequirement('At least 8 characters', _passwordRequirements['length']!),
            _buildRequirement('One uppercase letter', _passwordRequirements['uppercase']!),
            _buildRequirement('One lowercase letter', _passwordRequirements['lowercase']!),
            _buildRequirement('One number', _passwordRequirements['number']!),
            _buildRequirement('One special character (!@#\$&*~)', _passwordRequirements['special']!),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isMet ? Colors.green : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? Colors.green : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameRequirements() {
    if (!_usernameFocus.hasFocus) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Start with lowercase letter • Can contain: a-z, 0-9, _ or -',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.disabled,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_currentStep == 1 && !_acceptedTerms) 
                            ? null 
                            : details.onStepContinue,
                        child: Text(_currentStep == 1 ? 'Sign Up' : 'Continue'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        child: Text(_currentStep == 0 ? 'Cancel' : 'Back'),
                      ),
                    ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Essential Information'),
                content: Column(
                  children: [
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      focusNode: _usernameFocus,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                        errorMaxLines: 2,
                      ),
                      validator: (value) {
                        if (!_fieldTouched['username']!) return null;
                        return _validateUsername(value);
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    _buildUsernameRequirements(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (!_fieldTouched['email']!) return null;
                        return _validateEmail(value);
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (!_fieldTouched['password']!) return null;
                        return _validatePassword(value);
                      },
                      onChanged: (value) => setState(() {
                        _passwordRequirements['length'] = value.length >= 8;
                        _passwordRequirements['uppercase'] = value.contains(RegExp(r'[A-Z]'));
                        _passwordRequirements['lowercase'] = value.contains(RegExp(r'[a-z]'));
                        _passwordRequirements['number'] = value.contains(RegExp(r'[0-9]'));
                        _passwordRequirements['special'] = value.contains(RegExp(r'[!@#\$&*~]'));
                      }),
                    ),
                    _buildPasswordRequirements(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocus,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (!_fieldTouched['confirmPassword']!) return null;
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Additional Information'),
                content: Column(
                  children: [
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nicknameController,
                      focusNode: _nicknameFocus,
                      decoration: InputDecoration(
                        labelText: 'Nickname (optional)',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        helperText: _nicknameFocus.hasFocus ? 'Maximum 32 characters' : null,
                      ),
                      validator: (value) {
                        if (!_fieldTouched['nickname']!) return null;
                        return _validateNickname(value);
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: InternationalPhoneNumberInput(
                        onInputChanged: (PhoneNumber number) {
                          setState(() => _phoneNumber = number);
                        },
                        selectorConfig: const SelectorConfig(
                          selectorType: PhoneInputSelectorType.DROPDOWN,
                          setSelectorButtonAsPrefixIcon: true,
                        ),
                        spaceBetweenSelectorAndTextField: 0,
                        ignoreBlank: true,
                        autoValidateMode: AutovalidateMode.disabled,
                        formatInput: true,
                        focusNode: _phoneFocus,
                        validator: (value) {
                          if (!_fieldTouched['phone']!) return null;
                          if (value == null || value.isEmpty) return null;
                          
                          final phoneNumber = value.replaceAll(RegExp(r'[^\d]'), '');
                          if (phoneNumber.length < 8 || phoneNumber.length > 15) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                        inputDecoration: const InputDecoration(
                          labelText: 'Phone Number (optional)',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        searchBoxDecoration: InputDecoration(
                          labelText: 'Search by country name or code',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        initialValue: _phoneNumber,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: _acceptedTerms,
                      onChanged: (value) async {
                        if (value == true && !_acceptedTerms) {
                          final accepted = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TermsAndConditionsPage(),
                            ),
                          );
                          setState(() {
                            _acceptedTerms = accepted ?? false;
                          });
                        } else {
                          setState(() {
                            _acceptedTerms = value ?? false;
                          });
                        }
                      },
                      title: Row(
                        children: [
                          const Text('I accept the '),
                          TextButton(
                            onPressed: () async {
                              final accepted = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TermsAndConditionsPage(),
                                ),
                              );
                              setState(() {
                                _acceptedTerms = accepted ?? _acceptedTerms;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Terms of Service'),
                          ),
                        ],
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
                isActive: _currentStep >= 1,
                state: _currentStep == 1 && _validateCurrentStep() && _acceptedTerms
                    ? StepState.complete
                    : StepState.indexed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import '../widgets/back_button.dart' show CustomBackButton;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // TODO (mihaescuvlad): Add a method to fetch the user data from Mongo
  final String _initialUsername = 'testing_account';
  String _initialEmail = 'test@test.com';
  final String _initialPhone = '+40773388147';
  
  bool _usernameChanged = false;
  bool _emailChanged = false;
  bool _phoneChanged = false;
  
  bool _isEditingEmail = false;
  bool _isEditingPassword = false;
  
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _passwordError;
  
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  
  bool get _hasChanges => 
      _usernameChanged || _emailChanged || _phoneChanged || _profileImage != null;
  
  @override
  void initState() {
    super.initState();
    _usernameController.text = _initialUsername;
    _emailController.text = _initialEmail;
    _phoneController.text = _initialPhone;
    
    _usernameController.addListener(_onUsernameChanged);
    _emailController.addListener(_onEmailChanged);
    _phoneController.addListener(_onPhoneChanged);
  }
  
  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _emailController.removeListener(_onEmailChanged);
    _phoneController.removeListener(_onPhoneChanged);
    
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  void _onUsernameChanged() {
    setState(() {
      _usernameChanged = _usernameController.text != _initialUsername;
    });
  }
  
  void _onEmailChanged() {
    setState(() {
      _emailChanged = _emailController.text != _initialEmail;
    });
  }
  
  void _onPhoneChanged() {
    setState(() {
      _phoneChanged = _phoneController.text != _initialPhone;
    });
  }
  
  void _validatePasswords() {
    setState(() {
      if (_passwordController.text.isNotEmpty && 
          _confirmPasswordController.text.isNotEmpty) {
        if (_passwordController.text != _confirmPasswordController.text) {
          _passwordError = "Passwords don't match";
        } else {
          _passwordError = null;
        }
      }
    });
  }
  
  void _resetFields() {
    setState(() {
      _usernameController.text = _initialUsername;
      _emailController.text = _initialEmail;
      _phoneController.text = _initialPhone;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _passwordError = null;
      _isEditingEmail = false;
      _isEditingPassword = false;
      _profileImage = null;
    });
  }
  
  void _saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    setState(() {
      _usernameChanged = false;
      _emailChanged = false;
      _phoneChanged = false;
      _isEditingEmail = false;
      _isEditingPassword = false;
      _profileImage = null;
    });
  }
  
  void _savePasswordChanges() {
    _validatePasswords();
    
    if (_passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_passwordError!),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter and confirm your new password'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    setState(() {
      _passwordController.clear();
      _confirmPasswordController.clear();
      _isEditingPassword = false;
      _passwordError = null;
    });
  }
  
  void _saveEmailChanges() {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your new email'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email updated successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    setState(() {
      _initialEmail = _emailController.text;
      _emailChanged = false;
      _isEditingEmail = false;
    });
  }
  
  Future<void> _showProfileImageOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profile Picture',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.photo_camera, color: theme.colorScheme.primary),
                  title: const Text('Take a picture'),
                  onTap: () {
                    _getImage(ImageSource.camera);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: theme.colorScheme.primary),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    _getImage(ImageSource.gallery);
                    Navigator.pop(context);
                  },
                ),
                if (_profileImage != null)
                  ListTile(
                    leading: Icon(Icons.delete, color: theme.colorScheme.error),
                    title: Text(
                      'Remove photo',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () {
                      setState(() {
                        _profileImage = null;
                      });
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<PermissionStatus> _getStoragePermission() async {
    try {
      final photosStatus = await Permission.photos.request();
      if (photosStatus != PermissionStatus.permanentlyDenied) {
        return photosStatus;
      }
    } catch (e) {
      debugPrint('Photos permission not available, using storage permission: $e');
    }
    
    return Permission.storage.request();
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      PermissionStatus status;
      
      if (source == ImageSource.camera) {
        status = await Permission.camera.status;
        if (status.isDenied) {
          status = await Permission.camera.request();
        }
      } else {
        status = await _getStoragePermission();
      }
      
      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        _showPermissionSettingsDialog(
          source == ImageSource.camera ? 'camera' : 'photo library'
        );
        return;
      } else if (status.isDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${source == ImageSource.camera ? 'Camera' : 'Photos'} permission was denied'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'SETTINGS',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }
      
      final pickedFile = await _picker.pickImage(
        source: source, 
        imageQuality: 80,
        maxWidth: 800,
      );
      
      if (pickedFile != null && mounted) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
  
  void _showPermissionSettingsDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text('Permission Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This app needs access to your $permissionType to set a profile picture.'
              ),
              const SizedBox(height: 12),
              Text(
                'How to enable:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildPermissionInstructions(permissionType),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'CANCEL',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('OPEN SETTINGS'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Widget _buildPermissionInstructions(String permissionType) {
    final isCamera = permissionType == 'camera';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 14,
            ),
            children: [
              const TextSpan(text: '1. Tap '),
              TextSpan(
                text: 'OPEN SETTINGS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 14,
            ),
            children: [
              const TextSpan(text: '2. Select '),
              TextSpan(
                text: 'Permissions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 14,
            ),
            children: [
              const TextSpan(text: '3. Enable '),
              TextSpan(
                text: isCamera ? 'Camera' : 'Storage/Photos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' permission'),
            ],
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: CustomBackButton(path: "settings"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(theme),
            const SizedBox(height: 24),
            _buildProfileForm(theme),
            if (_hasChanges) ...[
              const SizedBox(height: 24),
              _buildActionButtons(theme),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileHeader(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _showProfileImageOptions,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.1),
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 2,
              ),
              image: _profileImage != null
                  ? DecorationImage(
                      image: FileImage(_profileImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _profileImage == null
              ? Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 18,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 18,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _initialUsername,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // TODO (mihaescuvlad): Add a method to fetch createdAt from Mongo
              // then parse to DateTime
              Text(
                'Member since March 2025',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildProfileForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _usernameController,
          label: 'Username',
          icon: Icons.person_outline,
          changed: _usernameChanged,
        ),
        const SizedBox(height: 16),
        
        _buildEmailSection(theme),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _phoneController,
          label: 'Phone',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          changed: _phoneChanged,
        ),
        const SizedBox(height: 24),
        
        _buildPasswordSection(theme),
      ],
    );
  }
  
  Widget _buildEmailSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isEditingEmail) ...[
          _buildInfoField(
            label: 'Email',
            value: _initialEmail,
            icon: Icons.email_outlined,
            onChangePressed: () {
              setState(() {
                _isEditingEmail = true;
                _emailController.text = _initialEmail;
              });
            },
          ),
        ] else ...[
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            changed: _emailChanged,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingEmail = false;
                      _emailController.text = _initialEmail;
                      _emailChanged = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveEmailChanges,
                  child: const Text('Save Email'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildPasswordSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        if (!_isEditingPassword) ...[
          InkWell(
            onTap: () {
              setState(() {
                _isEditingPassword = true;
                _passwordController.clear();
                _confirmPasswordController.clear();
                _passwordError = null;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.inputDecorationTheme.fillColor,
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Text(
                    'Change Password',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          _buildTextField(
            controller: _passwordController,
            label: 'New Password',
            icon: Icons.lock_outline,
            obscureText: true,
            errorText: _passwordError,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock_outline,
            obscureText: true,
            errorText: _passwordError,
            onChanged: (_) => _validatePasswords(),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingPassword = false;
                      _passwordController.clear();
                      _confirmPasswordController.clear();
                      _passwordError = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _savePasswordChanges,
                  child: const Text('Update Password'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onChangePressed,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.inputDecorationTheme.fillColor,
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChangePressed,
            child: Text(
              'Change',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool changed = false,
    String? errorText,
    Function(String)? onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.inputDecorationTheme.fillColor,
        border: changed || (obscureText && controller.text.isNotEmpty)
            ? Border.all(
                color: errorText != null 
                    ? theme.colorScheme.error 
                    : theme.colorScheme.primary, 
                width: 2)
            : null,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: errorText != null ? theme.colorScheme.error : null,
          ),
          suffixIcon: errorText != null
              ? Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                )
              : changed
                  ? Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                    )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          errorText: errorText,
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _resetFields();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
            child: const Text('Discard'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveChanges,
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}
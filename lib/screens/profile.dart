import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:food_recipes_app/services/auth_service.dart';
import 'package:food_recipes_app/services/notification_service.dart';
import 'package:food_recipes_app/screens/login_screen.dart';
import 'package:food_recipes_app/helper/theme_provider.dart';
import 'package:food_recipes_app/helper/pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _imagePicker = ImagePicker();
  
  Map<String, dynamic>? _userProfile;
  File? _selectedImage;
  String? _localProfilePicPath;
  bool _isLoading = true;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadLocalProfilePic();
  }

  // Load local profile picture path from SharedPreferences
  Future<void> _loadLocalProfilePic() async {
    final user = _authService.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final localPath = prefs.getString('profile_pic_${user.uid}');
      if (localPath != null && File(localPath).existsSync()) {
        setState(() {
          _localProfilePicPath = localPath;
          _selectedImage = File(localPath);
        });
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final profile = await _authService.getUserProfile(user.uid);
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Failed to load profile: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
        await _uploadProfilePicture();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_selectedImage == null) return;

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isUploadingImage = true);

    try {
      // Save image locally instead of Firebase Storage
      final appDir = await getApplicationDocumentsDirectory();
      final profilePicsDir = Directory('${appDir.path}/profile_pictures');
      
      // Create directory if it doesn't exist
      if (!await profilePicsDir.exists()) {
        await profilePicsDir.create(recursive: true);
      }
      
      // Save with user ID as filename
      final savedImagePath = '${profilePicsDir.path}/${user.uid}.jpg';
      await _selectedImage!.copy(savedImagePath);
      
      // Save path to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_pic_${user.uid}', savedImagePath);
      
      setState(() {
        _localProfilePicPath = savedImagePath;
      });
      
      print('✅ Profile picture saved locally: $savedImagePath');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: $e')),
        );
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Show Notifications Dialog
  void _showNotificationsDialog() async {
    bool notificationsEnabled = await NotificationService.areNotificationsEnabled();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications_outlined, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text('Notifications'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: Text(
                  notificationsEnabled 
                    ? 'Get notified when recipes are added'
                    : 'Notifications are currently off',
                ),
                value: notificationsEnabled,
                onChanged: (value) async {
                  await NotificationService.setNotificationsEnabled(value);
                  setDialogState(() {
                    notificationsEnabled = value;
                  });
                },
                activeColor: Colors.orangeAccent,
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'When enabled, you\'ll receive notifications when new recipes are added.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  // Show Account Settings Dialog
  void _showAccountSettingsDialog() {
    final user = _authService.currentUser;
    final nameController = TextEditingController(text: _userProfile?['fullName'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings_outlined, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text('Account Settings'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display Name
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              
              // Email (read-only)
              TextField(
                controller: TextEditingController(text: user?.email ?? ''),
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              
              // Change Password Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showChangePasswordDialog();
                  },
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Change Password'),
                ),
              ),
              const SizedBox(height: 8),
              
              // Delete Account Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showDeleteAccountDialog();
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (user != null && nameController.text.trim().isNotEmpty) {
                try {
                  await _authService.updateUserProfile(
                    uid: user.uid,
                    fullName: nameController.text.trim(),
                  );
                  await _loadUserProfile();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating profile: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Show Change Password Dialog
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters')),
                );
                return;
              }
              // TODO: Implement password change with Firebase Auth
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password change feature coming soon!'),
                  backgroundColor: Colors.orangeAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  // Show Delete Account Dialog
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Account'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Implement account deletion
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion feature coming soon!'),
                  backgroundColor: Colors.orangeAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  // Show Privacy & Security Dialog
  void _showPrivacySecurityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text('Privacy & Security'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Visibility
              const Text(
                'Profile Visibility',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Public Profile'),
                subtitle: const Text('Others can see your recipes'),
                value: true,
                onChanged: (value) {},
                activeColor: Colors.orangeAccent,
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              
              // Data Settings
              const Text(
                'Data Settings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Save Search History'),
                subtitle: const Text('Remember your recent searches'),
                value: true,
                onChanged: (value) {},
                activeColor: Colors.orangeAccent,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              
              // Clear Data Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showClearDataDialog();
                  },
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clear Local Data'),
                ),
              ),
              const Divider(),
              
              // Security
              const Text(
                'Security',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('Biometric Login'),
                subtitle: const Text('Use fingerprint to login'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                  activeColor: Colors.orangeAccent,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Show Clear Data Dialog
  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Local Data'),
        content: const Text(
          'This will clear all locally stored data including saved images and preferences. Your account and cloud data will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await Pref.init(); // Re-initialize
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Local data cleared successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final isLoggedIn = user != null;
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.orangeAccent),
        ),
      );
    }

    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Image.asset(
                'assets/images/cook-book.png',
                height: 30,
              ),
              const SizedBox(width: 8),
              const Text(
                "FLAVOR FIESTA",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 50,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Not Signed In',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to view your profile',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: themeProvider.isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: themeProvider.isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/cook-book.png',
              height: 30,
            ),
            const SizedBox(width: 8),
            Text(
              "FLAVOR FIESTA",
              style: TextStyle(
                color: themeProvider.isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Profile Picture Section
            Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : (_localProfilePicPath != null
                                ? DecorationImage(
                                    image: FileImage(File(_localProfilePicPath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null),
                      ),
                      child: (_selectedImage == null && _localProfilePicPath == null)
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingImage ? null : _pickImage,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[800],
                          ),
                          child: _isUploadingImage
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              _userProfile?['fullName'] ?? 'User',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDark ? Colors.white : Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            // Email
            Text(
              user.email ?? 'No email',
              style: TextStyle(
                fontSize: 16,
                color: themeProvider.isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),

            const SizedBox(height: 32),

            // Stats Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('24', 'Recipes', themeProvider),
                  _buildStatCard('8', 'Created', themeProvider),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Preferences Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildPreferenceRow(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {
                      _showNotificationsDialog();
                    },
                    themeProvider: themeProvider,
                  ),
                  const SizedBox(height: 12),

                  // 🌙 Dark Mode Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: themeProvider.isDark ? Colors.grey[850] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.dark_mode, color: themeProvider.isDark ? Colors.white : Colors.black87),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Dark Mode",
                            style: TextStyle(
                              fontSize: 16,
                              color: themeProvider.isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Switch(
                          value: themeProvider.isDark,
                          onChanged: (value) {
                            themeProvider.toggleTheme(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceRow(
                    icon: Icons.settings_outlined,
                    title: 'Account Settings',
                    onTap: () {
                      _showAccountSettingsDialog();
                    },
                    themeProvider: themeProvider,
                  ),
                  const SizedBox(height: 12),
                  _buildPreferenceRow(
                    icon: Icons.lock_outline,
                    title: 'Privacy & Security',
                    onTap: () {
                      _showPrivacySecurityDialog();
                    },
                    themeProvider: themeProvider,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String number, String label, ThemeProvider themeProvider) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: themeProvider.isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: themeProvider.isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: themeProvider.isDark ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: themeProvider.isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: themeProvider.isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}

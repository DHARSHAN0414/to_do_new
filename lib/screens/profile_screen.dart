import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../widgets/user_avatar.dart';
import '../widgets/app_button.dart';
import '../widgets/input_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize theme settings when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().initializeTheme();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;
    final isLargeScreen = screenSize.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: !isTablet,
        actions: [
          if (isTablet)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                onPressed: () => _showEditProfileDialog(context),
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Profile',
              ),
            ),
        ],
      ),
      body: _buildBody(theme, isTablet, isLargeScreen),
    );
  }

  Widget _buildBody(ThemeData theme, bool isTablet, bool isLargeScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 600 : (isTablet ? 500 : double.infinity),
          ),
          child: Consumer<AuthViewModel>(
            builder: (context, authViewModel, _) {
              return Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(theme, authViewModel, isTablet),
                  
                  SizedBox(height: isTablet ? 32 : 24),
                  
                  // Settings Sections
                  _buildSettingsSections(theme, authViewModel, isTablet),
                  
                  SizedBox(height: isTablet ? 32 : 24),
                  
                  // Sign Out Button
                  _buildSignOutSection(theme, authViewModel, isTablet),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, AuthViewModel authViewModel, bool isTablet) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          children: [
            // Avatar
            UserAvatar(
              photoUrl: authViewModel.photoUrl,
              displayName: authViewModel.displayName,
              email: authViewModel.userEmail,
              size: isTablet ? 80 : 64,
              isEditable: true,
              onTap: () => _showEditProfileDialog(context),
            ),
            
            SizedBox(height: isTablet ? 16 : 12),
            
            // User Info
            Text(
              authViewModel.displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: isTablet ? 8 : 4),
            
            Text(
              authViewModel.userEmail,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (!isTablet) ...[
              SizedBox(height: 16),
              SecondaryButton(
                onPressed: () => _showEditProfileDialog(context),
                label: 'Edit Profile',
                icon: Icons.edit,
                size: AppButtonSize.small,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSections(ThemeData theme, AuthViewModel authViewModel, bool isTablet) {
    return Column(
      children: [
        // Appearance Section
        _buildSettingsSection(
          theme,
          'Appearance',
          [
            _buildDarkModeTile(theme, authViewModel, isTablet),
          ],
          isTablet,
        ),
        
        SizedBox(height: isTablet ? 24 : 16),
        
        // Account Section
        _buildSettingsSection(
          theme,
          'Account',
          [
            _buildAccountInfoTile(
              theme,
              'Email',
              authViewModel.userEmail,
              Icons.email,
              isTablet,
            ),
            _buildAccountInfoTile(
              theme,
              'Account Type',
              _getAccountType(authViewModel),
              Icons.account_circle,
              isTablet,
            ),
          ],
          isTablet,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
    ThemeData theme,
    String title,
    List<Widget> children,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Card(
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDarkModeTile(ThemeData theme, AuthViewModel authViewModel, bool isTablet) {
    return SwitchListTile(
      title: Text(
        'Dark Mode',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        authViewModel.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      value: authViewModel.isDarkMode,
      onChanged: (_) => authViewModel.toggleDarkMode(),
      secondary: Icon(
        authViewModel.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: theme.colorScheme.primary,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 12 : 8,
      ),
    );
  }

  Widget _buildAccountInfoTile(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    bool isTablet,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 8 : 4,
      ),
    );
  }

  Widget _buildSignOutSection(ThemeData theme, AuthViewModel authViewModel, bool isTablet) {
    return Column(
      children: [
        DangerOutlinedButton(
          onPressed: () => _showSignOutDialog(context, authViewModel),
          label: 'Sign Out',
          icon: Icons.logout,
          isFullWidth: true,
          isLoading: authViewModel.isLoading,
        ),
        
        SizedBox(height: isTablet ? 16 : 12),
        
        Text(
          'Signing out will end your current session',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getAccountType(AuthViewModel authViewModel) {
    final user = authViewModel.currentUser;
    if (user == null) return 'Unknown';
    
    if (user.providerData.any((provider) => provider.providerId == 'google.com')) {
      return 'Google Account';
    }
    
    if (user.providerData.any((provider) => provider.providerId == 'password')) {
      return 'Email & Password';
    }
    
    return 'Email & Password';
  }

  void _showEditProfileDialog(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();
    final nameController = TextEditingController(text: authViewModel.displayName);
    final emailController = TextEditingController(text: authViewModel.userEmail);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(
              photoUrl: authViewModel.photoUrl,
              displayName: authViewModel.displayName,
              email: authViewModel.userEmail,
              size: 60,
              isEditable: true,
            ),
            const SizedBox(height: 16),
            InputFieldWithLabel(
              label: 'Display Name',
              controller: nameController,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            InputFieldWithLabel(
              label: 'Email',
              controller: emailController,
              enabled: false,
              helperText: 'Email cannot be changed',
            ),
          ],
        ),
        actions: [
          SecondaryButton(
            onPressed: () => Navigator.pop(context),
            label: 'Cancel',
          ),
          PrimaryButton(
            onPressed: () {
              // In a real app, you'd update the user profile here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile update feature coming soon!'),
                ),
              );
            },
            label: 'Save',
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthViewModel authViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          SecondaryButton(
            onPressed: () => Navigator.pop(context),
            label: 'Cancel',
          ),
          DangerButton(
            onPressed: () async {
              Navigator.pop(context);
              await authViewModel.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/signin');
              }
            },
            label: 'Sign Out',
          ),
        ],
      ),
    );
  }
}

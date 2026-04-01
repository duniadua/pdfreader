import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/data/models/app_settings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/profile_icon_button.dart';
import '../../drive/presentation/providers/drive_notifier.dart';
import '../../auth/presentation/providers/auth_notifier.dart';
import '../../auth/presentation/widgets/login_bottom_sheet.dart';
import '../../auth/data/auth_repository_provider.dart';
import 'providers/settings_notifier.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hasLoggedScreenView = false;

  @override
  Widget build(BuildContext context) {
    // Track screen view once
    if (!_hasLoggedScreenView) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AnalyticsService.instance.trackScreenView(
          screenName: 'SettingsScreen',
          screenClass: 'SettingsScreen',
        );
      });
      _hasLoggedScreenView = true;
    }

    final state = ref.watch(settingsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for failures
    ref.listen<SettingsState>(settingsNotifierProvider, (previous, next) {
      next.failure?.let((failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Theme.of(context).colorScheme.error,
              onPressed: () {
                ref.read(settingsNotifierProvider.notifier).dismissFailure();
              },
            ),
          ),
        );
      });
    });

    return Scaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(context),

          // Body Content
          Expanded(child: _buildBody(state.settings)),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(isDark),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppTheme.backgroundDark
        : AppTheme.backgroundLight;

    return Container(
      decoration: BoxDecoration(color: backgroundColor.withValues(alpha: 0.8)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              // Back button
              InkWell(
                onTap: () => context.go(AppRoutes.library),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Title
              Expanded(
                child: Text(
                  'Settings',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(bool isDark) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.12)
                : const Color(0xFFE2E8F0).withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home,
            label: 'Home',
            isSelected: false,
            onTap: () => context.go(AppRoutes.library),
          ),
          _buildNavItem(
            icon: Icons.settings,
            label: 'Settings',
            isSelected: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.primary : const Color(0xFF94A3B8),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? AppTheme.primary
                  : isDark
                  ? Colors.white
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppSettings settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Section: Display
          _buildSectionHeader('Display', isDark),
          _buildSettingsGroup(
            isDark: isDark,
            children: [
              _buildDarkModeSetting(
                isDark: isDark,
                value: settings.darkMode,
                onChanged: (value) {
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .setDarkMode(value);
                },
              ),
              _buildDivider(isDark),
              _buildBrightnessSetting(
                isDark: isDark,
                value: settings.brightness,
                onChanged: (value) {
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .setBrightness(value);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Section: Account
          _buildSectionHeader('Account', isDark),
          _buildSettingsGroup(
            isDark: isDark,
            children: [
              _buildAccountProfile(isDark: isDark),
              _buildDivider(isDark),
              _buildAppVersion(isDark: isDark),
            ],
          ),

          const SizedBox(height: 24),

          // Section: Google Drive
          _buildSectionHeader('Google Drive', isDark),
          _buildSettingsGroup(
            isDark: isDark,
            children: [_buildDriveSettings(isDark: isDark)],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDriveSettings({required bool isDark}) {
    final driveState = ref.watch(driveNotifierProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.cloud,
                  color: driveState.isConnected
                      ? Colors.green
                      : isDark
                      ? Colors.white
                      : const Color(0xFF334155),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              // Status info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Drive',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      driveState.isConnected
                          ? 'Connected${driveState.userName != null ? " as ${driveState.userName}" : ""}'
                          : 'Not connected',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              // Connect/Disconnect button
              if (driveState.isConnected)
                TextButton(
                  onPressed: () => _disconnectDrive(),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(
                    'Disconnect',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => _connectDrive(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    'Connect',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          // File count info when connected
          if (driveState.isConnected && driveState.files.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const SizedBox(width: 56), // Align with text above
                  Text(
                    '${driveState.files.length} PDF files available',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _connectDrive() async {
    final authRepo = ref.read(firebaseAuthRepositoryProvider);

    try {
      // Get Google credentials
      final credentials = await authRepo.getGoogleCredentials();

      if (credentials == null) {
        // User needs to sign in first
        if (mounted) {
          showLoginBottomSheet(context, ref);
        }
        return;
      }

      // Connect to Drive
      final success = await ref
          .read(driveNotifierProvider.notifier)
          .connect(
            accessToken: credentials['accessToken'] as String,
            refreshToken: credentials['refreshToken'] as String,
            expiry: credentials['expiry'] as DateTime,
          );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to Google Drive'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Failed to connect to Drive', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnectDrive() async {
    await ref.read(driveNotifierProvider.notifier).disconnect();
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282E39) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.2)
            : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildDarkModeSetting({
    required bool isDark,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.dark_mode,
                color: isDark ? Colors.white : const Color(0xFF334155),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Dark Mode',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrightnessSetting({
    required bool isDark,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.brightness_6,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Brightness',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.light_mode_outlined,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
                size: 20,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 6,
                    activeTrackColor: AppTheme.primary,
                    inactiveTrackColor: isDark
                        ? const Color(0xFF282E39)
                        : const Color(0xFFE2E8F0),
                    thumbColor: Colors.white,
                    overlayColor: AppTheme.primary.withValues(alpha: 0.1),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: value,
                    onChanged: onChanged,
                    min: 0.0,
                    max: 1.0,
                  ),
                ),
              ),
              Icon(
                Icons.light_mode,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountProfile({required bool isDark}) {
    final authState = ref.watch(authNotifierProvider);

    return InkWell(
      onTap: () => showLoginBottomSheet(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar - use ProfileIconButton for auth-aware icon
            const ProfileIconButton(),
            const SizedBox(width: 16),
            Expanded(
              child: authState.when(
                initial: () => _buildGuestUserInfo(isDark),
                unauthenticated: () => _buildGuestUserInfo(isDark),
                loading: () => _buildLoadingUserInfo(isDark),
                authenticated: (user) =>
                    _buildAuthenticatedUserInfo(user, isDark),
                error: (_) => _buildGuestUserInfo(isDark),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestUserInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Local User',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        Text(
          'Offline Mode',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingUserInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Loading...',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        Text(
          'Please wait',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatedUserInfo(dynamic user, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName ?? 'User',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Online Mode',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppVersion({required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Center(
        child: Text(
          'Version 1.0.0 (Build 1)',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

/// Extension for nullable types
extension LetExtension<T> on T? {
  R? let<R>(R Function(T) callback) {
    final value = this;
    if (value != null) {
      return callback(value);
    }
    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/data/models/app_settings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import 'providers/settings_notifier.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: _buildBody(state.settings),
          ),
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
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.8),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              // Avatar with person icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Text(
                'Settings',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              // Home button to navigate back
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => context.go(AppRoutes.library),
                splashRadius: 24,
              ),
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
        color: isDark
            ? AppTheme.backgroundDark
            : AppTheme.backgroundLight,
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

          // Dark Mode Setting
          _buildSettingCard(
            isDark: isDark,
            child: _buildDarkModeSetting(
              value: settings.darkMode,
              onChanged: (value) {
                ref.read(settingsNotifierProvider.notifier).setDarkMode(value);
              },
            ),
          ),

          const SizedBox(height: 12),

          // Font Size Setting
          _buildSettingCard(
            isDark: isDark,
            child: _buildFontSizeSetting(
              isDark: isDark,
              value: settings.fontSize.toInt(),
              onDecrease: () {
                ref.read(settingsNotifierProvider.notifier)
                    .setFontSize(settings.fontSize - 1);
              },
              onIncrease: () {
                ref.read(settingsNotifierProvider.notifier)
                    .setFontSize(settings.fontSize + 1);
              },
            ),
          ),

          const SizedBox(height: 12),

          // Brightness Setting
          _buildSettingCard(
            isDark: isDark,
            child: _buildBrightnessSetting(
              isDark: isDark,
              value: settings.brightness,
              onChanged: (value) {
                ref.read(settingsNotifierProvider.notifier).setBrightness(value);
              },
            ),
          ),

          const SizedBox(height: 12),

          // Scroll Direction Setting
          _buildSettingCard(
            isDark: isDark,
            child: _buildScrollDirectionSetting(
              isDark: isDark,
              value: settings.scrollDirection,
              onChanged: (value) {
                ref.read(settingsNotifierProvider.notifier).setScrollDirection(value);
              },
            ),
          ),

          const SizedBox(height: 12),

          // Auto Crop Margins Setting
          _buildSettingCard(
            isDark: isDark,
            child: _buildToggleSetting(
              isDark: isDark,
              icon: Icons.crop,
              title: 'Auto Crop Margins',
              value: settings.autoCropMargins,
              onChanged: (value) {
                ref.read(settingsNotifierProvider.notifier).setAutoCropMargins(value);
              },
            ),
          ),

          const SizedBox(height: 24),

          // Reset Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(settingsNotifierProvider.notifier).resetToDefaults();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset to Defaults'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.red.shade300 : Colors.red.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.05)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildDarkModeSetting({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          value ? Icons.dark_mode : Icons.light_mode,
          color: isDark ? Colors.white : const Color(0xFF334155),
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Dark Mode',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primary,
        ),
      ],
    );
  }

  Widget _buildFontSizeSetting({
    required bool isDark,
    required int value,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Row(
      children: [
        Icon(
          Icons.format_size,
          color: isDark ? Colors.white : const Color(0xFF334155),
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Font Size',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decrease button
            InkWell(
              onTap: value > AppConstants.minFontSize ? onDecrease : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.white24 : const Color(0xFF1E293B).withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.remove,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Font size display
            Text(
              value.toString(),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 16),
            // Increase button
            InkWell(
              onTap: value < AppConstants.maxFontSize ? onIncrease : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.white24 : const Color(0xFF1E293B).withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBrightnessSetting({
    required bool isDark,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(
          Icons.brightness_6,
          color: isDark ? Colors.white : const Color(0xFF334155),
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Brightness',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(value * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 120,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: AppTheme.primary.withValues(alpha: 0.5),
              inactiveTrackColor: AppTheme.primary.withValues(alpha: 0.2),
              thumbColor: AppTheme.primary,
              overlayColor: AppTheme.primary.withValues(alpha: 0.1),
              valueIndicatorColor: AppTheme.primary,
              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(value * 100).toInt()}%',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollDirectionSetting({
    required bool isDark,
    required ScrollDirection value,
    required ValueChanged<ScrollDirection> onChanged,
  }) {
    return Row(
      children: [
        Icon(
          Icons.swap_vert,
          color: isDark ? Colors.white : const Color(0xFF334155),
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scroll Direction',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value == ScrollDirection.vertical ? 'Vertical' : 'Horizontal',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        SegmentedButton<ScrollDirection>(
          segments: const [
            ButtonSegment(
              value: ScrollDirection.vertical,
              icon: Icon(Icons.arrow_downward, size: 16),
              label: Text('V'),
            ),
            ButtonSegment(
              value: ScrollDirection.horizontal,
              icon: Icon(Icons.arrow_back, size: 16),
              label: Text('H'),
            ),
          ],
          selected: {value},
          onSelectionChanged: (Set<ScrollDirection> newSelection) {
            if (newSelection.isNotEmpty) {
              onChanged(newSelection.first);
            }
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return AppTheme.primary.withValues(alpha: 0.2);
              }
              return null;
            }),
            foregroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return AppTheme.primary;
              }
              return isDark ? Colors.white : const Color(0xFF64748B);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSetting({
    required bool isDark,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isDark ? Colors.white : const Color(0xFF334155),
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primary,
        ),
      ],
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

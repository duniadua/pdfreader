import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/auth_notifier.dart';

/// Shows the login/profile bottom sheet.
///
/// Displays different content based on authentication state:
/// - Unauthenticated: Google Sign-In button
/// - Authenticated: User profile with logout option
void showLoginBottomSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _LoginBottomSheet(),
  );
}

class _LoginBottomSheet extends ConsumerWidget {
  const _LoginBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: authState.when(
            initial: () => _buildUnauthenticated(context, isDark, ref),
            unauthenticated: () => _buildUnauthenticated(context, isDark, ref),
            loading: () => _buildLoading(context, isDark),
            authenticated: (user) => _buildAuthenticated(
              context,
              isDark,
              user,
              ref,
            ),
            error: (message) => _buildError(
              context,
              isDark,
              message,
              ref,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnauthenticated(
    BuildContext context,
    bool isDark,
    WidgetRef ref,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Text(
          'Sign in to your account',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),

        // Subtitle
        Text(
          'Sign in to sync your reading progress across devices',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Google Sign-In Button
        _buildGoogleSignInButton(context, isDark, ref),

        const SizedBox(height: 16),

        // Info text
        Text(
          'By signing in, you agree to our Terms of Service',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(
    BuildContext context,
    bool isDark,
    WidgetRef ref,
  ) {
    return InkWell(
      onTap: () async {
        Navigator.of(context).pop();
        await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google Logo
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const _GoogleLogo(),
            ),
            const SizedBox(width: 12),
            // Sign in text
            Text(
              'Continue with Google',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticated(
    BuildContext context,
    bool isDark,
    dynamic user,
    WidgetRef ref,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Close button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: isDark ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Profile photo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: user.photoUrl != null && user.photoUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.network(
                    user.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        size: 40,
                        color: AppTheme.primary,
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.person,
                  size: 40,
                  color: AppTheme.primary,
                ),
        ),
        const SizedBox(height: 16),

        // User name
        Text(
          user.displayName ?? 'User',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),

        // User email
        Text(
          user.email,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 24),

        // Online indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Online Mode',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Sign Out Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authNotifierProvider.notifier).signOut();
            },
            icon: const Icon(Icons.logout, size: 18),
            label: Text(
              'Sign Out',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(
                color: Colors.red.withValues(alpha: 0.3),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading(BuildContext context, bool isDark) {
    return const SizedBox(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    bool isDark,
    String message,
    WidgetRef ref,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: Colors.red,
        ),
        const SizedBox(height: 16),
        Text(
          'Authentication Error',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            ref.read(authNotifierProvider.notifier).dismissError();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Close',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom Google G logo widget
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final path = Path();

    // Draw Google "G" logo
    // Red part
    paint.color = const Color(0xFFEA4335);
    path.addRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 9, 9),
      const Radius.circular(2),
    ));
    canvas.drawPath(path, paint);
    path.reset();

    // Yellow part
    paint.color = const Color(0xFFFBBC05);
    path.addRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(9, 0, 6, 9),
      const Radius.circular(2),
    ));
    canvas.drawPath(path, paint);
    path.reset();

    // Green part
    paint.color = const Color(0xFF34A853);
    path.addRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 9, 9, 6),
      const Radius.circular(2),
    ));
    canvas.drawPath(path, paint);
    path.reset();

    // Blue part
    paint.color = const Color(0xFF4285F4);
    path.addRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(9, 9, 6, 6),
      const Radius.circular(2),
    ));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

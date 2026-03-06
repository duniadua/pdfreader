import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/auth/domain/entities/auth_state.dart';
import '../../../features/auth/presentation/providers/auth_notifier.dart';
import '../../../features/auth/presentation/widgets/login_bottom_sheet.dart';

/// A reusable profile icon button that shows the login bottom sheet when tapped.
///
/// Displays different content based on authentication state:
/// - Unauthenticated: Person icon with primary color
/// - Authenticated: User profile photo or person icon
class ProfileIconButton extends ConsumerWidget {
  const ProfileIconButton({
    super.key,
    this.size = 40,
  });

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return InkWell(
      onTap: () => showLoginBottomSheet(context, ref),
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: _buildIcon(authState),
      ),
    );
  }

  Widget _buildIcon(AuthState state) {
    return state.when(
      initial: () => _buildDefaultIcon(),
      unauthenticated: () => _buildDefaultIcon(),
      loading: () => _buildLoadingIndicator(),
      authenticated: (user) => _buildUserIcon(user),
      error: (_) => _buildDefaultIcon(),
    );
  }

  Widget _buildDefaultIcon() {
    return Icon(
      Icons.person,
      color: AppTheme.primary,
      size: size * 0.6,
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: size * 0.5,
      height: size * 0.5,
      child: const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
      ),
    );
  }

  Widget _buildUserIcon(dynamic user) {
    final photoUrl = user.photoUrl;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildDefaultIcon(),
          errorWidget: (context, url, error) => _buildDefaultIcon(),
        ),
      );
    }

    return _buildDefaultIcon();
  }
}

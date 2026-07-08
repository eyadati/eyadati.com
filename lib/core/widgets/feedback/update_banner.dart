import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../theme/text_styles.dart';

class AppWithUpdateBanner extends StatefulWidget {
  final Widget child;
  const AppWithUpdateBanner({super.key, required this.child});

  @override
  State<AppWithUpdateBanner> createState() => _AppWithUpdateBannerState();
}

class _AppWithUpdateBannerState extends State<AppWithUpdateBanner>
    with SingleTickerProviderStateMixin {
  bool _updateAvailable = false;
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _listenForUpdates();
  }

  void _listenForUpdates() {
    if (!kIsWeb) return;

    // Listen for custom event dispatched by index.html when SW update is detected
    html.window.addEventListener('sw-update-ready', (_) {
      if (mounted) {
        setState(() => _updateAvailable = true);
        _animCtrl.forward();
      }
    });

    // Also try the standard SW updatefound API as fallback
    final sw = html.window.navigator.serviceWorker;
    if (sw == null) return;
    sw.getRegistration().then((reg) {
      reg.addEventListener('updatefound', (e) {
        final installing = reg.installing;
        if (installing == null) return;
        installing.addEventListener('statechange', (e) {
          if (installing.state == 'installed' && mounted) {
            setState(() => _updateAvailable = true);
            _animCtrl.forward();
          }
        });
      });
    });
  }

  void _applyUpdate() {
    html.window.location.reload();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_updateAvailable)
          SafeArea(
            child: SlideTransition(
              position: _slideAnim,
              child: Material(
                elevation: 8,
                shadowColor: AppColors.shadow,
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.md,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          color: AppColors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Nouvelle version disponible',
                              style: AppTextStyles.sectionTitle.copyWith(
                                color: AppColors.white,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Appuyez pour mettre à jour vers la dernière version',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: _applyUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                          ),
                          child: const Text(
                            'Mettre à jour',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
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
      ],
    );
  }
}

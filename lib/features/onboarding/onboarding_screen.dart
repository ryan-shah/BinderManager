import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';


/// Full-screen onboarding overlay shown on first launch.
///
/// Presents a centered card that lets the user trigger a (placeholder) card
/// data download. Agent A will replace the fake progress with the real
/// Scryfall import pipeline.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _downloading = false;
  double _progress = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startDownload() {
    setState(() {
      _downloading = true;
      _progress = 0;
    });

    // Simulate fake progress: 0 -> 100% over ~3 seconds (30 ticks x 100ms).
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progress += 1 / 30;
        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
          // Navigate to the main app after a short pause.
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) {
              context.go('/binders');
            }
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.neutral0,
                borderRadius: BorderRadius.circular(AppRadii.xxl),
                boxShadow: const [AppShadows.modal],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'Welcome to BinderManager',
                      style: AppTypography.headingXl,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Subtitle
                    Text(
                      'Download card data to get started',
                      style:
                          AppTypography.body.copyWith(color: AppColors.neutral600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Size info
                    Text(
                      '~150 MB of card data from Scryfall',
                      style: AppTypography.bodyXs
                          .copyWith(color: AppColors.neutral500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Web consent note
                    if (kIsWeb) ...[
                      _WebConsentNote(),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Download button — hidden once download starts
                    if (!_downloading)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _startDownload,
                          child: const Text('Download Card Data'),
                        ),
                      ),

                    // Progress section
                    if (_downloading) ...[
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        child: SizedBox(
                          height: 8,
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: AppColors.neutral150,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.neutral900),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Downloading... ${(_progress * 100).round()}%',
                        style: AppTypography.meta
                            .copyWith(color: AppColors.neutral500),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Amber banner shown only on web to explain persistent storage requirements.
class _WebConsentNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.amberBg,
        border: Border.all(color: AppColors.amberBorder),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Text(
        'This app stores card data in your browser. '
        'Your browser may ask for permission to use persistent storage.',
        style: AppTypography.bodyXs.copyWith(color: AppColors.amberText),
      ),
    );
  }
}

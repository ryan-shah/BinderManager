import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/providers/corpus_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(corpusImportProvider);

    // Navigate to main app once import completes
    ref.listen(corpusImportProvider, (prev, next) {
      if (next.complete) {
        ref.invalidate(corpusReadyProvider);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (context.mounted) context.go('/binders');
        });
      }
    });

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
                    Text(
                      'Welcome to BinderManager',
                      style: AppTypography.headingXl,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Download card data to get started',
                      style: AppTypography.body
                          .copyWith(color: AppColors.neutral600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '~150 MB of card data from Scryfall',
                      style: AppTypography.bodyXs
                          .copyWith(color: AppColors.neutral500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    if (kIsWeb) ...[
                      _WebConsentNote(),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Error state
                    if (importState.error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.statusRemoveBg,
                          border:
                              Border.all(color: AppColors.statusRemoveBorder),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: Text(
                          importState.error!,
                          style: AppTypography.bodyXs
                              .copyWith(color: AppColors.statusRemoveText),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Download button — shown when idle or after error
                    if (importState.phase == 'idle' ||
                        importState.error != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(corpusImportProvider.notifier).runImport();
                          },
                          child: Text(importState.error != null
                              ? 'Retry Download'
                              : 'Download Card Data'),
                        ),
                      ),

                    // Progress section
                    if (importState.phase != 'idle' &&
                        importState.error == null &&
                        !importState.complete) ...[
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        child: SizedBox(
                          height: 8,
                          child: LinearProgressIndicator(
                            value: importState.progress,
                            backgroundColor: AppColors.neutral150,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.neutral900),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _statusText(importState),
                        style: AppTypography.meta
                            .copyWith(color: AppColors.neutral500),
                      ),
                    ],

                    // Complete state
                    if (importState.complete) ...[
                      const SizedBox(height: AppSpacing.md),
                      Icon(Icons.check_circle,
                          color: AppColors.statusAddText, size: 32),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        importState.phase,
                        style: AppTypography.meta
                            .copyWith(color: AppColors.statusAddText),
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

  String _statusText(CorpusImportState state) {
    if (state.progress != null) {
      return '${state.phase}... ${(state.progress! * 100).round()}%';
    }
    return '${state.phase}...';
  }
}

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

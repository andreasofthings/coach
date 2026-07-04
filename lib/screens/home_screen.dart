import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                       ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lightbulb,
                          size: 32,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.readyToInnovate,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.homeSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            child: Text(AppLocalizations.of(context)!.startSession, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final Uri githubIssueUri = Uri.parse(
                                'https://github.com/andreasofthings/coach/issues/new'
                                '?title=%5BFeature+Request%5D+'
                                '&labels=enhancement'
                                '&body=%23%23+Feature+Request%0A%0A'
                                '**Description**%0A'
                                'Describe+your+idea+here...%0A%0A'
                                '**Why+is+this+needed?**%0A'
                                'Explain+how+this+helps+facilitators+or+consultants.%0A%0A'
                                '**Additional+Context**%0A'
                                'Any+other+details+or+links.'
                              );
                              if (await canLaunchUrl(githubIssueUri)) {
                                await launchUrl(githubIssueUri, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.lightbulb_outline),
                            label: Text(AppLocalizations.of(context)!.submitIdea),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              side: BorderSide(color: colorScheme.primary),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

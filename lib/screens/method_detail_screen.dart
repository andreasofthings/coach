import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/method.dart';

class MethodDetailScreen extends StatelessWidget {
  final Method method;

  const MethodDetailScreen({super.key, required this.method});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.methodDetails, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDOFd1Ucr6JHagj6FOSc1WeUFAcgrW-n0uVujmYR-s1bTbYoblMj2p1Ji0aEqG9Pw7wJzGWUlE2-iqYrd4l5Et2huBJhZQN1O_Z9RfMNBTrClt6l5zymhIs868l2glAj72Ds9eY7S1Z0BdP7sAHaWgNDwZ2gpFgNPPPe7r0lZ_vRXHQWbrJAi-4DFBWpNA499-gcS6mRWyyvY2rRKG5CpK4aSe54xw_9D1p0ZpJJAN8NX3gWQajD6yM7tNRJcTvggEMVe23-f2tp-U'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                method.methodType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.minutesCapsLabel(30),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          method.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Bento Grid for Meta
            Row(
              children: [
                Expanded(
                  child: _buildMetaCard(
                    context,
                    Icons.psychology,
                    AppLocalizations.of(context)!.methodInput,
                    [
                      AppLocalizations.of(context)!.paperSharpies,
                      AppLocalizations.of(context)!.oneToEightParticipants,
                      AppLocalizations.of(context)!.timer
                    ],
                    colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetaCard(
                    context,
                    Icons.output,
                    AppLocalizations.of(context)!.methodOutput,
                    [
                      AppLocalizations.of(context)!.eightRoughSketches,
                      AppLocalizations.of(context)!.diverseIdeas,
                      AppLocalizations.of(context)!.nextStepFocus
                    ],
                    colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Why Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.secondaryContainer),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stars, color: colorScheme.secondary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.theWhyBenefit,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    method.benefit,
                    style: TextStyle(color: colorScheme.onSecondaryContainer),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // How Section
            Row(
              children: [
                Icon(Icons.format_list_numbered, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.theHowProcess,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._buildHowSteps(context),
            const SizedBox(height: 24),
            // Pro Tip
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb, color: colorScheme.tertiaryContainer),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.proTip, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          AppLocalizations.of(context)!.crazyEightsProTipDesc,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaCard(BuildContext context, IconData icon, String title, List<String> items, Color accentColor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Row(
                  children: [
                    Container(width: 4, height: 4, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(item, style: const TextStyle(fontSize: 11))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  List<Widget> _buildHowSteps(BuildContext context) {
    final steps = [
      {'title': AppLocalizations.of(context)!.step1Title, 'desc': AppLocalizations.of(context)!.step1Desc},
      {'title': AppLocalizations.of(context)!.step2Title, 'desc': AppLocalizations.of(context)!.step2Desc},
      {'title': AppLocalizations.of(context)!.step3Title, 'desc': AppLocalizations.of(context)!.step3Desc},
      {'title': AppLocalizations.of(context)!.step4Title, 'desc': AppLocalizations.of(context)!.step4Desc},
    ];

    return steps.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final step = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(step['desc']!, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

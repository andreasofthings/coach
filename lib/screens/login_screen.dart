import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        centerTitle: true,
        backgroundColor: isDark ? colorScheme.surface : const Color(0xFF000000),
        foregroundColor: colorScheme.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                         MediaQuery.of(context).padding.top -
                         MediaQuery.of(context).padding.bottom -
                         kToolbarHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lightbulb_outline,
                                size: 64,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              AppLocalizations.of(context)!.readyToCoach,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.loginSubtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              _handleLogin(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.login,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.madeWithLove,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        GestureDetector(
                          onTap: () {
                            launchUrl(Uri.parse('https://neumeier.org'));
                          },
                          child: Text(
                            'https://neumeier.org',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    try {
      await context.read<AuthProvider>().login();
    } catch (e) {
      _showError(context, e);
    }
  }

  void _showError(BuildContext context, dynamic e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.loginFailed(e.toString()))),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/workshop_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> get _screens => [
    const HomeContent(),
    const LibraryScreen(isFavoritesOnly: false),
    const WorkshopScreen(),
    Center(child: Text(AppLocalizations.of(context)!.menuPlaceholder)),
  ];

  void _onItemTapped(int index) {
    if (index == 3) {
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userProvider = context.watch<UserProvider>();
    final userProfile = userProvider.profile;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.lightbulb, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.appTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  (userProfile?.name.isNotEmpty == true ? userProfile?.name[0] : 'A')!,
                  style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 24),
                ),
              ),
              accountName: Text(
                userProfile?.name ?? 'Alex Rivers',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              accountEmail: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userProfile?.email ?? 'facilitator@example.com',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.coachLevel(userProfile?.level ?? 1),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(AppLocalizations.of(context)!.profile),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: Text(AppLocalizations.of(context)!.favorites),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/favorites');
              },
            ),
            ListTile(
              leading: const Icon(Icons.contacts),
              title: Text(AppLocalizations.of(context)!.contacts),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/contacts');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: Text(AppLocalizations.of(context)!.chat),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/chat');
              },
            ),
            ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: Text(AppLocalizations.of(context)!.donate),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: colorScheme.error),
              title: Text(AppLocalizations.of(context)!.logout, style: TextStyle(color: colorScheme.error)),
              onTap: () {
                context.read<AuthProvider>().logout();
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                AppLocalizations.of(context)!.buildVersion(const String.fromEnvironment('BUILD_NUMBER', defaultValue: 'local')),
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            destinations: const [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: AppLocalizations.of(context)!.homeLabel,
              ),
              NavigationDestination(
                icon: const Icon(Icons.subscriptions_outlined),
                selectedIcon: const Icon(Icons.subscriptions),
                label: AppLocalizations.of(context)!.libraryLabel,
              ),
              NavigationDestination(
                icon: const Icon(Icons.auto_awesome_outlined),
                selectedIcon: const Icon(Icons.auto_awesome),
                label: AppLocalizations.of(context)!.workshopLabel,
              ),
              NavigationDestination(
                icon: const Icon(Icons.menu),
                label: AppLocalizations.of(context)!.menuLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

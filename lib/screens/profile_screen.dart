import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/contact_provider.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Timer? _debounce;
  bool _isSyncing = false;
  StreamSubscription? _linkSubscription;

  final List<String> _countries = [
    'Germany', 'United States', 'United Kingdom', 'France', 'Spain',
    'Italy', 'Canada', 'Australia', 'Switzerland', 'Austria'
  ];

  final Map<String, IconData> _icons = {
    'person': Icons.person,
    'star': Icons.star,
    'work': Icons.work,
    'school': Icons.school,
    'home': Icons.home,
    'favorite': Icons.favorite,
    'settings': Icons.settings,
    'group': Icons.group,
    'rocket': Icons.rocket_launch,
    'lightbulb': Icons.lightbulb,
  };

  final List<Color> _brandColors = [
    const Color(0xFF25AFF4), // Seed / PrimaryContainer
    const Color(0xFF006590), // Primary
    const Color(0xFF3C627D), // Secondary
    const Color(0xFF845400), // Tertiary
    const Color(0xFFE3940A), // TertiaryContainer
    const Color(0xFFB8DFFE), // SecondaryContainer
    const Color(0xFF171C20), // onSurface
    const Color(0xFF6E7881), // outline
  ];

  @override
  void initState() {
    super.initState();
    _setupLinkListener();
  }

  void _setupLinkListener() {
    final authProvider = context.read<AuthProvider>();
    _linkSubscription = authProvider.linkStream.listen((uri) {
      debugPrint('ProfileScreen received link: $uri');
      // If we're returned from a google connection flow
      if (uri.path.contains('profile') || uri.toString().contains('oauth2redirect')) {
        _handleGoogleSync();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _updateProfileField(UserProfile Function(UserProfile) updater) {
    final userProvider = context.read<UserProvider>();
    final currentProfile = userProvider.profile;
    if (currentProfile != null) {
      final updatedProfile = updater(currentProfile);
      userProvider.updateProfile(updatedProfile);
    }
  }

  Future<void> _handleGoogleSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final contactProvider = context.read<ContactProvider>();
    final userProvider = context.read<UserProvider>();
    
    try {
      final result = await contactProvider.syncGoogleContacts();
      
      if (result.success) {
        // Refresh user profile to update isGoogleConnected status
        await userProvider.fetchProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacts synced successfully')),
          );
        }
      } else if (result.connectUrl != null) {
        if (mounted) {
          _showConnectionDialog(result.connectUrl!);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error ?? 'Sync failed')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showConnectionDialog(String connectUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect Google Account'),
        content: const Text(
          'To sync your contacts, you need to authorize access to your Google account in your browser.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final fullUrl = 'https://www.pramari.de$connectUrl';
              final uri = Uri.parse(fullUrl);
              // Use external application to ensure cookies/session can be shared
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Authorize'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userProvider = context.watch<UserProvider>();
    final profile = userProvider.profile;

    if (profile == null && userProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (profile == null) {
      return const Scaffold(body: Center(child: Text('Profile not found')));
    }

    final avatarColor = Color(int.parse(profile.color.replaceFirst('#', '0xFF')));
    final avatarIcon = _icons[profile.icon] ?? Icons.person;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: avatarColor,
                    child: Icon(avatarIcon, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    profile.email,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              context,
              'PERSONAL INFORMATION',
              [
                _buildDropdown<String>(
                  label: 'Language',
                  value: profile.language,
                  items: [
                    const DropdownMenuItem(value: 'en', child: Text('English')),
                    const DropdownMenuItem(value: 'de', child: Text('German')),
                  ],
                  onChanged: (val) {
                    if (val != null) _updateProfileField((p) => p.copyWith(language: val));
                  },
                ),
                _buildDropdown<String>(
                  label: 'Country',
                  value: _countries.contains(profile.country) ? profile.country : null,
                  hint: 'Select Country',
                  items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) _updateProfileField((p) => p.copyWith(country: val));
                  },
                ),
                ListTile(
                  title: const Text('Date of Birth', style: TextStyle(fontSize: 14)),
                  trailing: Text(
                    profile.dateOfBirth != null ? DateFormat('yyyy-MM-dd').format(profile.dateOfBirth!) : 'Not set',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: profile.dateOfBirth ?? DateTime(1990),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      _updateProfileField((p) => p.copyWith(dateOfBirth: picked));
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),
            _buildSection(
              context,
              'WORKSHOP PREFERENCES',
              [
                _buildDropdown<String>(
                  label: 'Default Setting',
                  value: profile.defaultWorkshopSetting,
                  items: const [
                    DropdownMenuItem(value: 'on-site', child: Text('On-Site')),
                    DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                    DropdownMenuItem(value: 'virtual', child: Text('Virtual')),
                  ],
                  onChanged: (val) {
                    if (val != null) _updateProfileField((p) => p.copyWith(defaultWorkshopSetting: val));
                  },
                ),
                _buildNumberInput(
                  label: 'Default Length (min)',
                  initialValue: profile.defaultWorkshopLength.toString(),
                  onChanged: (val) {
                    final length = int.tryParse(val);
                    if (length != null && length > 0) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        _updateProfileField((p) => p.copyWith(defaultWorkshopLength: length));
                      });
                    }
                  },
                ),
                _buildNumberInput(
                  label: 'Default Group Size',
                  initialValue: profile.defaultGroupSize.toString(),
                  onChanged: (val) {
                    final size = int.tryParse(val);
                    if (size != null && size > 0) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        _updateProfileField((p) => p.copyWith(defaultGroupSize: size));
                      });
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Confidence Level', style: TextStyle(fontSize: 14)),
                          Text('${(profile.confidence * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: profile.confidence,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: '${(profile.confidence * 100).toInt()}%',
                        onChanged: (val) {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(const Duration(milliseconds: 200), () {
                            _updateProfileField((p) => p.copyWith(confidence: val));
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            _buildSection(
              context,
              'VISUAL PREFERENCES',
              [
                ListTile(
                  title: const Text('Theme Color', style: TextStyle(fontSize: 14)),
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: avatarColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                  ),
                  onTap: () => _showColorPicker(context, profile),
                ),
                ListTile(
                  title: const Text('Profile Icon', style: TextStyle(fontSize: 14)),
                  trailing: Icon(avatarIcon, color: colorScheme.primary),
                  onTap: () => _showIconPicker(context, profile),
                ),
              ],
            ),

            const SizedBox(height: 16),
            _buildSection(
              context,
              'INTEGRATIONS',
              [
                ListTile(
                  leading: const Icon(Icons.contacts_outlined),
                  title: const Text('Google Contacts', style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    profile.isGoogleConnected 
                        ? 'Connected • Tap to manage contacts' 
                        : 'Not connected',
                    style: TextStyle(fontSize: 12, color: profile.isGoogleConnected ? Colors.green : null),
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/contacts');
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!profile.isGoogleConnected)
                        TextButton(
                          onPressed: _handleGoogleSync,
                          child: const Text('Connect'),
                        ),
                      if (profile.isGoogleConnected)
                        _isSyncing 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(
                              icon: const Icon(Icons.sync),
                              onPressed: _handleGoogleSync,
                              tooltip: 'Sync Contacts',
                            ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () => context.read<UserProvider>().fetchProfile(),
                        tooltip: 'Refresh Status',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            _buildSection(
              context,
              'ACTIVITY',
              [
                ListTile(
                  title: const Text('Favorite Methods', style: TextStyle(fontSize: 14)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${profile.favorites.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => Navigator.pushNamed(context, '/favorites'),
                ),
              ],
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.read<AuthProvider>().logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: colorScheme.outline),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
  }) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: DropdownButton<T>(
        value: value,
        hint: hint != null ? Text(hint) : null,
        underline: Container(),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNumberInput({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: SizedBox(
        width: 60,
        child: TextFormField(
          initialValue: initialValue,
          key: ValueKey(initialValue), // Ensure it rebuilds with new external value
          textAlign: TextAlign.right,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: InputBorder.none),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Theme Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _brandColors.map((color) {
                  final hex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                  final isSelected = profile.color == hex;
                  return GestureDetector(
                    onTap: () {
                      _updateProfileField((p) => p.copyWith(color: hex));
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, spreadRadius: 1)
                        ],
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showIconPicker(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Profile Icon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: GridView.count(
                  crossAxisCount: 5,
                  children: _icons.entries.map((entry) {
                    final isSelected = profile.icon == entry.key;
                    return IconButton(
                      icon: Icon(entry.value),
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                      onPressed: () {
                        _updateProfileField((p) => p.copyWith(icon: entry.key));
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

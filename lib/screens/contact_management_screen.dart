import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact.dart';
import '../models/workshop.dart';
import '../models/participant.dart';
import '../providers/contact_provider.dart';
import '../providers/workshop_provider.dart';
import '../providers/participant_provider.dart';
import '../providers/user_provider.dart';

class ContactManagementScreen extends StatefulWidget {
  const ContactManagementScreen({super.key});

  @override
  State<ContactManagementScreen> createState() => _ContactManagementScreenState();
}

class _ContactManagementScreenState extends State<ContactManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactProvider>().fetchContacts();
      context.read<WorkshopProvider>().fetchWorkshops();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactProvider = context.watch<ContactProvider>();
    final contacts = contactProvider.contacts.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.firstName.toLowerCase().contains(query) ||
          c.lastName.toLowerCase().contains(query) ||
          c.email.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (contactProvider.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => _handleSync(context),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: contacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.contacts_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No contacts found', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(contact.firstName.isNotEmpty ? contact.firstName[0] : '?'),
                        ),
                        title: Text(contact.fullName),
                        subtitle: Text(contact.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_task, size: 20),
                              tooltip: 'Add to workshop',
                              onPressed: () => _showWorkshopSelectionDialog(context, contact),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              tooltip: 'Edit contact',
                              onPressed: () => _showEditContactDialog(context, contact),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              tooltip: 'Delete contact',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Contact'),
                                    content: Text('Are you sure you want to delete ${contact.fullName}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  context.read<ContactProvider>().deleteContact(contact.id);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _handleSync(BuildContext context) async {
    final contactProvider = context.read<ContactProvider>();
    final userProvider = context.read<UserProvider>();
    final result = await contactProvider.syncGoogleContacts();
    
    if (context.mounted) {
      if (result.success) {
        await userProvider.fetchProfile();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacts synced successfully')),
          );
        }
      } else if (result.connectUrl != null) {
        _showConnectionDialog(context, result.connectUrl!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Failed to sync contacts')),
        );
      }
    }
  }

  void _showConnectionDialog(BuildContext context, String connectUrl) {
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

  void _showAddContactDialog(BuildContext context) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.isEmpty) return;
              final newContact = Contact(
                id: '',
                firstName: firstNameController.text,
                lastName: lastNameController.text,
                email: emailController.text,
              );
              final success = await context.read<ContactProvider>().addContact(newContact);
              if (success && context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditContactDialog(BuildContext context, Contact contact) {
    final firstNameController = TextEditingController(text: contact.firstName);
    final lastNameController = TextEditingController(text: contact.lastName);
    final emailController = TextEditingController(text: contact.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.isEmpty) return;
              final updatedContact = Contact(
                id: contact.id,
                firstName: firstNameController.text,
                lastName: lastNameController.text,
                email: emailController.text,
                googleContactId: contact.googleContactId,
                source: contact.source,
                photoUrl: contact.photoUrl,
              );
              final success = await context.read<ContactProvider>().updateContact(updatedContact);
              if (success && context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWorkshopSelectionDialog(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (context) {
        final workshops = context.watch<WorkshopProvider>().workshops;
        final plannedWorkshops = workshops.where((w) => w.date.isAfter(DateTime.now())).toList();

        return AlertDialog(
          title: Text('Add ${contact.fullName} to Workshop'),
          content: plannedWorkshops.isEmpty
              ? const Text('No planned workshops found.')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: plannedWorkshops.length,
                    itemBuilder: (context, index) {
                      final workshop = plannedWorkshops[index];
                      return ListTile(
                        title: Text(workshop.title),
                        subtitle: Text(DateFormat('MMM dd, yyyy').format(workshop.date)),
                        onTap: () => _addParticipant(context, workshop, contact),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _addParticipant(BuildContext context, Workshop workshop, Contact contact) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final participant = WorkshopParticipant(
      id: '',
      workshop: workshop.id,
      firstName: contact.firstName,
      lastName: contact.lastName,
      email: contact.email,
      source: contact.source,
      googleContactId: contact.googleContactId,
    );

    final success = await context.read<ParticipantProvider>().addParticipant(participant);
    if (context.mounted) {
      Navigator.pop(context);
      if (success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('${contact.fullName} added to ${workshop.title}')),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to add participant')),
        );
      }
    }
  }
}

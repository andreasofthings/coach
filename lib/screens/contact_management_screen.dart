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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        title: Text(AppLocalizations.of(context)!.contacts, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                hintText: AppLocalizations.of(context)!.searchContactsHint2,
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
                        Text(AppLocalizations.of(context)!.noContactsFound, style: TextStyle(color: Colors.grey[600])),
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
                              tooltip: AppLocalizations.of(context)!.addToWorkshopTooltip,
                              onPressed: () => _showWorkshopSelectionDialog(context, contact),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              tooltip: AppLocalizations.of(context)!.editContactTooltip,
                              onPressed: () => _showEditContactDialog(context, contact),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              tooltip: AppLocalizations.of(context)!.deleteContactTooltip,
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(AppLocalizations.of(context)!.deleteContactTitle),
                                    content: Text(AppLocalizations.of(context)!.deleteContactConfirm(contact.fullName)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text(AppLocalizations.of(context)!.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text(AppLocalizations.of(context)!.delete),
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
            SnackBar(content: Text(AppLocalizations.of(context)!.contactsSyncedSuccessfully)),
          );
        }
      } else if (result.connectUrl != null) {
        _showConnectionDialog(context, result.connectUrl!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? AppLocalizations.of(context)!.failedToSyncContacts)),
        );
      }
    }
  }

  void _showConnectionDialog(BuildContext context, String connectUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.connectGoogleAccount),
        content: Text(
          AppLocalizations.of(context)!.googleConnectDesc
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
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
            child: Text(AppLocalizations.of(context)!.authorize),
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
        title: Text(AppLocalizations.of(context)!.addContactTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.firstName),
            ),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.lastName),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.email),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
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
            child: Text(AppLocalizations.of(context)!.add),
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
        title: Text(AppLocalizations.of(context)!.editContactTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.firstName),
            ),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.lastName),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.email),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
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
            child: Text(AppLocalizations.of(context)!.save),
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
          title: Text(AppLocalizations.of(context)!.addContactToWorkshopTitle(contact.fullName)),
          content: plannedWorkshops.isEmpty
              ? Text(AppLocalizations.of(context)!.noPlannedWorkshops)
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
              child: Text(AppLocalizations.of(context)!.cancel),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.contactAddedToWorkshop(contact.fullName, workshop.title))),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToAddParticipant)),
        );
      }
    }
  }
}

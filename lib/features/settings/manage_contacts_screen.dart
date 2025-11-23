import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/invitation_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:plop/features/contacts/widgets/add_contact_dialog.dart';
import 'package:plop/features/contacts/widgets/invitation_dialog.dart';
import 'package:plop/features/settings/advanced_contact_settings_screen.dart';
import 'package:plop/l10n/app_localizations.dart';

class ManageContactsScreen extends StatefulWidget {
  const ManageContactsScreen({super.key});

  @override
  ManageContactsScreenState createState() => ManageContactsScreenState();
}

class ManageContactsScreenState extends State<ManageContactsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final InvitationService _invitationService = InvitationService();
  final UserService _userService = UserService();
  List<Contact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    setState(() => _isLoading = true);
    await _userService.init();
    await _loadContacts();
    setState(() => _isLoading = false);
  }

  Future<void> _loadContacts() async {
    _contacts = await _databaseService.getAllContactsOrdered();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleMute(Contact contact) async {
    contact.isMuted = !(contact.isMuted ?? false);
    await _databaseService.contactsBox.put(contact.key, contact);
    setState(() {});
  }

  Future<void> _toggleHidden(Contact contact) async {
    contact.isHidden = !(contact.isHidden ?? false);
    await _databaseService.contactsBox.put(contact.key, contact);
    setState(() {});
  }

  void _reorderContacts(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final Contact item = _contacts.removeAt(oldIndex);
      _contacts.insert(newIndex, item);
      final List<String> orderedIds = _contacts.map((c) => c.userId).toList();
      _databaseService.settingsBox.put('contactOrder', orderedIds);
    });
  }

  void _openAdvancedSettings(Contact contact) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                AdvancedContactSettingsScreen(contactKey: contact.key),
          ),
        )
        .then((_) => _loadContacts());
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AddContactDialog(
          myUserId: _userService.userId!, myPseudo: _userService.username!),
    ).then((_) => _loadContacts());
  }

  void _generateInvitation() async {
    final invitationData = await _invitationService.createInvitationCode(
        _userService.userId!, _userService.username!);
    if (!mounted) return;
    if (invitationData != null) {
      showDialog(
        context: context,
        builder: (context) => InvitationDialog(
          invitationCode: invitationData['code']!,
          validityMinutes: invitationData['validityMinutes']!,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneratingCode)));
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.startByAddingContactTitle, // AFTER
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.startByAddingContactSubtitle,
              // AFTER
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _generateInvitation,
              icon: const Icon(Icons.share),
              label: Text(AppLocalizations.of(context)!.shareMyCode),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _showAddContactDialog,
              icon: const Icon(Icons.group_add_outlined),
              label: Text(AppLocalizations.of(context)!.enterInvitationCode),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageContacts),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? _buildEmptyState()
              : ReorderableListView(
                  padding: const EdgeInsets.all(8.0),
                  header: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(AppLocalizations.of(context)!.reorderListHint),
                  ),
                  onReorder: _reorderContacts,
                  children: _contacts.map((contact) {
                    final bool hasCustomAlias = contact.alias.isNotEmpty &&
                        contact.alias != contact.originalPseudo;
                    final String primaryName =
                        hasCustomAlias ? contact.alias : contact.originalPseudo;
                    final String? secondaryName =
                        hasCustomAlias ? contact.originalPseudo : null;

                    return Card(
                      key: Key(contact.userId),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(contact.colorValue),
                          child: Text(primaryName.isNotEmpty
                              ? primaryName[0].toUpperCase()
                              : '?'),
                        ),
                        title: Text(primaryName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: secondaryName != null
                            ? Text("($secondaryName)",
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                  (contact.isMuted ?? false)
                                      ? Icons.volume_off
                                      : Icons.volume_up,
                                  color: Colors.grey),
                              onPressed: () => _toggleMute(contact),
                              tooltip:
                                  AppLocalizations.of(context)!.tooltipMuteContact,
                            ),
                            IconButton(
                              icon: Icon(
                                  (contact.isHidden ?? false)
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey),
                              onPressed: () => _toggleHidden(contact),
                              tooltip: AppLocalizations.of(context)!
                                  .tooltipHideContact,
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_note,
                                  color: Theme.of(context).primaryColor),
                              onPressed: () => _openAdvancedSettings(contact),
                              tooltip:
                                  AppLocalizations.of(context)!.advancedSettings,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
      floatingActionButton: _contacts.isNotEmpty
          ? SpeedDial(
              icon: Icons.menu,
              activeIcon: Icons.close,
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              visible: true,
              curve: Curves.bounceIn,
              children: [
                SpeedDialChild(
                  child: const Icon(Icons.share),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  label: AppLocalizations.of(context)!.inviteContact,
                  // Localized
                  onTap: _generateInvitation,
                ),
                SpeedDialChild(
                  child: const Icon(Icons.group_add),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  label: AppLocalizations.of(context)!.addViaCode,
                  // Localized
                  onTap: _showAddContactDialog,
                ),
              ],
            )
          : null,
    );
  }
}

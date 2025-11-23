import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/invitation_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:plop/core/services/websocket_service.dart';
// import 'package:plop/features/chat/chat_screen.dart';
import 'package:plop/features/contacts/widgets/add_contact_dialog.dart';
import 'package:plop/features/contacts/widgets/contact_tile.dart';
import 'package:plop/features/contacts/widgets/invitation_dialog.dart';
import 'package:plop/features/settings/manage_contacts_screen.dart';
import 'package:plop/features/settings/settings_screen.dart';
import 'package:plop/features/settings/sync_account_screen.dart';
import 'package:plop/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  ContactListScreenState createState() => ContactListScreenState();
}

class ContactListScreenState extends State<ContactListScreen> {
  late final DatabaseService _databaseService;
  late final InvitationService _invitationService;
  late final UserService _userService;
  late final WebSocketService _webSocketService;

  List<Contact> _contacts = [];
  bool _isLoading = true;
  bool _isGlobalMute = false;

  @override
  void initState() {
    super.initState();
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _invitationService = Provider.of<InvitationService>(context, listen: false);
    _userService = Provider.of<UserService>(context, listen: false);
    _webSocketService = Provider.of<WebSocketService>(context, listen: false);
    _loadDataAndSync();
  }

  @override
  void dispose() {
    // _webSocketService.disconnect();
    super.dispose();
  }

  Future<void> _loadDataAndSync() async {
    setState(() => _isLoading = true);
    await _userService.init();
    _isGlobalMute = _userService.isGlobalMute;
    if (_userService.userId != null && _userService.username != null) {
      _webSocketService.connect();
    }

    final localContacts = await _databaseService.getAllContactsOrdered();
    final bool wasUpdated =
        await _userService.syncContactsPseudos(localContacts);

    if (wasUpdated) {
      await _loadContacts();
    } else {
      _loadContacts(initialContacts: localContacts);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadContacts({List<Contact>? initialContacts}) async {
    final allContacts =
        initialContacts ?? await _databaseService.getAllContactsOrdered();
    setState(() {
      _contacts = allContacts
          .where((c) => !(c.isBlocked ?? false) && !(c.isHidden ?? false))
          .toList();
    });
  }

  void _showAddContactDialog() {
    if (_userService.userId == null || _userService.username == null) return;
    showDialog(
      context: context,
      builder: (context) => AddContactDialog(
          myUserId: _userService.userId!, myPseudo: _userService.username!),
    ).then((_) => _loadContacts());
  }

  void _generateInvitation() async {
    if (_userService.userId == null || _userService.username == null) return;
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

  void _toggleGlobalMute() async {
    await _userService.toggleGlobalMute();
    setState(() => _isGlobalMute = _userService.isGlobalMute);
  }

  void _onMenuSelection(String value) {
    if (value == 'sync') {
      // NOUVEAU
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => SyncAccountScreen()))
          .then((_) => _loadDataAndSync());
    } else if (value == 'settings') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => SettingsScreen()))
          .then((_) => _loadDataAndSync());
    }
  }

  // void _navigateToChatScreen(Contact contact) {
  //   Navigator.of(context)
  //       .push(
  //     MaterialPageRoute(
  //       builder: (context) => ChatScreen(contact: contact),
  //     ),
  //   )
  //       .then((_) => _loadContacts());
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appName),
        actions: [
          IconButton(
            icon: Icon(_isGlobalMute ? Icons.volume_off : Icons.volume_up,
                color: _isGlobalMute ? Colors.red : Colors.grey.shade900),
            onPressed: _toggleGlobalMute,
            tooltip: AppLocalizations.of(context)!.tooltipGlobalMute,
          ),
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (context) => ManageContactsScreen()))
                  .then((_) => _loadDataAndSync());
            },
            tooltip: AppLocalizations.of(context)!.manageContacts,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _onMenuSelection,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: "settings",
                child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings' /*AppLocalizations.of(context)!.settings*/)),
              ),
              const PopupMenuItem<String>(
                // NOUVEAU
                value: 'sync',
                child: ListTile(
                    leading: Icon(Icons.sync),
                    title: Text('Sync' /*AppLocalizations.of(context)!.syncTitle*/)),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDataAndSync,
              child: _contacts.isEmpty
                  ? Center(
                      child: Text(AppLocalizations.of(context)!.noContactsYet))
                  : Padding(
                      padding: const EdgeInsets.all(1.0),
                      // Add some padding around the wrap
                      child: LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          final double screenWidth = constraints.maxWidth;
                          // You can adjust these values based on your desired minimum/maximum tile width
                          final double tileWidth = screenWidth < 500.0
                              ? screenWidth
                              : (screenWidth * 0.95) /
                                  (screenWidth * 0.95 / 500)
                                      .round(); // Minimum width for a contact tile

                          return Wrap(
                            spacing: 1.0,
                            // horizontal spacing between items
                            runSpacing: 1.0,
                            // vertical spacing between lines
                            alignment: WrapAlignment.spaceAround,
                            // Align items in the center
                            children: _contacts.map((contact) {
                              return SizedBox(
                                width:
                                    tileWidth, // Set the calculated width for each tile
                                height:
                                    110, // Set the calculated width for each tile
                                child: ContactTile(
                                  contact: contact,
                                  onTap: () {} // () => _navigateToChatScreen(contact),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
            ),
      floatingActionButton: SpeedDial(
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
            shape: const CircleBorder(),
            onTap: _generateInvitation,
          ),
          SpeedDialChild(
            child: const Icon(Icons.group_add),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            label: AppLocalizations.of(context)!.addByCode,
            shape: const CircleBorder(),
            onTap: _showAddContactDialog,
          ),
        ],
      ),
    );
  }
}

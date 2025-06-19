import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/models/message_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/locale_provider.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:plop/features/setup/setup_screen.dart';
import 'package:plop/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Services et contrôleurs
  final DatabaseService _databaseService = DatabaseService();
  final UserService _userService = UserService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final Uuid _uuid = Uuid();
  Locale? _selectedLocale;
  bool _isLocaleInitialized = false;

  // State
  late List<MessageModel> _messages;
  // List<Contact> _contacts = [];
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedLocale = Provider.of<LocaleProvider>(context, listen: false).locale;
        });
      }
    });
    _loadAllData();
  }
  void _saveLocale() {
    Provider.of<LocaleProvider>(context, listen: false).setLocale(_selectedLocale);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.languageUpdated)),
    );
  }
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await _userService.init();
    _messages = _databaseService.getAllMessages();
    // _contacts = await _databaseService.getAllContactsOrdered();
    _usernameController.text = _userService.username ?? '';
    _userId = _userService.userId;
    setState(() => _isLoading = false);
  }

  void _addMessage() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty && _messages.length < 10) {
      final newMessage = MessageModel(id: _uuid.v4(), text: text);
      await _databaseService.addMessage(newMessage);
      _messageController.clear();
      setState(() {
        _messages = _databaseService.getAllMessages();
      });
    } else if (_messages.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.maxTenMessages)),
      );
    }
  }

  void _deleteMessage(String id) async {
    await _databaseService.deleteMessage(id);
    setState(() {
      _messages = _databaseService.getAllMessages();
    });
  }

  void _saveUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isNotEmpty && newUsername != _userService.username) {
      await _userService.updateUsername(newUsername);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pseudo mis à jour !')),
      );
      FocusScope.of(context).unfocus(); // Ferme le clavier
    }
  }

  // void _reorderContacts(int oldIndex, int newIndex) {
  //   setState(() {
  //     if (newIndex > oldIndex) {
  //       newIndex -= 1;
  //     }
  //     final Contact item = _contacts.removeAt(oldIndex);
  //     _contacts.insert(newIndex, item);
  //
  //     final List<String> orderedIds = _contacts.map((c) => c.userId).toList();
  //     _databaseService.saveContactOrder(orderedIds);
  //   });
  // }
  String _getLanguageName(BuildContext context, String code) {
    switch (code) {
      case 'fr': return AppLocalizations.of(context)!.french;
      case 'en': return AppLocalizations.of(context)!.english;
      case 'de': return AppLocalizations.of(context)!.german;
      case 'es': return AppLocalizations.of(context)!.spanish;
      case 'it': return AppLocalizations.of(context)!.italian;
      default: return code;
    }
  }
  // Future<void> _deleteContact(String userId) async {
  //   final bool? confirm = await showDialog<bool>(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //             title: Text(AppLocalizations.of(context)!.deleteThisContact),
  //             content: Text(AppLocalizations.of(context)!.actionIsPermanent),
  //             actions: [
  //               TextButton(
  //                   onPressed: () => Navigator.of(context).pop(false),
  //                   child: Text(AppLocalizations.of(context)!.cancel)),
  //               TextButton(
  //                 onPressed: () => Navigator.of(context).pop(true),
  //                 child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red)),
  //               ),
  //             ],
  //           ));
  //
  //   if (confirm == true) {
  //     await _databaseService.deleteContact(userId);
  //     await _loadAllData(); // Recharger les données pour mettre à jour l'UI
  //   }
  // }

  Future<void> _resetApp() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.resetApp),
          content: Text(AppLocalizations.of(context)!.resetWarning),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocalizations.of(context)!.cancel)),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('RÉINITIALISER', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // CORRECTION: On vide les données au lieu de supprimer les fichiers.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final db = DatabaseService();
      await db.contactsBox.clear();
      await db.messagesBox.clear();
      await db.saveContactOrder([]);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => SetupScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  // void _openAdvancedSettings(Contact contact) {
  //   Navigator.of(context).push(
  //     MaterialPageRoute(
  //       builder: (context) => AdvancedContactSettingsScreen(contactKey: contact.key),
  //     ),
  //   ).then((_) => _loadAllData()); // Recharge les données au retour
  // }
  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context); if (!_isLocaleInitialized) {
      _selectedLocale = localeProvider.locale;
      _isLocaleInitialized = true;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Section Compte Utilisateur ---
                  Text(AppLocalizations.of(context)!.myAccount,
                      style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 10),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.myUsername,
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.save_alt),
                        onPressed: _saveUsername,
                        tooltip: AppLocalizations.of(context)!.saveUsername,
                      ),
                    ),
                    maxLength: 20,
                  ),
                  SizedBox(height: 10),
                  if (_userId != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Mon User ID (pour le débogage)'),
                      subtitle: Text(_userId!),
                      trailing: IconButton(
                        icon: Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _userId!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.userIdCopied)),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 10),
                  if (_userId != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('WS server'),
                      subtitle: Text(dotenv.env['WEBSOCKET_URL']!),

                    ),
                  SizedBox(height: 10),
                  if (_userId != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('HTTP Server'),
                      subtitle: Text(dotenv.env['BASE_URL']!),

                    ),

                 Divider(height: 40),

// --- Section Langue ---
                  Text(AppLocalizations.of(context)!.language, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Locale?>(
                          value: _selectedLocale,
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(AppLocalizations.of(context)!.systemLanguage),
                            ),
                            ...AppLocalizations.supportedLocales.map((locale) {
                              final flag = {'en': '🇬🇧', 'fr': '🇫🇷', 'de': '🇩🇪', 'es': '🇪🇸', 'it': '🇮🇹'}[locale.languageCode];
                              return DropdownMenuItem(
                                value: locale,
                                child: Row(
                                  children: [
                                    Text(flag ?? ''),
                                    const SizedBox(width: 8),
                                    Text(_getLanguageName(context, locale.languageCode)),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (locale) {
                            setState(() {
                              _selectedLocale = locale;
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: (_selectedLocale != localeProvider.locale) ? _saveLocale : null,
                        tooltip: AppLocalizations.of(context)!.save,
                        color: Theme.of(context).primaryColor,
                      )
                    ],
                  ),


                  Divider(height: 40),
                  // --- Section Messages Rapides ---
                  Text(AppLocalizations.of(context)!.quickMessages,
                      style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 10),
                  TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.addNewQuickMessage,
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add_circle),
                        onPressed: _addMessage,
                        tooltip: AppLocalizations.of(context)!.add,
                      ),
                    ),
                    maxLength: 20,
                    inputFormatters: [LengthLimitingTextInputFormatter(20)],
                  ),
                  SizedBox(height: 10),
                  Text(AppLocalizations.of(context)!.yourMessages(_messages.length),
                      style: Theme.of(context).textTheme.titleMedium),
                  Divider(),
                  ..._messages.map((message) => ListTile(
                        title: Text(message.text),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteMessage(message.id),
                          tooltip: AppLocalizations.of(context)!.delete,
                        ),
                      )),
                  if (_messages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(child: Text(AppLocalizations.of(context)!.noMessagesConfigured)),
                    ),

                  Divider(height: 40),

                  // --- Section Réinitialisation ---
                  TextButton(
                    onPressed: _resetApp,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber_rounded),
                        SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.resetApp),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

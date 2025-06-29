import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plop/core/models/message_model.dart';
import 'package:plop/core/services/backup_service.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/sync_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:plop/features/contacts/contact_list_screen.dart';
import 'package:plop/features/setup/import_account_screen.dart';
import 'package:plop/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
// NEW: Import the path package

class SyncAccountScreen extends StatefulWidget {
  const SyncAccountScreen({super.key});

  @override
  _SyncAccountScreenState createState() => _SyncAccountScreenState();
}

class _SyncAccountScreenState extends State<SyncAccountScreen> {
  final SyncService _syncService = SyncService();
  final UserService _userService = UserService();
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final BackupService _backupService = BackupService(); // AJOUT
  String? _generatedCode;
  bool _isLoadingExport = false;
  final String _backupFileName = 'plop_config_backup.json';

  @override
  void initState() {
    super.initState();
    _userService.init();
  }

  Future<void> _generateCode() async {
    setState(() => _isLoadingExport = true);
    final code = await _syncService.createSyncCode(_userService.userId!);
    setState(() {
      _generatedCode = code;
      _isLoadingExport = false;
    });
  }

  Future<void> _clearDataAndNavigateToImport() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmImportTitle),
          content: Text(AppLocalizations.of(context)!.confirmImportBody),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel)),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocalizations.of(context)!.import,
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    debugPrint("[SyncScreen] Réinitialisation des données locales...");
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final db = DatabaseService();
    await db.contactsBox.clear();
    await db.messagesBox.clear();
    await db.saveContactOrder([]);

    debugPrint("[SyncScreen] Données locales réinitialisées.");

    if (!mounted) return;

    // CORRECTION: Utilise `pushAndRemoveUntil` pour une navigation propre après la réinitialisation.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const ImportAccountScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // NOUVELLE MÉTHODE DE CONTRÔLE POUR LA SAUVEGARDE
  Future<void> _handleSaveBackup() async {
    final result = await _backupService.saveBackup(
      userService: _userService,
      databaseService: _databaseService,
      saveToUserSelectedLocation: true,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result ??
                AppLocalizations.of(context)!.configurationSavedSuccessfully)),
      );
    }
  }

  // NOUVELLE MÉTHODE DE CONTRÔLE POUR LA RESTAURATION
  Future<void> _handleRestoreBackup() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.loadConfiguration),
        content: Text(AppLocalizations.of(context)!.loadConfigurationWarning),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocalizations.of(context)!.load,
                  style: const TextStyle(color: Colors.orange))),
        ],
      ),
    );

    if (confirm != true) return;

    final String? errorMessage = await _backupService.restoreFromBackup();

    // La logique de l'interface réagit au résultat
    if (mounted) {
      if (errorMessage == null) {
        await _loadAllData();
        // Succès : naviguer vers l'écran principal
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ContactListScreen()),
          (route) => false,
        );
      } else {
        // Échec : afficher le message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }

    // S'assurer que l'indicateur de chargement est toujours enlevé
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  late List<MessageModel> _messages;

  // List<Contact> _contacts = [];
  String? _userId;
  bool _isLoading = true;

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await _userService.init();
    _messages = _databaseService.getAllMessages();
    // _contacts = await _databaseService.getAllContactsOrdered();
    _usernameController.text = _userService.username ?? '';
    _userId = _userService.userId;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.syncTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Section Exporter ---
            Text(AppLocalizations.of(context)!.exportAccountTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.exportAccountBody),
            const SizedBox(height: 16),
            if (_generatedCode != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SelectableText(_generatedCode!,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2)),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: _generatedCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text(AppLocalizations.of(context)!.codeCopied)));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () {
                          SharePlus.instance.share(ShareParams(
                              text:
                              AppLocalizations.of(context)!.syncCodeShareText(_generatedCode!)));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _isLoadingExport
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _generateCode,
                    icon: const Icon(Icons.screen_share_outlined),
                    label:
                        Text(AppLocalizations.of(context)!.generateExportCode),
                  ),

            const Divider(height: 40),

            // --- Section Importer ---
            Text(AppLocalizations.of(context)!.importAccountTitle2,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.importWarning),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _clearDataAndNavigateToImport,
              icon: const Icon(Icons.download),
              label: Text(AppLocalizations.of(context)!.importAccountButtonLabel),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            Divider(height: 40),
            // CHANGED: UI texts updated to reflect new behavior
            Text(AppLocalizations.of(context)!.backupAndRestore,
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.save_alt),
              title: Text(AppLocalizations.of(context)!.saveConfiguration),
              subtitle: Text(AppLocalizations.of(context)!
                  .saveConfigurationDescriptionLocal),
              // e.g., "Saves a local backup. Overwrites previous backup."
              onTap: _handleSaveBackup,
            ),
            ListTile(
              leading: Icon(Icons.settings_backup_restore),
              title: Text(AppLocalizations.of(context)!.loadConfiguration),
              subtitle: Text(AppLocalizations.of(context)!
                  .loadConfigurationDescriptionLocal),
              // e.g., "Restores configuration from the local backup."
              onTap: _handleRestoreBackup,
            ),

            Divider(height: 40),
          ],
        ),
      ),
    );
  }
}

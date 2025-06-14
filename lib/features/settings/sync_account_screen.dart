import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/sync_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:plop/features/setup/import_account_screen.dart';
import 'package:plop/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncAccountScreen extends StatefulWidget {
  const SyncAccountScreen({Key? key}) : super(key: key);

  @override
  _SyncAccountScreenState createState() => _SyncAccountScreenState();
}

class _SyncAccountScreenState extends State<SyncAccountScreen> {
  final SyncService _syncService = SyncService();
  final UserService _userService = UserService();
  String? _generatedCode;
  bool _isLoadingExport = false;

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
          title:  Text(AppLocalizations.of(context)!.confirmImportTitle),
          content:  Text(AppLocalizations.of(context)!.confirmImportBody),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocalizations.of(context)!.cancel)),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocalizations.of(context)!.import, style: TextStyle(color: Colors.red)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  Text(AppLocalizations.of(context)!.syncTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Section Exporter ---
            Text(AppLocalizations.of(context)!.exportAccountTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                      SelectableText(_generatedCode!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _generatedCode!));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copié !')));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () {
                          SharePlus.instance.share(ShareParams(text: 'Mon code de synchronisation Plop est : $_generatedCode'));
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
              label: Text(AppLocalizations.of(context)!.generateExportCode),
            ),

            const Divider(height: 40),

            // --- Section Importer ---
            Text(AppLocalizations.of(context)!.importAccountTitle2, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
             Text(AppLocalizations.of(context)!.importWarning),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _clearDataAndNavigateToImport,
              icon: const Icon(Icons.download),
              label: const Text('Importer un compte'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
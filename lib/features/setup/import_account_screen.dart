import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plop/core/services/sync_service.dart';
import 'package:plop/features/contacts/contact_list_screen.dart';
import 'package:plop/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImportAccountScreen extends StatefulWidget {
  const ImportAccountScreen({super.key});

  @override
  ImportAccountScreenState createState() => ImportAccountScreenState();
}

class ImportAccountScreenState extends State<ImportAccountScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _importAccount() async {
    final syncService = Provider.of<SyncService>(context, listen: false);
    if (_codeController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseEnterSyncCode)),
      );
      return;
    }
    setState(() => _isLoading = true);
    final syncData =
        await syncService.useSyncCode(_codeController.text.trim());
    if (!mounted) return;
    if (syncData != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', syncData['userId']!);
      if (!mounted) return;
      if (syncData['pseudo'] != null && syncData['pseudo']!.isNotEmpty) {
        await prefs.setString('username', syncData['pseudo']!);
      } else {
        await prefs.setString('username', AppLocalizations.of(context)!.defaultImportedUsername);
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ContactListScreen()),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.invalidOrExpiredCode)),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.importAccountTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.download_for_offline_outlined,
                    size: 80, color: Theme.of(context).primaryColor),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.syncYourAccount,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.importAccountBody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.syncCode,
                    border: const OutlineInputBorder(),
                  ),
                  maxLength: 20,
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _importAccount,
                        icon: const Icon(Icons.sync),
                        label: Text(AppLocalizations.of(context)!.import),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

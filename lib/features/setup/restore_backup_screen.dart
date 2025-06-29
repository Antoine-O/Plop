// features/setup/restore_backup_screen.dart

import 'package:flutter/material.dart';
import 'package:plop/core/services/backup_service.dart'; // AJOUT : Importer le nouveau service
import 'package:plop/features/contacts/contact_list_screen.dart';
import 'package:plop/l10n/app_localizations.dart';
// Les autres imports (file_picker, dart:io, etc.) ne sont plus nécessaires ici.

class RestoreBackupScreen extends StatefulWidget {
  const RestoreBackupScreen({super.key});

  @override
  State<RestoreBackupScreen> createState() => _RestoreBackupScreenState();
}

class _RestoreBackupScreenState extends State<RestoreBackupScreen> {
  // AJOUT : Instancier le service
  final BackupService _backupService = BackupService();
  bool _isLoading = false;

  // MODIFICATION : La fonction est maintenant un "contrôleur" qui appelle la logique métier.

  // MODIFICATION : La fonction est maintenant un "contrôleur" qui appelle la logique métier.
  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);

    // Appel de la logique métier extraite dans le service
    final String? errorMessage = await _backupService.restoreFromBackup();

    // La logique de l'interface réagit au résultat
    if (mounted) {
      if (errorMessage == null) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(AppLocalizations.of(context)!.restoreFromBackup)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.settings_backup_restore,
                    size: 80, color: Theme.of(context).primaryColor),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.restoreYourAccount,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.restoreBackupBody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        // MODIFICATION : Appelle la nouvelle fonction de "contrôle"
                        onPressed: _handleRestore,
                        icon: const Icon(Icons.folder_open),
                        label: Text(
                            AppLocalizations.of(context)!.selectBackupFile),
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

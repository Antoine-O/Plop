import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:plop/core/services/backup_service.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/features/contacts/contact_list_screen.dart';
import 'package:plop/l10n/app_localizations.dart';

class RestoreBackupScreen extends StatefulWidget {
  const RestoreBackupScreen({super.key});

  @override
  State<RestoreBackupScreen> createState() => _RestoreBackupScreenState();
}

class _RestoreBackupScreenState extends State<RestoreBackupScreen> {
  late final BackupService _backupService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _backupService = BackupService(DatabaseService());
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.cancel),
          ),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    final jsonString = utf8.decode(result.files.single.bytes!);
    await _backupService.importBackup(jsonString);

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ContactListScreen()),
        (route) => false,
      );
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

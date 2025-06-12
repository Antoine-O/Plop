import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:plop_app/core/models/contact_model.dart';
import 'package:plop_app/core/services/database_service.dart';
import 'package:plop_app/l10n/app_localizations.dart';

class AdvancedContactSettingsScreen extends StatefulWidget {
  final dynamic contactKey;

  const AdvancedContactSettingsScreen({Key? key, required this.contactKey})
      : super(key: key);

  @override
  _AdvancedContactSettingsScreenState createState() =>
      _AdvancedContactSettingsScreenState();
}

class _AdvancedContactSettingsScreenState
    extends State<AdvancedContactSettingsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _aliasController = TextEditingController();
  final _overrideController = TextEditingController();
  late Contact _contact;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  Future<void> _loadContact() async {
    setState(() => _isLoading = true);
    _contact = _dbService.contactsBox.get(widget.contactKey)!;
    _aliasController.text = _contact.alias;
    _overrideController.text = _contact.defaultMessageOverride ?? '';
    setState(() => _isLoading = false);
  }

  Future<void> _pickSound() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      setState(() {
        _contact.customSoundPath = result.files.single.path;
      });
    }
  }

  Future<void> _saveSettings() async {
    _contact.alias = _aliasController.text.trim();
    _contact.defaultMessageOverride = _overrideController.text.trim();
    await _contact.save();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.settingsSaved)));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.advancedSettings),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: AppLocalizations.of(context)!.save,
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                TextField(
                  controller: _aliasController,
                  decoration: InputDecoration(
                      labelText: 'Nom du contact (alias)',
                      border: OutlineInputBorder()),
                  maxLength: 20,
                ),
                SizedBox(height: 20),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.ignoreNotifications),
                  subtitle: Text(AppLocalizations.of(context)!.muteThisContact),
                  value: _contact.isMuted ?? false, // CORRECTION
                  onChanged: (bool value) {
                    setState(() => _contact.isMuted = value);
                  },
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.hideThisContact),
                  subtitle:
                      Text(AppLocalizations.of(context)!.doNotSeeInList),
                  value: _contact.isHidden ?? false,
                  onChanged: (bool value) {
                    setState(() => _contact.isHidden = value);
                  },
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.blockThisContact),
                  subtitle: Text(AppLocalizations.of(context)!.doNotSeeInList),
                  value: _contact.isBlocked ?? false, // CORRECTION
                  onChanged: (bool value) {
                    setState(() => _contact.isBlocked = value);
                  },
                ),
                SizedBox(height: 20),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.notificationSound),
                  subtitle: Text(_contact.customSoundPath ?? AppLocalizations.of(context)!.defaultSound),
                  trailing: Icon(Icons.audiotrack),
                  onTap: _pickSound,
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _overrideController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.overrideDefaultMessage,
                    hintText: AppLocalizations.of(context)!.exampleNewPlop,
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 20,
                ),
              ],
            ),
    );
  }
}

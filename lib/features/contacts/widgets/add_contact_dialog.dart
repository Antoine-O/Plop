import 'package:flutter/material.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/invitation_service.dart';
import 'package:plop/l10n/app_localizations.dart';

class AddContactDialog extends StatefulWidget {
  final String myUserId;
  final String myPseudo;

  const AddContactDialog({Key? key, required this.myUserId, required this.myPseudo}) : super(key: key);
  @override
  _AddContactDialogState createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _codeController = TextEditingController();
  final _aliasController = TextEditingController();
  final _dbService = DatabaseService();
  final _invitationService = InvitationService();
  Color _selectedColor = Colors.blue;
  bool _isLoading = false;

  void _addContact() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterCode)));
      return;
    }

    setState(() => _isLoading = true);
    final serverResponse = await _invitationService.useInvitationCode(code, widget.myUserId, widget.myPseudo);
    setState(() => _isLoading = false);

    if (serverResponse != null) {
      final String alias = _aliasController.text.trim();
      final newContact = Contact(
        userId: serverResponse['userId']!,
        originalPseudo: serverResponse['pseudo']!,
        // Si l'alias est vide, on utilise le pseudo du contact
        alias: alias.isNotEmpty ? alias : serverResponse['pseudo']!,
        colorValue: _selectedColor.value,
      );
      await _dbService.addContact(newContact);
      if (mounted) Navigator.of(context).pop();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.invalidOrExpiredCode)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.addContact),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _codeController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.invitationCode),maxLength: 20,),
          TextField(controller: _aliasController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.contactNameOptional),maxLength: 20,),
          SizedBox(height: 20),
          Text(AppLocalizations.of(context)!.chooseAColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple].map((color) => GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: CircleAvatar(
                backgroundColor: color,
                child: _selectedColor == color ? Icon(Icons.check, color: Colors.white) : null,
              ),
            )).toList(),
          )
        ],
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.of(context).pop(), child: Text(AppLocalizations.of(context)!.cancel)),
        ElevatedButton(
          onPressed: _isLoading ? null : _addContact,
          child: _isLoading ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : Text(AppLocalizations.of(context)!.add),
        ),
      ],
    );
  }
}
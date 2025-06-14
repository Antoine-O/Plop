import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:plop/l10n/app_localizations.dart';

class InvitationDialog extends StatelessWidget {
  final String invitationCode;
  final int validityMinutes;

  const InvitationDialog({
    super.key,
    required this.invitationCode,
    required this.validityMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final shareText = 'Mon code d\'invitation Plop est : $invitationCode';

    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.invitationDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.invitationDialogBody(validityMinutes),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              invitationCode,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: invitationCode));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.codeCopied)));
          },
          child: Text(AppLocalizations.of(context)!.copy),
        ),
        ElevatedButton(
          onPressed: () => SharePlus.instance.share(ShareParams(text: shareText)),
          child: Text(AppLocalizations.of(context)!.share),
        ),
      ],
    );
  }
}
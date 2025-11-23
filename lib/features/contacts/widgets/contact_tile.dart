import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/services/database_service.dart';

class ContactTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;

  const ContactTile({
    super.key,
    required this.contact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    return ListTile(
      leading: CircleAvatar(
        child: Text(contact.alias.isNotEmpty ? contact.alias[0] : '?'),
      ),
      title: Text(contact.alias),
      subtitle: FutureBuilder<Contact?>(
        future: databaseService.getContact(contact.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('Loading...');
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            return Text(snapshot.data!.originalPseudo);
          } else {
            return const Text('Unknown');
          }
        },
      ),
      onTap: onTap,
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plop/core/config/app_config.dart';
import 'package:flutter/foundation.dart';

class UserService {
  late SharedPreferences _prefs;
  final String _baseUrl = AppConfig.baseUrl;
  static const String _globalMuteKey = 'globalMute';

  String? userId;
  String? username;
  bool isGlobalMute = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    userId = _prefs.getString('userId');
    username = _prefs.getString('username');
    isGlobalMute = _prefs.getBool(_globalMuteKey) ?? false;
  }

  bool hasUser() => userId != null && username != null;

  Future<bool> createUser(String newUsername) async {
    debugPrint('Appel de l\'URL : |$_baseUrl/users/generate-id|');
    try {
      final response = await http.get(Uri.parse('$_baseUrl/users/generate-id'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        userId = data['userId'];
        username = newUsername;
        await _prefs.setString('userId', userId!);
        await _prefs.setString('username', username!);
        return true;
      }
    } catch (e) {
      debugPrint('Erreur createUser: $e');
    }
    return false;
  }

  Future<void> updateUsername(String newUsername) async {
    username = newUsername;
    await _prefs.setString('username', username!);
  }

  Future<void> toggleGlobalMute() async {
    isGlobalMute = !isGlobalMute;
    await _prefs.setBool(_globalMuteKey, isGlobalMute);
  }

  Future<bool> syncContactsPseudos(List<Contact> localContacts) async {
    if (localContacts.isEmpty) return false;
    bool hasBeenUpdated = false;
    try {
      final userIds = localContacts.map((c) => c.userId).toList();
      final response = await http.post(
        Uri.parse('$_baseUrl/users/get-pseudos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userIds': userIds}),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> remotePseudos = jsonDecode(response.body);
        final db = DatabaseService();
        for (var contact in localContacts) {
          if (remotePseudos.containsKey(contact.userId) &&
              contact.originalPseudo != remotePseudos[contact.userId]) {
            contact.originalPseudo = remotePseudos[contact.userId]!;
            await db.updateContact(contact);
            hasBeenUpdated = true;
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur syncContactsPseudos: $e');
    }
    return hasBeenUpdated;
  }
}
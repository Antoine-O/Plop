import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:plop/core/config/app_config.dart';
import 'package:flutter/foundation.dart';

class InvitationService {
  final String _baseUrl = AppConfig.baseUrl;

  Future<Map<String, dynamic>?> createInvitationCode(String userId, String userPseudo) async {
    try {
      // On envoie maintenant le pseudo pour que le serveur le stocke avec l'invitation
      final response = await http.get(Uri.parse('$_baseUrl/invitations/create?userId=$userId&pseudo=$userPseudo'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'code': data['code'] as String,
          'validityMinutes': data['validityMinutes'] as int,
        };
      }
    } catch (e) {
      debugPrint('Erreur lors de la création du code d\'invitation: $e');
    }
    return null;
  }

  Future<Map<String, String>?> useInvitationCode(String code, String myUserId, String myPseudo) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/invitations/use'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'userId': myUserId, // On envoie nos infos
          'pseudo': myPseudo, // pour que l'autre nous ajoute
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'userId': data['userId'] as String,
          'pseudo': data['pseudo'] as String,
        };
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'utilisation du code d\'invitation: $e');
    }
    return null;
  }
}
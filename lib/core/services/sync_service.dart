import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:plop/core/config/app_config.dart';

class SyncService {
  final String _baseUrl = AppConfig.baseUrl;

  Future<String?> createSyncCode(String userId) async {
    try {
      final url = Uri.parse('$_baseUrl/sync/create?userId=$userId');
      debugPrint("[SyncService] Création du code via: $url");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final code = jsonDecode(response.body)['code'];
        debugPrint("[SyncService] Code reçu: $code");
        return code;
      } else {
        debugPrint("[SyncService] Erreur createSyncCode, statut: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('[SyncService] Exception createSyncCode: $e');
    }
    return null;
  }

  Future<Map<String, String>?> useSyncCode(String code) async {
    try {
      final url = Uri.parse('$_baseUrl/sync/use');
      final body = jsonEncode({'code': code});
      debugPrint("[SyncService] Utilisation du code via: $url avec body: $body");
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("[SyncService] Données de synchro reçues: $data");
        return {
          'userId': data['userId'] as String,
          'pseudo': data['pseudo'] as String,
        };
      } else {
        debugPrint("[SyncService] Erreur useSyncCode, statut: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('[SyncService] Exception useSyncCode: $e');
    }
    return null;
  }
}
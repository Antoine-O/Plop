import 'dart:convert';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:http/http.dart' as http;
import 'package:plop/core/config/app_config.dart';
import 'package:plop/core/services/websocket_service.dart';

class SyncService {
  final String _baseUrl = AppConfig.baseUrl;

  Future<String?> createSyncCode(String userId,
      {http.Client? client, WebSocketService? webSocketService}) async {
    final client0 = client ?? http.Client();
    final webSocketService0 = webSocketService ?? WebSocketService();
    debugPrint(
        "[SyncService] createSyncCode: Attempting to create sync code for userId: $userId");
    try {
      debugPrint(
          "[SyncService] createSyncCode: Ensuring WebSocket is connected.");
      webSocketService0
          .ensureConnected(); // Assuming this is synchronous or you don't need to await its completion before HTTP
      debugPrint(
          "[SyncService] createSyncCode: WebSocket connection check complete.");

      final url = Uri.parse('$_baseUrl/sync/create?userId=$userId');
      debugPrint("[SyncService] createSyncCode: Requesting URL: $url");

      final response = await client0.get(url);
      debugPrint(
          "[SyncService] createSyncCode: Response status code: ${response.statusCode}");
      debugPrint(
          "[SyncService] createSyncCode: Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final code = responseData['code'] as String?;
        if (code != null) {
          debugPrint(
              "[SyncService] createSyncCode: Sync code successfully received: $code");
          return code;
        } else {
          debugPrint(
              "[SyncService] createSyncCode: 'code' field is null or missing in response.");
          return null;
        }
      } else {
        debugPrint(
            "[SyncService] createSyncCode: Error creating sync code, status: ${response.statusCode}, body: ${response.body}");
      }
    } catch (e, stackTrace) {
      debugPrint('[SyncService] createSyncCode: Exception occurred: $e');
      debugPrintStack(
          stackTrace: stackTrace,
          label: '[SyncService] createSyncCode Exception');
    }
    debugPrint(
        "[SyncService] createSyncCode: Failed to create sync code, returning null.");
    return null;
  }

  Future<Map<String, String>?> useSyncCode(String code,
      {http.Client? client, WebSocketService? webSocketService}) async {
    final client0 = client ?? http.Client();
    final webSocketService0 = webSocketService ?? WebSocketService();
    debugPrint("[SyncService] useSyncCode: Attempting to use sync code: $code");
    try {
      debugPrint("[SyncService] useSyncCode: Ensuring WebSocket is connected.");
      webSocketService0.ensureConnected(); // Assuming this is synchronous
      debugPrint(
          "[SyncService] useSyncCode: WebSocket connection check complete.");

      final url = Uri.parse('$_baseUrl/sync/use');
      final body = jsonEncode({'code': code});
      debugPrint(
          "[SyncService] useSyncCode: Requesting URL: $url with body: $body");

      final response = await client0.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      debugPrint(
          "[SyncService] useSyncCode: Response status code: ${response.statusCode}");
      debugPrint("[SyncService] useSyncCode: Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint(
            "[SyncService] useSyncCode: Sync data successfully received: $data");

        final userId = data['userId'] as String?;
        final pseudo = data['pseudo'] as String?;

        if (userId != null && pseudo != null) {
          final result = {'userId': userId, 'pseudo': pseudo};
          debugPrint("[SyncService] useSyncCode: Parsed sync data: $result");
          return result;
        } else {
          debugPrint(
              "[SyncService] useSyncCode: 'userId' or 'pseudo' is null or missing in response data.");
          return null;
        }
      } else {
        debugPrint(
            "[SyncService] useSyncCode: Error using sync code, status: ${response.statusCode}, body: ${response.body}");
      }
    } catch (e, stackTrace) {
      debugPrint('[SyncService] useSyncCode: Exception occurred: $e');
      debugPrintStack(
          stackTrace: stackTrace, label: '[SyncService] useSyncCode Exception');
    }
    debugPrint(
        "[SyncService] useSyncCode: Failed to use sync code, returning null.");
    return null;
  }
}

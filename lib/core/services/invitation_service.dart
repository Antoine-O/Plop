import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:plop/core/config/app_config.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

class InvitationService {
  final String _baseUrl = AppConfig.baseUrl;
  final http.Client _client;

  InvitationService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>?> createInvitationCode(
      String userId, String userPseudo) async {
    debugPrint(
        "[InvitationService] createInvitationCode: Attempting to create invitation code for userId: $userId, pseudo: $userPseudo");
    try {
      final url = Uri.parse(
          '$_baseUrl/invitations/create?userId=$userId&pseudo=$userPseudo');
      debugPrint(
          "[InvitationService] createInvitationCode: Requesting URL: $url");

      final response = await _client.get(url);
      debugPrint(
          "[InvitationService] createInvitationCode: Response status code: ${response.statusCode}");
      debugPrint(
          "[InvitationService] createInvitationCode: Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = {
          'code': data['code'] as String,
          'validityMinutes': data['validityMinutes'] as int,
        };
        debugPrint(
            "[InvitationService] createInvitationCode: Successfully created code. Result: $result");
        return result;
      } else {
        debugPrint(
            "[InvitationService] createInvitationCode: Failed to create code. Status: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      debugPrint(
          '[InvitationService] createInvitationCode: Error during creation: $e');
      debugPrintStack(
          stackTrace: stackTrace,
          label: '[InvitationService] createInvitationCode');
    }
    return null;
  }

  Future<Map<String, String>?> useInvitationCode(
      String code, String myUserId, String myPseudo) async {
    debugPrint(
        "[InvitationService] useInvitationCode: Attempting to use invitation code: $code for userId: $myUserId, pseudo: $myPseudo");
    try {
      final url = Uri.parse('$_baseUrl/invitations/use');
      final body = jsonEncode({
        'code': code,
        'userId': myUserId,
        'pseudo': myPseudo,
      });
      debugPrint("[InvitationService] useInvitationCode: Requesting URL: $url");
      debugPrint("[InvitationService] useInvitationCode: Request body: $body");

      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      debugPrint(
          "[InvitationService] useInvitationCode: Response status code: ${response.statusCode}");
      debugPrint(
          "[InvitationService] useInvitationCode: Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = {
          'userId': data['userId'] as String,
          'pseudo': data['pseudo'] as String,
        };
        debugPrint(
            "[InvitationService] useInvitationCode: Successfully used code. Result: $result");
        return result;
      } else {
        debugPrint(
            "[InvitationService] useInvitationCode: Failed to use code. Status: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      debugPrint('[InvitationService] useInvitationCode: Error during use: $e');
      debugPrintStack(
          stackTrace: stackTrace,
          label: '[InvitationService] useInvitationCode');
    }
    return null;
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plop/core/config/app_config.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

class UserService extends ChangeNotifier {
  late SharedPreferences _prefs;
  final String _baseUrl = AppConfig.baseUrl;
  static const String _globalMuteKey = 'globalMute';

  String? userId;
  String? username;
  bool isGlobalMute = false;

  Future<void> init() async {
    debugPrint("[UserService] init: Initializing UserService...");
    try {
      _prefs = await SharedPreferences.getInstance();
      debugPrint("[UserService] init: SharedPreferences instance obtained.");

      userId = _prefs.getString('userId');
      username = _prefs.getString('username');
      isGlobalMute = _prefs.getBool(_globalMuteKey) ?? false;

      debugPrint("[UserService] init: Loaded from SharedPreferences -> userId: $userId, username: $username, isGlobalMute: $isGlobalMute");
      debugPrint("[UserService] init: UserService initialization complete.");
    } catch (e, stackTrace) {
      debugPrint("[UserService] init: ERROR during initialization: $e");
      debugPrintStack(stackTrace: stackTrace, label: "[UserService] init Error");
      // Depending on the error, you might want to set default values or rethrow
    }
  }

  bool hasUser() {
    final bool result = userId != null && username != null;
    debugPrint("[UserService] hasUser: Checking if user exists. UserID: $userId, Username: $username. Result: $result");
    return result;
  }

  Future<bool> createUser(String newUsername) async {
    debugPrint("[UserService] createUser: Attempting to create user with username: '$newUsername'");
    final String url = '$_baseUrl/users/generate-id';
    debugPrint("[UserService] createUser: Requesting URL: |$url|");
    try {
      final response = await http.get(Uri.parse(url));
      debugPrint("[UserService] createUser: Response status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        userId = data['userId'] as String?; // Safely cast
        username = newUsername;
        debugPrint("[UserService] createUser: User ID received: $userId. Setting username to: $newUsername");

        if (userId != null) {
          await _prefs.setString('userId', userId!);
          await _prefs.setString('username', username!);
          debugPrint("[UserService] createUser: User details saved to SharedPreferences. UserId: $userId, Username: $username");
          notifyListeners();
          debugPrint("[UserService] createUser: Listeners notified. User creation successful.");
          return true;
        } else {
          debugPrint("[UserService] createUser: Failed to create user - received null userId from server.");
          return false;
        }
      } else {
        debugPrint("[UserService] createUser: Failed to create user - server responded with status ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      debugPrint('[UserService] createUser: ERROR creating user: $e');
      debugPrintStack(stackTrace: stackTrace, label: '[UserService] createUser Error');
    }
    debugPrint("[UserService] createUser: User creation failed.");
    return false;
  }

  Future<void> updateUsername(String newUsername) async {
    debugPrint("[UserService] updateUsername: Attempting to update username to: '$newUsername'. Current username: $username");
    username = newUsername;
    try {
      await _prefs.setString('username', username!);
      debugPrint("[UserService] updateUsername: Username '$newUsername' saved to SharedPreferences.");
      notifyListeners();
      debugPrint("[UserService] updateUsername: Listeners notified.");
    } catch (e, stackTrace) {
      debugPrint("[UserService] updateUsername: ERROR saving username to SharedPreferences: $e");
      debugPrintStack(stackTrace: stackTrace, label: '[UserService] updateUsername Error');
    }
  }

  Future<void> updateUserId(String newUserId) async {
    debugPrint("[UserService] updateUserId: Attempting to update userId to: '$newUserId'. Current userId: $userId");
    userId = newUserId;
    try {
      await _prefs.setString('userId', userId!);
      debugPrint("[UserService] updateUserId: UserId '$newUserId' saved to SharedPreferences.");
      notifyListeners();
      debugPrint("[UserService] updateUserId: Listeners notified.");
    } catch (e, stackTrace) {
      debugPrint("[UserService] updateUserId: ERROR saving userId to SharedPreferences: $e");
      debugPrintStack(stackTrace: stackTrace, label: '[UserService] updateUserId Error');
    }
  }

  Future<void> toggleGlobalMute() async {
    final bool oldMuteState = isGlobalMute;
    isGlobalMute = !isGlobalMute;
    debugPrint("[UserService] toggleGlobalMute: Toggling global mute from $oldMuteState to $isGlobalMute.");
    try {
      await _prefs.setBool(_globalMuteKey, isGlobalMute);
      debugPrint("[UserService] toggleGlobalMute: Global mute state ($isGlobalMute) saved to SharedPreferences.");
      notifyListeners();
      debugPrint("[UserService] toggleGlobalMute: Listeners notified.");
    } catch (e, stackTrace) {
      debugPrint("[UserService] toggleGlobalMute: ERROR saving global mute state: $e");
      debugPrintStack(stackTrace: stackTrace, label: '[UserService] toggleGlobalMute Error');
    }
  }

  Future<bool> syncContactsPseudos(List<Contact> localContacts) async {
    debugPrint("[UserService] syncContactsPseudos: Attempting to sync pseudos for ${localContacts.length} contacts.");
    if (localContacts.isEmpty) {
      debugPrint("[UserService] syncContactsPseudos: No local contacts to sync. Returning false.");
      return false;
    }
    bool hasBeenUpdated = false;
    try {
      final userIds = localContacts.map((c) => c.userId).toList();
      debugPrint("[UserService] syncContactsPseudos: UserIds to sync: $userIds");

      final url = Uri.parse('$_baseUrl/users/get-pseudos');
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({'userIds': userIds});
      debugPrint("[UserService] syncContactsPseudos: Requesting URL: $url with body: $body");

      final response = await http.post(url, headers: headers, body: body);
      debugPrint("[UserService] syncContactsPseudos: Response status: ${response.statusCode}");
      // debugPrint("[UserService] syncContactsPseudos: Response body: ${response.body}"); // Can be verbose

      if (response.statusCode == 200) {
        final Map<String, dynamic> remotePseudos = jsonDecode(response.body);
        debugPrint("[UserService] syncContactsPseudos: Received remote pseudos: $remotePseudos");

        final db = DatabaseService(); // Assuming DatabaseService is a singleton or correctly instantiated
        for (var contact in localContacts) {
          if (remotePseudos.containsKey(contact.userId) &&
              contact.originalPseudo != remotePseudos[contact.userId]) {
            debugPrint("[UserService] syncContactsPseudos: Updating contact ${contact.userId}. Old pseudo: '${contact.originalPseudo}', New pseudo: '${remotePseudos[contact.userId]}'");
            contact.originalPseudo = remotePseudos[contact.userId]!;
            await db.updateContact(contact); // Assuming updateContact handles DB operations
            hasBeenUpdated = true;
          } else if (!remotePseudos.containsKey(contact.userId)) {
            debugPrint("[UserService] syncContactsPseudos: Contact ${contact.userId} not found in remote pseudos response.");
          } else {
            // debugPrint("[UserService] syncContactsPseudos: Contact ${contact.userId} pseudo ('${contact.originalPseudo}') is already up to date."); // Can be verbose
          }
        }
        if (hasBeenUpdated) {
          debugPrint("[UserService] syncContactsPseudos: Contacts updated. Notifying listeners.");
          notifyListeners(); // Notify if any contact was actually updated
        } else {
          debugPrint("[UserService] syncContactsPseudos: No contact pseudos needed updating.");
        }
      } else {
        debugPrint("[UserService] syncContactsPseudos: Failed to get pseudos - server responded with status ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      debugPrint('[UserService] syncContactsPseudos: ERROR during sync: $e');
      debugPrintStack(stackTrace: stackTrace, label: '[UserService] syncContactsPseudos Error');
    }
    debugPrint("[UserService] syncContactsPseudos: Sync process finished. Has been updated: $hasBeenUpdated");
    return hasBeenUpdated;
  }
}
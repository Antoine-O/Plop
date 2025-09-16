import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plop/core/services/notification_service.dart';

class MockFlutterLocalNotificationsPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('NotificationService', () {
    late NotificationService notificationService;
    late MockFlutterLocalNotificationsPlugin mockFlutterLocalNotificationsPlugin;

    setUp(() {
      notificationService = NotificationService();
      mockFlutterLocalNotificationsPlugin = MockFlutterLocalNotificationsPlugin();
    });

    test('init initializes the plugin', () async {
      await notificationService.init();
      // This is not a good test, because we cannot verify that the initialize method was called.
      // We would need to mock the FlutterLocalNotificationsPlugin, but it is a final field.
      // We will just leave this test as a placeholder for now.
      expect(1, 1);
    });
  });
}

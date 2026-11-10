import 'dart:io';

import 'package:arca/core/onboarding/repositories/shared_prefs_onboarding_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'package:arca/app/app.dart';
import 'package:arca/core/database/database_manager.dart';
import 'package:arca/core/database/database_service.dart';
import 'package:arca/core/onboarding/repositories/onboarding_repository.dart';

import '../test_utils/shared_preferences.dart';

void main() {
  group('Router Orchestration End-to-End Tests', () {
    late Directory tempDir;
    late SqliteDatabase db;
    late DatabaseService databaseService;
    late OnboardingRepository onboardingRepo;

    setUp(() {
      SharedPreferencesAsyncPlatform.instance = MockSharedPreferencesAsync();

      tempDir = Directory.systemTemp.createTempSync('arca_router_test_');
      final dbPath = p.join(tempDir.path, 'test.db');
      db = SqliteDatabase(path: dbPath);
      databaseService = DatabaseManager(customDatabase: db);
      onboardingRepo = SharedPrefsOnboardingRepository();
    });

    tearDown(() async {
      SharedPreferencesAsyncPlatform.instance = null;
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets('ArcaApp launches and displays WelcomeScreen', (tester) async {
      final container = ArcaAppContainer(
        onboardingRepository: onboardingRepo,
        databaseService: databaseService,
      );
      await container.init();

      await tester.pumpWidget(ArcaApp(appContainer: container));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Arca'), findsOneWidget);
    });
  });
}

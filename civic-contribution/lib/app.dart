import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/issue_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'providers/report_flow_provider.dart';
import 'providers/user_provider.dart';
import 'providers/verification_provider.dart';
import 'services/credits_service.dart';
import 'services/duplicate_service.dart';
import 'services/firestore_service.dart';
import 'services/image_metadata_service.dart';
import 'services/location_service.dart';
import 'services/mock_auth_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

class CivicApp extends StatelessWidget {
  const CivicApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final creditsService = CreditsService(firestoreService);

    return MultiProvider(
      providers: [
        Provider<MockAuthService>(create: (_) => MockAuthService()),
        Provider<FirestoreService>(create: (_) => firestoreService),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<ImageMetadataService>(create: (_) => ImageMetadataService()),
        Provider<CreditsService>(create: (_) => creditsService),
        Provider<DuplicateService>(
          create: (_) => DuplicateService(firestoreService),
        ),
        ChangeNotifierProxyProvider<MockAuthService, UserProvider>(
          create: (ctx) => UserProvider(
            ctx.read<MockAuthService>(),
            firestoreService,
          ),
          update: (ctx, auth, prev) =>
              prev ?? UserProvider(auth, firestoreService),
        ),
        ChangeNotifierProvider<IssueProvider>(
          create: (_) => IssueProvider(firestoreService),
        ),
        ChangeNotifierProvider<LeaderboardProvider>(
          create: (_) => LeaderboardProvider(firestoreService),
        ),
        ChangeNotifierProvider<ReportFlowProvider>(
          create: (ctx) => ReportFlowProvider(
            locationService: ctx.read<LocationService>(),
            firestoreService: firestoreService,
            storageService: ctx.read<StorageService>(),
            duplicateService: ctx.read<DuplicateService>(),
            creditsService: creditsService,
            metadataService: ctx.read<ImageMetadataService>(),
          ),
        ),
        ChangeNotifierProvider<VerificationProvider>(
          create: (ctx) => VerificationProvider(
            firestoreService,
            ctx.read<StorageService>(),
            creditsService,
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'CivicPulse',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRoutes.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:civic_contribution/presentation/config/theme.dart';
import 'package:civic_contribution/application/providers/admin_data_provider.dart';
import 'package:civic_contribution/application/providers/account_management_provider.dart';
import 'package:civic_contribution/application/providers/archive_provider.dart';
import 'package:civic_contribution/application/providers/community_provider.dart';
import 'package:civic_contribution/application/providers/issue_provider.dart';
import 'package:civic_contribution/application/providers/leaderboard_provider.dart';
import 'package:civic_contribution/application/providers/report_flow_provider.dart';
import 'package:civic_contribution/application/providers/user_provider.dart';
import 'package:civic_contribution/application/providers/verification_provider.dart';
import 'package:civic_contribution/data/services/archive_service.dart';
import 'package:civic_contribution/data/services/archive_storage_service.dart';
import 'package:civic_contribution/data/services/auth_service.dart';
import 'package:civic_contribution/data/services/community_service.dart';
import 'package:civic_contribution/data/services/credits_service.dart';
import 'package:civic_contribution/data/services/duplicate_service.dart';
import 'package:civic_contribution/data/services/export_service.dart';
import 'package:civic_contribution/data/services/firestore_service.dart';
import 'package:civic_contribution/data/services/image_metadata_service.dart';
import 'package:civic_contribution/data/services/location_service.dart';
import 'package:civic_contribution/data/services/notification_service.dart';
import 'package:civic_contribution/data/services/storage_service.dart';
import 'package:civic_contribution/presentation/config/routes.dart';

/// Root widget. Single responsibility: provider wiring and MaterialApp setup.
class CivicApp extends StatelessWidget {
  const CivicApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final creditsService = CreditsService(firestoreService);
    final authService = AuthService();
    final communityService = CommunityService();
    final exportService = ExportService();
    final archiveService = ArchiveService();
    final archiveStorageService = ArchiveStorageService();

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => authService),
        Provider<FirestoreService>(create: (_) => firestoreService),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<ImageMetadataService>(create: (_) => ImageMetadataService()),
        Provider<CreditsService>(create: (_) => creditsService),
        Provider<DuplicateService>(
          create: (_) => DuplicateService(firestoreService),
        ),
        Provider<CommunityService>(create: (_) => communityService),
        Provider<ExportService>(create: (_) => exportService),
        Provider<ArchiveService>(create: (_) => archiveService),
        Provider<ArchiveStorageService>(
          create: (_) => archiveStorageService,
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(authService, firestoreService),
        ),
        ChangeNotifierProvider<IssueProvider>(
          create: (_) => IssueProvider(firestoreService, creditsService),
        ),
        ChangeNotifierProvider<LeaderboardProvider>(
          create: (_) => LeaderboardProvider(firestoreService),
        ),
        ChangeNotifierProvider<CommunityProvider>(
          create: (_) => CommunityProvider(communityService, firestoreService),
        ),
        ChangeNotifierProvider<AdminDataProvider>(
          create: (_) => AdminDataProvider(firestoreService, exportService),
        ),
        ChangeNotifierProvider<ArchiveProvider>(
          create: (_) => ArchiveProvider(
            archiveService,
            archiveStorageService,
            firestoreService,
          ),
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
        ChangeNotifierProxyProvider<UserProvider, AccountManagementProvider>(
          create: (ctx) => AccountManagementProvider(
            communityService,
            firestoreService,
            authService,
            ctx.read<UserProvider>(),
          ),
          update: (ctx, userProvider, previous) =>
              previous ?? AccountManagementProvider(
                communityService,
                firestoreService,
                authService,
                userProvider,
              ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final userProvider = context.watch<UserProvider>();
          return MaterialApp.router(
            title: 'CivicPulse',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: AppRoutes.createRouter(userProvider),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

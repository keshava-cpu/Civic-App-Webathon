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
import 'package:civic_contribution/data/services/database_service.dart';
import 'package:civic_contribution/data/services/duplicate_service.dart';
import 'package:civic_contribution/data/services/export_service.dart';
import 'package:civic_contribution/data/services/image_metadata_service.dart';
import 'package:civic_contribution/data/services/location_service.dart';
import 'package:civic_contribution/data/services/notification_service.dart';
import 'package:civic_contribution/data/services/phash_service.dart';
import 'package:civic_contribution/data/services/storage_service.dart';
import 'package:civic_contribution/presentation/config/routes.dart';

/// Root widget. Single responsibility: provider wiring and MaterialApp setup.
class CivicApp extends StatelessWidget {
  const CivicApp({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = DatabaseService();
    final creditsService = CreditsService(databaseService);
    final authService = AuthService();
    final communityService = CommunityService();
    final exportService = ExportService();
    final archiveService = ArchiveService();
    final archiveStorageService = ArchiveStorageService();
    final phashService = PhashService();
    final duplicateService = DuplicateService(databaseService, phashService);

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => authService),
        Provider<DatabaseService>(create: (_) => databaseService),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<PhashService>(create: (_) => phashService),
        Provider<ImageMetadataService>(
          create: (_) => ImageMetadataService(phashService),
        ),
        Provider<CreditsService>(create: (_) => creditsService),
        Provider<DuplicateService>(create: (_) => duplicateService),
        Provider<CommunityService>(create: (_) => communityService),
        Provider<ExportService>(create: (_) => exportService),
        Provider<ArchiveService>(create: (_) => archiveService),
        Provider<ArchiveStorageService>(
          create: (_) => archiveStorageService,
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(authService, databaseService),
        ),
        ChangeNotifierProxyProvider<UserProvider, IssueProvider>(
          create: (ctx) => IssueProvider(databaseService, creditsService),
          update: (ctx, userProvider, previous) {
            final issueProvider = previous ?? IssueProvider(databaseService, creditsService);
            issueProvider.reinitialize(userProvider.communityId);
            return issueProvider;
          },
        ),
        ChangeNotifierProxyProvider<UserProvider, LeaderboardProvider>(
          create: (ctx) => LeaderboardProvider(databaseService),
          update: (ctx, userProvider, previous) {
            final leaderboardProvider = previous ?? LeaderboardProvider(databaseService);
            leaderboardProvider.reinitialize(userProvider.communityId);
            return leaderboardProvider;
          },
        ),
        ChangeNotifierProvider<CommunityProvider>(
          create: (_) =>
              CommunityProvider(communityService, databaseService),
        ),
        ChangeNotifierProxyProvider<UserProvider, AdminDataProvider>(
          create: (ctx) => AdminDataProvider(databaseService, exportService),
          update: (ctx, userProvider, previous) {
            final adminProvider = previous ?? AdminDataProvider(databaseService, exportService);
            final communityId = userProvider.communityId;
            if (communityId != null && userProvider.isAdmin) {
              adminProvider.subscribeToIssues(communityId);
            }
            return adminProvider;
          },
        ),
        ChangeNotifierProvider<ArchiveProvider>(
          create: (_) => ArchiveProvider(
            archiveService,
            archiveStorageService,
            databaseService,
          ),
        ),
        ChangeNotifierProvider<ReportFlowProvider>(
          create: (ctx) => ReportFlowProvider(
            locationService: ctx.read<LocationService>(),
            firestoreService: databaseService,
            storageService: ctx.read<StorageService>(),
            duplicateService: duplicateService,
            creditsService: creditsService,
            metadataService: ctx.read<ImageMetadataService>(),
            phashService: phashService,
          ),
        ),
        ChangeNotifierProvider<VerificationProvider>(
          create: (ctx) => VerificationProvider(
            databaseService,
            ctx.read<StorageService>(),
            creditsService,
          ),
        ),
        ChangeNotifierProxyProvider<UserProvider, AccountManagementProvider>(
          create: (ctx) => AccountManagementProvider(
            communityService,
            databaseService,
            authService,
            ctx.read<UserProvider>(),
          ),
          update: (ctx, userProvider, previous) =>
              previous ??
              AccountManagementProvider(
                communityService,
                databaseService,
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

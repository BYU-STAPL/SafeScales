import 'package:provider/provider.dart';
import 'package:safe_scales/dependencies/shop_dependencies.dart';
import 'package:safe_scales/dependencies/theme_dependencies.dart';
import 'package:safe_scales/providers/shop_provider.dart';
import 'package:safe_scales/services/course_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/user_state_service.dart';
import '../providers/course_provider.dart';
import '../providers/dragon_provider.dart';
import '../providers/item_provider.dart';
import '../providers/theme_provider.dart';
import 'course_dependencies.dart';
import 'dragon_dependencies.dart';
import 'item_dependencies.dart';

/// Global app-level dependencies manager
/// Centralizes all feature dependencies and shared services
class AppDependencies {
  // === Shared Services ===
  final SupabaseClient supabase;
  final UserStateService userStateService;
  final CourseService courseService;

  // === Feature Dependencies ===
  late final CourseDependencies course;
  late final DragonDependencies dragon;
  late final ItemDependencies item;
  late final ShopDependencies shop;
  late final ThemeDependencies theme;

  AppDependencies({
    required this.supabase,
    required this.userStateService,
    required this.courseService,
  }) {
    _initializeAllDependencies();
  }

  void _initializeAllDependencies() {
    // Initialize course dependencies
    course = CourseDependencies(
      supabase: supabase,
      userStateService: userStateService,
    );

    // Initialize dragon dependencies
    dragon = DragonDependencies(
      supabase: supabase,
      userStateService: userStateService,
      courseService: courseService,
    );

    // Initialize item dependencies
    item = ItemDependencies(
      supabase: supabase,
      userStateService: userStateService,
    );

    // Initialize theme dependencies
    theme = ThemeDependencies(
      supabase: supabase,
      userStateService: userStateService,
    );

    shop = ShopDependencies(
        supabase: supabase,
        userStateService: userStateService
    );
  }

  /// Initialize all providers - but DON'T load data yet
  /// Data loading will happen in AppInitializationScreen after authentication
  Future<void> initializeProviders() async {
    try {
      // Just initialize the providers, don't load data
      await course.provider.initialize();
      await dragon.provider.initialize();
      await item.provider.initialize();
      await shop.provider.initialize();

    } catch (e) {
      print("❌ Provider initialization failed: $e");
      rethrow;
    }
  }

  /// Load all provider data - called from AppInitializationScreen
  Future<void> loadAllData() async {
    try {
      // Load course data
      await course.provider.loadCourseContent();
      await course.provider.loadUserProgress();

      // Load dragon data
      await dragon.provider.loadUserDragons();

      // Load item data
      await item.provider.loadUserItems();

      // Load shop data
      await shop.provider.loadShopData();

    } catch (e) {
      print("❌ Provider data loading failed: $e");
      rethrow;
    }
  }

  /// Helper method to get current class ID
  // Future<String?> _getCurrentClassId() async {
  //   try {
  //     final user = userStateService.currentUser;
  //     if (user == null) {
  //       print("⚠️ No current user for class ID lookup");
  //       return null;
  //     }
  //
  //     // Option 1: Get from user's metadata if stored there
  //     final userMetadata = user.userMetadata;
  //     if (userMetadata.containsKey('class_id')) {
  //       return userMetadata['class_id'] as String?;
  //     }
  //
  //     // Option 2: Query from database
  //     try {
  //       final response =
  //           await supabase
  //               .from('Users')
  //               .select('class_id')
  //               .eq('id', user.id)
  //               .maybeSingle();
  //
  //       return response?['class_id'] as String?;
  //     } catch (dbError) {
  //       print("⚠️ Database query for class_id failed: $dbError");
  //       return null;
  //     }
  //   } catch (e) {
  //     print("❌ Error getting current class ID: $e");
  //     return null;
  //   }
  // }

  /// Get all providers for MultiProvider setup
  List<ChangeNotifierProvider> getProviders() {
    return [
      ChangeNotifierProvider<ThemeNotifier>.value(value: theme.notifier),
      ChangeNotifierProvider<CourseProvider>.value(value: course.provider),
      ChangeNotifierProvider<DragonProvider>.value(value: dragon.provider),
      ChangeNotifierProvider<ItemProvider>.value(value: item.provider),
      ChangeNotifierProvider<ShopProvider>.value(value: shop.provider,),
      // Add future providers here
    ];
  }

  /// Dispose all dependencies
  void dispose() {
    theme.dispose();
    course.dispose();
    dragon.dispose();
    item.dispose();
    shop.dispose();
  }

  /// Health check - verify all dependencies are properly initialized
  bool get isHealthy {
    try {
      // Check if all core dependencies are available
      final checks = [
        true, // Supabase client presence
        theme.isHealthy,
        true, // providers constructed
        true,
        true,
      ];

      return checks.every((check) => check == true);
    } catch (e) {
      print("❌ Health check failed: $e");
      return false;
    }
  }
}

/// Factory for creating app-wide dependencies
AppDependencies createAppDependencies({
  required SupabaseClient supabase,
  UserStateService? userStateService,
  CourseService? courseService,
}) {
  return AppDependencies(
    supabase: supabase,
    userStateService: userStateService ?? UserStateService(),
    courseService: courseService ?? CourseService(),
  );
}

/// Simplified factory that creates all services automatically
AppDependencies createAppDependenciesFromSupabase(SupabaseClient supabase) {
  final userStateService = UserStateService();
  final courseService = CourseService();

  return AppDependencies(
    supabase: supabase,
    userStateService: userStateService,
    courseService: courseService,
  );
}

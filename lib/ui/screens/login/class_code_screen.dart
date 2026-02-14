import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/config/supabase_config.dart';
import 'package:safe_scales/ui/screens/app_initialization_screen.dart'; // Import the new screen
import 'package:safe_scales/services/user_state_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class ClassCodeScreen extends StatefulWidget {
  const ClassCodeScreen({super.key});

  @override
  State<ClassCodeScreen> createState() => _ClassCodeScreenState();
}

class _ClassCodeScreenState extends State<ClassCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classCodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _userState = UserStateService();
  bool isLoading = false;

  @override
  void dispose() {
    _classCodeController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  /// Parses default_habitat / default_item from the dashboard (JSON string or array).
  /// Returns a list of asset ID strings.
  static List<String> _parseDefaultIds(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e?.toString().trim())
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return [];
      try {
        final decoded = jsonDecode(s);
        if (decoded is List) {
          return decoded
              .map((e) => e?.toString().trim())
              .whereType<String>()
              .where((s) => s.isNotEmpty)
              .toList();
        }
        return [s];
      } catch (_) {
        return [s];
      }
    }
    return [];
  }

  /// Resolves parsed default ID lists to IDs that exist in class assets with the
  /// correct type. Returns (environment IDs, accessory IDs) in dashboard order.
  (List<String>, List<String>) _resolveDefaultIdsFromAssets(
    List<Map<String, dynamic>> classAssets,
    List<String> defaultHabitatIds,
    List<String> defaultItemIds,
  ) {
    final assetIdsByType = <String, String>{};
    for (final asset in classAssets) {
      final id = asset['id']?.toString();
      if (id == null || id.isEmpty) continue;
      final type = asset['type']?.toString();
      if (type != null && (type == 'environment' || type == 'accessory')) {
        assetIdsByType[id] = type;
      }
    }

    final envIds = defaultHabitatIds
        .where((id) => assetIdsByType[id] == 'environment')
        .toList();
    final itemIds = defaultItemIds
        .where((id) => assetIdsByType[id] == 'accessory')
        .toList();

    return (envIds, itemIds);
  }

  Future<void> _submitForm() async {
    //TODO: Move Direct database access code into a repository file

    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        // Clean the class code of any ANSI color codes and trim whitespace
        final cleanClassCode =
            _classCodeController.text
                .replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '')
                .trim();

        // Get class ID from class code (case-insensitive)
        final classResponseList = await SupabaseConfig.client
            .from('classes')
            .select('id, code')
            .ilike('code', cleanClassCode);

        if (classResponseList.isEmpty) {
          throw Exception('Invalid class code');
        }

        final classId = classResponseList[0]['id'];

        // Check if user with same username exists in the class
        final existingUserResponse =
            await SupabaseConfig.client
                .from('Users')
                .select()
                .eq('Username', _usernameController.text.trim())
                .maybeSingle();

        if (existingUserResponse != null) {
          // User exists, check if they're already in the class
          final joinedClasses = List<String>.from(
            existingUserResponse['joined_classes'] ?? [],
          );
          if (joinedClasses.contains(classId)) {
            // User has already joined this class - treat as sign-in
            final supabaseUser = supabase.User(
              id: existingUserResponse['id'],
              email: existingUserResponse['email'],
              createdAt: existingUserResponse['created_at'],
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              role: 'authenticated',
            );

            // Set the user as current user (sign them in)
            _userState.setUser(supabaseUser);
            _userState.setUserProfile(existingUserResponse);

            if (mounted) {
              final theme = Theme.of(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome back! Signed in successfully.'),
                  backgroundColor: theme.colorScheme.secondaryContainer,
                ),
              );

              // Navigate to initialization screen instead of MainNavigation
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const AppInitializationScreen(),
                ),
                (route) => false, // Remove all previous routes
              );
            }
            return;
          }

          // User exists but not in this class - add class to user's joined_classes
          joinedClasses.add(classId);
          await SupabaseConfig.client
              .from('Users')
              .update({'joined_classes': joinedClasses})
              .eq('id', existingUserResponse['id']);

          // Grant the new class's default env/item if not already owned
          final classDefaultsResponse =
              await SupabaseConfig.client
                  .from('classes')
                  .select('assets, default_habitat, default_item')
                  .eq('id', classId)
                  .single();

          final defaultsAssetList = List<Map<String, dynamic>>.from(
            classDefaultsResponse['assets'] ?? [],
          );
          final defaultHabitatIds = _parseDefaultIds(classDefaultsResponse['default_habitat']);
          final defaultItemIdsRaw = _parseDefaultIds(classDefaultsResponse['default_item']);
          final (defaultEnvIds, defaultItemIds) = _resolveDefaultIdsFromAssets(
            defaultsAssetList,
            defaultHabitatIds,
            defaultItemIdsRaw,
          );

          final userId = existingUserResponse['id'] as String;
          final updates = <String, dynamic>{};

          if (defaultEnvIds.isNotEmpty) {
            final acquiredEnvsRaw = existingUserResponse['acquired_environments'];
            List<dynamic> acquiredEnvs = acquiredEnvsRaw is Map
                ? acquiredEnvsRaw.values.toList()
                : List<dynamic>.from(acquiredEnvsRaw ?? []);
            bool changed = false;
            for (final id in defaultEnvIds) {
              if (!acquiredEnvs.contains(id)) {
                acquiredEnvs.add(id);
                changed = true;
              }
            }
            if (changed) updates['acquired_environments'] = acquiredEnvs;
          }

          if (defaultItemIds.isNotEmpty) {
            final acquiredAccRaw = existingUserResponse['acquired_accessories'];
            List<dynamic> acquiredAcc = acquiredAccRaw is Map
                ? acquiredAccRaw.values.toList()
                : List<dynamic>.from(acquiredAccRaw ?? []);
            bool changed = false;
            for (final id in defaultItemIds) {
              if (!acquiredAcc.contains(id)) {
                acquiredAcc.add(id);
                changed = true;
              }
            }
            if (changed) updates['acquired_accessories'] = acquiredAcc;
          }

          Map<String, dynamic> userProfile = Map<String, dynamic>.from(existingUserResponse);
          if (updates.isNotEmpty) {
            await SupabaseConfig.client
                .from('Users')
                .update(updates)
                .eq('id', userId);
            userProfile.addAll(updates);
          }

          // Set the user as current user
          final supabaseUser = supabase.User(
            id: existingUserResponse['id'],
            email: existingUserResponse['email'],
            createdAt: existingUserResponse['created_at'],
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            role: 'authenticated',
          );

          _userState.setUser(supabaseUser);
          _userState.setUserProfile(userProfile);
        } else {
          // User doesn't already exist

          // Get modules for the class
          final classResponse =
              await SupabaseConfig.client
                  .from('classes')
                  .select('course_modules')
                  .eq('id', classId)
                  .single();

          // Initialize empty progress for each module
          Map<String, dynamic> initialReadingProgress = {};
          if (classResponse['course_modules'] != null) {
            for (var moduleId in classResponse['course_modules']) {
              initialReadingProgress[moduleId] = {
                'reading': {
                  'completed': false,
                  'completed_at': null,
                  'bookmarks': [],
                },
              };
            }
          }

          // Load class assets and default_habitat / default_item from classes table
          // so we can grant those habitats and items to the new user.
          final classAssetsResponse =
              await SupabaseConfig.client
                  .from('classes')
                  .select('assets, default_habitat, default_item')
                  .eq('id', classId)
                  .single();

          final classAssetList = List<Map<String, dynamic>>.from(
            classAssetsResponse['assets'] ?? [],
          );

          final defaultHabitatIds = _parseDefaultIds(classAssetsResponse['default_habitat']);
          final defaultItemIds = _parseDefaultIds(classAssetsResponse['default_item']);
          final (resolvedEnvIds, resolvedItemIds) =
              _resolveDefaultIdsFromAssets(classAssetList, defaultHabitatIds, defaultItemIds);

          Map<String, dynamic> initialDragonData = {};

          for (final asset in classAssetList) {
            if (asset['type'] != 'dragon') continue;

            final dragonId = asset['id'] as String?;
            if (dragonId == null) continue;

            initialDragonData[dragonId] = {
              'name': 'no name',
              'phases': ['egg'],
            };
          }

          final initialAcquiredEnvironments = List<String>.from(resolvedEnvIds);
          final initialAcquiredAccessories = List<String>.from(resolvedItemIds);
          final initialDragonEnvironments = <String, dynamic>{};
          final firstDefaultEnvId = resolvedEnvIds.isNotEmpty ? resolvedEnvIds.first : null;
          if (firstDefaultEnvId != null) {
            for (final dragonId in initialDragonData.keys) {
              initialDragonEnvironments[dragonId] = firstDefaultEnvId;
            }
          }

          // Create new user with initialized modules
          final newUserResponse =
              await SupabaseConfig.client
                  .from('Users')
                  .insert({
                    'Username': _usernameController.text.trim(),
                    'role': 'student',
                    'joined_classes': [classId],
                    'settings': {"fontSize": 1.0, "isDarkMode": false},
                    'dragons': initialDragonData,
                    'acquired_accessories': initialAcquiredAccessories,
                    'acquired_environments': initialAcquiredEnvironments,
                    'dragon_preferred_phases': {},
                    'dragon_environments': initialDragonEnvironments,
                    'dragon_dressup': {},
                    'reading_progress': initialReadingProgress,
                  })
                  .select()
                  .single();

          // Set the new user as current user
          final supabaseUser = supabase.User(
            id: newUserResponse['id'],
            email: newUserResponse['email'],
            createdAt: newUserResponse['created_at'],
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            role: 'authenticated',
          );

          _userState.setUser(supabaseUser);
          _userState.setUserProfile(newUserResponse);
        }

        if (mounted) {
          final theme = Theme.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully joined class!'),
              backgroundColor: theme.colorScheme.secondaryContainer,
            ),
          );

          // Navigate to initialization screen instead of MainNavigation
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const AppInitializationScreen(),
            ),
            (route) => false, // Remove all previous routes
          );
        }
      } catch (e) {
        if (mounted) {
          final theme = Theme.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: theme.colorScheme.errorContainer,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              theme.colorScheme.lightBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Add back button at the top
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: theme.colorScheme.onPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    color: theme.colorScheme.surfaceContainer,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Join a Class',
                              style: theme.textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 25),
                            TextFormField(
                              controller: _classCodeController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Class Code',
                                prefixIcon: Icon(
                                  Icons.class_,
                                  size: 25 * AppTheme.fontSizeScale,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the class code';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(
                                  Icons.person,
                                  size: 24 * AppTheme.fontSizeScale,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a username';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:
                                    isLoading
                                        ? const CircularProgressIndicator()
                                        : Text(
                                          'Join Class',
                                          style: TextStyle(
                                            fontSize:
                                                16 * AppTheme.fontSizeScale,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

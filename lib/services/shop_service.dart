import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safe_scales/config/supabase_config.dart';

class ShopService {
  final supabase = SupabaseConfig.client;

  Future<List<Map<String, dynamic>>> getAccessories() async {
    try {
      final response = await supabase
          .from('accessories')
          .select()
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching accessories: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEnvironments() async {
    try {
      final response = await supabase
          .from('environments')
          .select()
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching environments: $e');
      return [];
    }
  }

  Future<bool> purchaseAccessory(String userId, int accessoryId) async {
    try {
      // First get the current user's acquired accessories
      final userResponse =
          await supabase
              .from('Users')
              .select('acquired_accessories')
              .eq('id', userId)
              .single();

      // Handle both Map and List formats
      List<dynamic> acquiredAccessories;
      if (userResponse['acquired_accessories'] is Map) {
        // If it's a Map, convert it to a List of IDs
        final Map<String, dynamic> accessoriesMap =
            userResponse['acquired_accessories'];
        acquiredAccessories = accessoriesMap.values.toList();
      } else {
        // If it's already a List, use it directly
        acquiredAccessories = userResponse['acquired_accessories'] ?? [];
      }

      // Check if user already has this accessory
      if (acquiredAccessories.contains(accessoryId)) {
        print('User already owns this accessory');
        return false;
      }

      // Add the new accessory ID to the list
      acquiredAccessories.add(accessoryId);

      // Update the user's acquired accessories
      await supabase
          .from('Users')
          .update({'acquired_accessories': acquiredAccessories})
          .eq('id', userId);

      return true;
    } catch (e) {
      print('Error purchasing accessory: $e');
      return false;
    }
  }

  Future<List<int>> getUserAcquiredAccessories(String userId) async {
    try {
      final response =
          await supabase
              .from('Users')
              .select('acquired_accessories')
              .eq('id', userId)
              .single();

      // Handle both Map and List formats
      List<dynamic> acquiredAccessories;
      if (response['acquired_accessories'] is Map) {
        // If it's a Map, convert it to a List of IDs
        final Map<String, dynamic> accessoriesMap =
            response['acquired_accessories'];
        acquiredAccessories = accessoriesMap.values.toList();
      } else {
        // If it's already a List, use it directly
        acquiredAccessories = response['acquired_accessories'] ?? [];
      }

      return acquiredAccessories.map((id) => id as int).toList();
    } catch (e) {
      print('Error getting user acquired accessories: $e');
      return [];
    }
  }

  Future<List<String>> getUserAcquiredEnvironments(String userId) async {
    try {
      final response =
          await supabase
              .from('Users')
              .select('acquired_environments')
              .eq('id', userId)
              .single();

      // Handle both Map and List formats
      List<dynamic> acquiredEnvironments;
      if (response['acquired_environments'] is Map) {
        // If it's a Map, convert it to a List of IDs
        final Map<String, dynamic> environmentsMap =
            response['acquired_environments'];
        acquiredEnvironments = environmentsMap.values.toList();
      } else {
        // If it's already a List, use it directly
        acquiredEnvironments = response['acquired_environments'] ?? [];
      }

      return acquiredEnvironments.map((id) => id as String).toList();
    } catch (e) {
      print('Error getting user acquired environments: $e');
      return [];
    }
  }

  Future<bool> purchaseEnvironment(String userId, String environmentId) async {
    try {
      // First get the current user's acquired environments
      final userResponse =
          await supabase
              .from('Users')
              .select('acquired_environments')
              .eq('id', userId)
              .single();

      // Handle both Map and List formats
      List<dynamic> acquiredEnvironments;
      if (userResponse['acquired_environments'] is Map) {
        // If it's a Map, convert it to a List of IDs
        final Map<String, dynamic> environmentsMap =
            userResponse['acquired_environments'];
        acquiredEnvironments = environmentsMap.values.toList();
      } else {
        // If it's already a List, use it directly
        acquiredEnvironments = userResponse['acquired_environments'] ?? [];
      }

      // Check if user already has this environment
      if (acquiredEnvironments.contains(environmentId)) {
        print('User already owns this environment');
        return false;
      }

      // Add the new environment ID to the list
      acquiredEnvironments.add(environmentId);

      // Update the user's acquired environments
      await supabase
          .from('Users')
          .update({'acquired_environments': acquiredEnvironments})
          .eq('id', userId);

      return true;
    } catch (e) {
      print('Error purchasing environment: $e');
      return false;
    }
  }
}

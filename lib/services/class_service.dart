import 'package:supabase_flutter/supabase_flutter.dart';

class ClassService {
  final SupabaseClient supabase;

  ClassService(this.supabase);

  Future<Map<String, dynamic>> getUserClass(String userId) async {
    try {
      // Get user's joined classes
      final userResponse =
          await supabase
              .from('Users')
              .select('joined_classes')
              .eq('id', userId)
              .single();

      if (userResponse['joined_classes'] == null ||
          (userResponse['joined_classes'] as List).isEmpty) {
        print('No joined classes found for user: $userId');
        return {};
      }

      // Get the first class ID from the array
      final classId = (userResponse['joined_classes'] as List).first;

      // Get class details
      final classResponse =
          await supabase.from('classes').select().eq('id', classId).single();

      // print('Class details: $classResponse');

      return Map<String, dynamic>.from(classResponse);

    } catch (e) {
      print('❌Error getting user class: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getClassModules(String classId) async {
    try {
      // Get class details to get course_modules
      final classResponse =
          await supabase
              .from('classes')
              .select('course_modules')
              .eq('id', classId)
              .single();

      if (classResponse['course_modules'] == null) {
        print('No course modules found for class: $classId');
        return [];
      }

      // Get module IDs from the course_modules array
      final moduleIds = List<String>.from(classResponse['course_modules']);

      // Get module details for each module ID
      final modulesResponse = await supabase
          .from('modules')
          .select()
          .inFilter('id', moduleIds)
          .order('created_at', ascending: true);

      final modules = List<Map<String, dynamic>>.from(modulesResponse);

      return modules;
    } catch (e) {
      print('❌Error getting class modules: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getModuleById(String moduleId) async {
    try {
      final moduleResponse =
          await supabase.from('modules').select().eq('id', moduleId).single();

      return Map<String, dynamic>.from(moduleResponse);
    } catch (e) {
      print('❌Error getting module by ID: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getClassAssets(String classId) async {
    try {
      final classResponse =
          await supabase
              .from('classes')
              .select('assets')
              .eq('id', classId)
              .single();

      if (classResponse['assets'] != null) {
        return List<dynamic>.from(classResponse['assets']);
      }

      return null;
    } catch (e) {
      print('❌Error getting class assets: $e');
      return null;
    }
  }
}

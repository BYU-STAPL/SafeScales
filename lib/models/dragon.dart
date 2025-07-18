class Dragon {
  final String id;
  final String speciesName;
  final String moduleId;
  final String preferredEnvironment;
  final String favoriteItem;
  final String name;

  // Dynamic phases with their images
  final Map<String, String> phaseImages;
  final List<String> phaseOrder;

  Dragon({
    required this.id,
    required this.speciesName,
    required this.moduleId,
    required this.preferredEnvironment,
    required this.favoriteItem,
    required this.name,
    required this.phaseImages,
    required this.phaseOrder,
  });

  // Convenience getters for common phases (for backward compatibility)
  String get eggImage => phaseImages['egg'] ?? '';
  String get stage1Image => phaseImages['stage1'] ?? phaseImages['baby'] ?? '';
  String get stage2Image => phaseImages['stage2'] ?? phaseImages['teen'] ?? '';
  String get finalImage => phaseImages['final'] ?? phaseImages['adult'] ?? '';

  // Get image for any phase
  String getImageForPhase(String phase) {
    return phaseImages[phase] ?? phaseImages['egg'] ?? '';
  }

  // Get all available phases
  List<String> get availablePhases => phaseOrder;

  // Check if dragon has a specific phase
  bool hasPhase(String phase) {
    return phaseImages.containsKey(phase);
  }

  // Get the phase index
  int getPhaseIndex(String phase) {
    return phaseOrder.indexOf(phase);
  }
}
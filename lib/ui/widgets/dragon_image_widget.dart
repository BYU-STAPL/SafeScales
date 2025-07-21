import 'package:flutter/cupertino.dart';

import '../../states/dragon_state_manager.dart';

class DragonImageWidget extends StatelessWidget {
  final String moduleId;
  final double size;

  final String? phase;


  const DragonImageWidget({
    Key? key,
    required this.moduleId,
    required this.size,
    this.phase,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dragon = DragonStateManager().getDragonByModuleId(moduleId);

    String imageUrl = 'assets/images/other/QuestionMark.png';
    if (dragon != null) {
      imageUrl = DragonStateManager().getDragonImageUrl(dragon.id, forPhase: phase ?? DragonStateManager().getDragonHighestPhase(dragon.id));
    }

    Widget imageWidget = Image.asset(imageUrl, width: size, height: size);

    if (imageUrl.startsWith('http')) {
      imageWidget = Image.network(
        imageUrl,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/other/QuestionMark.png',
            width: size,
            height: size,
          );
        },
      );
    }

    return imageWidget;
  }
}

// Usage in your screens:
// DragonImageWidget(moduleId: widget.moduleId, phase: 'baby')
// DragonImageWidget(moduleId: widget.moduleId, phase: 'teen')
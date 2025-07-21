import 'package:flutter/cupertino.dart';

import '../../models/dragon.dart';
import '../../states/dragon_state_manager.dart';

class DragonImageWidget extends StatelessWidget {
  final String? dragonId;
  final String? moduleId;
  final double size;

  final String? phase;


  const DragonImageWidget({
    Key? key,
    this.dragonId,
    this.moduleId,
    required this.size,
    this.phase,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    Dragon? dragon;
    if (moduleId != null) {
      dragon = DragonStateManager().getDragonByModuleId(moduleId!);
    }
    else if (dragonId != null) {
      dragon = DragonStateManager().getDragonById(dragonId!);
    }


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
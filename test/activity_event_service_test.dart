import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:safe_scales/services/activity_event_service.dart';

void main() {
  test('createEventId never uses nextInt(0) and returns unique ids', () {
    final ids = <String>{};
    for (var i = 0; i < 200; i++) {
      final id = ActivityEventService.createEventId();
      expect(id, isNotEmpty);
      expect(id.contains('-'), isTrue);
      final randomPart = id.split('-').last;
      expect(int.parse(randomPart), inInclusiveRange(0, 0xFFFFFFFF));
      ids.add(id);
    }
    expect(ids.length, 200);
  });

  test('Random.nextInt rejects max 0 (documents web 1<<32 pitfall)', () {
    // On dart2js, `1 << 32` evaluates to 0. Guard against regressing to that.
    expect(() => Random().nextInt(0), throwsRangeError);
    expect(() => Random().nextInt(1 << 16), returnsNormally);
  });
}

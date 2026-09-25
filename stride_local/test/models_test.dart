import 'package:flutter_test/flutter_test.dart';

import 'package:stride_local/models/activity.dart';

void main() {
  test('activity type labels are readable', () {
    expect(ActivityType.run.label, 'Run');
    expect(ActivityType.cycle.label, 'Cycling');
  });
}

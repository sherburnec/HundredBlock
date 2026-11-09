import 'package:flutter_test/flutter_test.dart';
import 'package:hundred_block/map/screen_point.dart';

void main() {
  test('web points are already logical', () {
    final o = screenPointToLogical(
      300,
      150,
      physicalPixels: false,
      devicePixelRatio: 2.75,
    );
    expect(o.dx, 300);
    expect(o.dy, 150);
  });

  test('native physical pixels are divided by the device pixel ratio', () {
    final o = screenPointToLogical(
      825,
      412.5,
      physicalPixels: true,
      devicePixelRatio: 2.75,
    );
    expect(o.dx, closeTo(300, 1e-9));
    expect(o.dy, closeTo(150, 1e-9));
  });

  test('ratio 1 and a bad ratio leave the point unchanged', () {
    expect(
      screenPointToLogical(10, 20, physicalPixels: true, devicePixelRatio: 1),
      const Offset(10, 20),
    );
    expect(
      screenPointToLogical(10, 20, physicalPixels: true, devicePixelRatio: 0),
      const Offset(10, 20),
    );
  });
}

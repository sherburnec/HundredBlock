import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hundred_block/map/map_style.dart';

double _lum(String hex) {
  final v = int.parse(hex.substring(1), radix: 16);
  double ch(int c) {
    final s = c / 255;
    return s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * ch((v >> 16) & 255) +
      0.7152 * ch((v >> 8) & 255) +
      0.0722 * ch(v & 255);
}

double contrast(String a, String b) {
  final la = _lum(a), lb = _lum(b);
  final hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  const bg = '#10151c'; // background color in kBlankMapStyle

  test('the blank style background is the color this test assumes', () {
    expect(kBlankMapStyle, contains(bg));
  });

  test(
    'street lines meet 3:1 against the background (WCAG non-text contrast)',
    () {
      expect(contrast(kStreetColor, bg), greaterThanOrEqualTo(3.0));
    },
  );

  test('highlighted streets are much brighter than ordinary streets', () {
    expect(contrast(kHighlightColor, bg), greaterThanOrEqualTo(7.0));
    expect(contrast(kHighlightColor, kStreetColor), greaterThanOrEqualTo(2.0));
  });

  test('markers and the landmark dot meet 3:1 against the background', () {
    for (final c in [kGuessColor, kTruthColor, kLandmarkColor, kLinkColor]) {
      expect(contrast(c, bg), greaterThanOrEqualTo(3.0), reason: c);
    }
  });

  test('guess and true-spot markers differ from each other', () {
    expect(kGuessColor, isNot(kTruthColor));
  });
}

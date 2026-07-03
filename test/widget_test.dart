import 'package:flutter_test/flutter_test.dart';
import 'package:riddles_words/src/models/level.dart';

void main() {
  const level = Level(
    level: 10,
    type: 'Jumble',
    question: 'Unscramble: RTHEA',
    answer: 'EARTH',
    accept: ['EARTH', 'HEART', 'HATER'],
    hint: 'The planet we live on.',
    solution: 'RTHEA unscrambles to EARTH.',
  );

  test('answer matching normalizes case, spaces and punctuation', () {
    expect(level.matches('earth'), isTrue);
    expect(level.matches('  EaRtH '), isTrue);
    expect(level.matches('e a r t h'), isTrue);
    expect(level.matches('heart'), isTrue);
    expect(level.matches('hater'), isTrue);
    expect(level.matches('water'), isFalse);
    expect(level.matches(''), isFalse);
  });
}

import 'dart:math';

class Die {
  List<String> letters;
  Die(this.letters);

  String roll() {
    Random random = Random();
    return letters[random.nextInt(letters.length)];
  }
}

class Dice {
  late List<Die> dice;
  Dice(int dimension) {
    dice = [
      Die(['N', 'L', 'N', 'H', 'Z', 'R']),
      Die(['D', 'R', 'Y', 'V', 'E', 'L']),
      Die(['F', 'F', 'K', 'S', 'P', 'A']),
      Die(['S', 'E', 'N', 'I', 'E', 'U']),
      Die(['S', 'E', 'I', 'S', 'O', 'T']),
      Die(['I', 'D', 'L', 'X', 'E', 'R']),
      Die(['T', 'V', 'E', 'H', 'R', 'W']),
      Die(['Y', 'T', 'I', 'S', 'T', 'D']),
      Die(['H', 'G', 'E', 'W', 'E', 'N']),
      Die(['H', 'N', 'QU', 'M', 'I', 'U']),
      Die(['N', 'A', 'E', 'G', 'A', 'E']),
      Die(['O', 'O', 'A', 'B', 'B', 'J']),
      Die(['L', 'E', 'T', 'T', 'Y', 'R']),
      Die(['O', 'I', 'C', 'U', 'T', 'M']),
      Die(['O', 'A', 'H', 'S', 'P', 'C']),
      Die(['O', 'A', 'W', 'T', 'T', 'O']),
    ];
  }

  String roll() {
    List<int> indexes = List.generate(dice.length, (index) => index);
    Random random = Random();
    String result = '';
    while (indexes.isNotEmpty) {
      int index = random.nextInt(indexes.length);
      result += dice[indexes[index]].roll();
      indexes.removeAt(index);
    }
    return result;
  }
}

const Map<String, String> EMOJI_ICONS = {
  'A': '  Ａ  ',
  'B': '  Ｂ  ',
  'C': '  Ｃ  ',
  'D': '  Ｄ  ',
  'E': '  Ｅ  ',
  'F': '  Ｆ  ',
  'G': '  Ｇ  ',
  'H': '  Ｈ  ',
  'I': '  Ｉ  ',
  'J': '  Ｊ  ',
  'K': '  Ｋ  ',
  'L': '  Ｌ  ',
  'M': '  Ｍ  ',
  'N': '  Ｎ  ',
  'O': '  Ｏ  ',
  'P': '  Ｐ  ',
  'Q': '  Ｑ  ',
  'R': '  Ｒ  ',
  'S': '  Ｓ  ',
  'T': '  Ｔ  ',
  'U': '  Ｕ  ',
  'V': '  Ｖ  ',
  'W': '  Ｗ  ',
  'X': '  Ｘ  ',
  'Y': '  Ｙ  ',
  'Z': '  Ｚ  ',
  'QU': 'ＱＵ',
};
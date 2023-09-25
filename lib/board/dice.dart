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
  Map<int, List<Die>> dice = {
    1: [
      Die(['A', 'A', 'A', 'I', 'I', 'I']),
    ],
    2: [
      Die(['A', 'E', 'I', 'O', 'U', 'E']),
      Die(['T', 'R', 'S', 'H', 'L', 'D']),
      Die(['C', 'M', 'F', 'N', 'E', 'P']),
      Die(['G', 'N', 'R', 'K', 'T', 'A']),
    ],
    3: [
      Die(['A', 'E', 'I', 'O', 'T', 'N']),
      Die(['R', 'L', 'S', 'C', 'M', 'P']),
      Die(['D', 'G', 'U', 'H', 'V', 'W']),
      Die(['F', 'K', 'Y', 'B', 'J', 'Z']),
      Die(['X', 'QU', 'E', 'T', 'N', 'E']),
      Die(['O', 'A', 'E', 'R', 'L', 'S']),
      Die(['I', 'U', 'N', 'E', 'H', 'T']),
      Die(['M', 'C', 'D', 'Y', 'P', 'G']),
      Die(['K', 'F', 'L', 'W', 'V', 'B'])
    ],
    4: [
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
    ],
    5: [
      Die(['A', 'A', 'A', 'F', 'R', 'S']),
      Die(['A', 'A', 'E', 'E', 'E', 'E']),
      Die(['A', 'A', 'F', 'I', 'R', 'S']),
      Die(['A', 'D', 'E', 'N', 'N', 'N']),
      Die(['A', 'E', 'E', 'E', 'E', 'M']),
      Die(['A', 'E', 'E', 'G', 'M', 'U']),
      Die(['A', 'E', 'G', 'M', 'N', 'N']),
      Die(['A', 'F', 'I', 'R', 'S', 'Y']),
      Die(['B', 'J', 'K', 'Q', 'X', 'Z']),
      Die(['C', 'C', 'E', 'N', 'S', 'T']),
      Die(['C', 'E', 'I', 'I', 'L', 'T']),
      Die(['C', 'E', 'I', 'L', 'P', 'T']),
      Die(['C', 'E', 'I', 'P', 'S', 'T']),
      Die(['D', 'D', 'H', 'N', 'O', 'T']),
      Die(['D', 'H', 'H', 'L', 'O', 'R']),
      Die(['D', 'H', 'L', 'N', 'O', 'R']),
      Die(['D', 'H', 'L', 'N', 'O', 'R']),
      Die(['E', 'I', 'I', 'I', 'T', 'T']),
      Die(['E', 'M', 'O', 'T', 'T', 'T']),
      Die(['E', 'N', 'S', 'S', 'S', 'U']),
      Die(['F', 'I', 'P', 'R', 'S', 'Y']),
      Die(['G', 'O', 'R', 'R', 'V', 'W']),
      Die(['I', 'P', 'R', 'R', 'R', 'Y']),
      Die(['N', 'O', 'O', 'T', 'U', 'W']),
      Die(['O', 'O', 'O', 'T', 'T', 'U']),
    ],
  };

  Dice();

  String roll(int dimension) {
    if (!dice.containsKey(dimension)) { return ''; }
    List<int> indexes = List.generate(min(dimension * dimension, dice[dimension]!.length), (index) => index);
    Random random = Random();
    String result = '';
    dice[dimension]!.shuffle();
    while (indexes.isNotEmpty) {
      int index = random.nextInt(indexes.length);
      result += dice[dimension]![indexes[index]].roll();
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
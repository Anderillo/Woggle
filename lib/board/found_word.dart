import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:woggle/board/word.dart';
import 'package:woggle/utils/utils.dart';

enum FoundWordState {
  IS_POINTS,
  IS_NOT_POINTS,
  IS_NOT_FOUND,
  IS_NOT_WORD,
  IS_TOO_SHORT
}


const Color isPointsColor = Color(0xFF44AF69);
const Color isNotPointsColor = Color(0xFF7286A0);
const Color isNotWordColor = Color(0xFFD90368);
const Color isNotFoundColor = Color(0xFF333138);
const Color isTooShortColor = Color(0xFF333138);

class FoundWord {
  Word word;
  int? numPoints;
  FoundWordState? state;
  FoundWord(this.word);

  void setState(FoundWordState? state) {
    this.state = state;
    if (this.state == FoundWordState.IS_POINTS) { numPoints = getPointsFromWordLength(word.word.length); }
    else { numPoints = 0; }
  }

  Color? getColor() {
    switch (state) {
      case FoundWordState.IS_POINTS: return isPointsColor;
      case FoundWordState.IS_NOT_POINTS: return isNotPointsColor;
      case FoundWordState.IS_NOT_WORD: return isNotWordColor;
      case FoundWordState.IS_NOT_FOUND: return isNotFoundColor;
      case FoundWordState.IS_TOO_SHORT: return isTooShortColor;
      default: return null;
    }
  }
}
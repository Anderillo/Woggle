import 'dart:ui';

import 'package:flutter/material.dart';

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
  String word;
  int? numPoints;
  FoundWordState? state;
  FoundWord(this.word);

  void setState(FoundWordState? state) {
    this.state = state;
    if (this.state == FoundWordState.IS_POINTS) {
      if (word.length < 3) { numPoints = 0; }
      else if (word.length == 3 || word.length == 4) { numPoints = 1; }
      else if (word.length == 5) { numPoints = 2; }
      else if (word.length == 6) { numPoints = 3; }
      else if (word.length == 7) { numPoints = 5; }
      else if (word.length >= 8) { numPoints = 11; }
    }
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
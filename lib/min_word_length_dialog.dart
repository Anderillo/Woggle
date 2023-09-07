import 'package:flutter/material.dart';

class MinWordLengthDialog extends StatelessWidget {
  final int wordLength;
  final Function(int) onChanged;
  const MinWordLengthDialog(this.wordLength, this.onChanged, {super.key});

  @override
  Widget build(BuildContext context) {
    double min = 1;
    double max = 6;
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: wordLength.toDouble(),
            onChanged: (double newWordLength) => onChanged(newWordLength.toInt()),
            min: min,
            max: max,
            label: wordLength.toString(),
            divisions: (max - min).toInt(),
          ),
        ],
      ),
    );
  }
}
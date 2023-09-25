import 'package:flutter/material.dart';

class MinWordLengthDialog extends StatefulWidget {
  final int wordLength;
  final Function(int) onChanged;
  const MinWordLengthDialog(this.wordLength, this.onChanged, {super.key});

  @override
  State<MinWordLengthDialog> createState() => _MinWordLengthDialogState();
}

class _MinWordLengthDialogState extends State<MinWordLengthDialog> {
  late int wordLength;

  @override
  void initState() {
    super.initState();
    wordLength = widget.wordLength;
  }

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
            onChanged: (double newWordLength) {
              setState(() => wordLength = newWordLength.toInt());
              widget.onChanged(wordLength);
            },
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
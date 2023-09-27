import 'package:flutter/material.dart';
import 'package:woggle/board/found_word.dart';
import 'package:woggle/widgets/word_chip.dart';

class VerifiedWords extends StatelessWidget {
  final List<FoundWord>? verifiedWords;
  final int? numWords;
  final Function() onUpdate;
  final Function(String) addWord;
  final Function(String) removeWord;
  const VerifiedWords(this.verifiedWords, this.numWords, this.onUpdate, this.addWord, this.removeWord, {super.key});

  static String getNumVerifiedWords(List<FoundWord>? verifiedWords) {
    return (verifiedWords ?? []).where((word) => word.state == null || word.state == FoundWordState.IS_POINTS || word.state == FoundWordState.IS_NOT_POINTS).length.toString();
  }

  Widget buildWordChip(BuildContext buildContext, FoundWord word) {
    return WordChip(
      word.word,
      wordExtension: word.state == FoundWordState.IS_POINTS ? ': ${word.numPoints}' : null,
      onLongPress: word.state == null || word.state == FoundWordState.IS_POINTS || word.state == FoundWordState.IS_NOT_POINTS ? () {
        showModalBottomSheet(context: buildContext, builder: (BuildContext modalContext) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                child: const Text('Remove from dictionary'),
                onPressed: () {
                  word.setState(FoundWordState.IS_NOT_WORD);
                  onUpdate();
                  removeWord(word.word);
                  Navigator.pop(modalContext);
                },
              ),
            ]
          );
        });
      } : null,
      color: word.getColor(),
      wordStyle: TextStyle(
        decoration: word.state == FoundWordState.IS_NOT_POINTS ? TextDecoration.lineThrough : null,
        decorationThickness: 2,
      ),
      actions: [
        if (word.state == FoundWordState.IS_POINTS || word.state == FoundWordState.IS_NOT_POINTS) ...[
          ChipAction(
            Icons.close_rounded,
            () {
              word.setState(null);
              onUpdate();
            },
          ),
        ],
        if (word.state == null) ...[
          ChipAction(
            Icons.remove_done_rounded,
            () {
              word.setState(FoundWordState.IS_NOT_POINTS);
              onUpdate();
            },
          ),
          ChipAction(
            Icons.check_rounded,
            () {
              word.setState(FoundWordState.IS_POINTS);
              onUpdate();
            },
          ),
        ],
        if (word.state == FoundWordState.IS_NOT_WORD) ...[
          ChipAction(
            Icons.keyboard_capslock_rounded,
            () {
              word.setState(null);
              onUpdate();
              addWord(word.word);
            },
          ),
        ],
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (verifiedWords == null) { return Container(); }
    verifiedWords!.sort((word1, word2) {
      if (word1.state != word2.state) {
        if (word1.state == null) { return -1; }
        else if (word2.state == null) { return 1; }
        else if (word1.state == FoundWordState.IS_POINTS) { return -1; }
        else if (word2.state == FoundWordState.IS_POINTS) { return 1; }
        else if (word1.state == FoundWordState.IS_NOT_POINTS) { return -1; }
        else if (word2.state == FoundWordState.IS_NOT_POINTS) { return 1; }
        else if (word1.state == FoundWordState.IS_NOT_WORD) { return -1; }
        else if (word2.state == FoundWordState.IS_NOT_WORD) { return 1; }
        else if (word1.state == FoundWordState.IS_NOT_FOUND) { return -1; }
        else if (word2.state == FoundWordState.IS_NOT_FOUND) { return 1; }
        else if (word1.state == FoundWordState.IS_TOO_SHORT) { return -1; }
        else if (word2.state == FoundWordState.IS_TOO_SHORT) { return 1; }
      }
      return word1.word.compareTo(word2.word);
    });
    int index = verifiedWords!.indexWhere((word) => [FoundWordState.IS_NOT_WORD, FoundWordState.IS_NOT_FOUND, FoundWordState.IS_TOO_SHORT].contains(word.state));
    if (index < 0) { index = verifiedWords!.length; }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(children: verifiedWords!.sublist(0, index).map((word) => buildWordChip(context, word)).toList()),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total points: ${verifiedWords!.fold(0, (total, word) => total += (word.numPoints == null || word.numPoints == -1 ? 0 : word.numPoints)!.toInt()).toString()}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            if (numWords != null && numWords! > 0) Text(
              '${(verifiedWords!.sublist(0, index).length / numWords! * 100).toStringAsFixed(1)}% of all words',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        const Divider(),
        Wrap(children: verifiedWords!.sublist(index).map((word) => buildWordChip(context, word)).toList()),
        const SizedBox(height: kFloatingActionButtonMargin + 62,),
      ],
    );
  }
}
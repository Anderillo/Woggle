import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:woggle/board/found_word.dart';
import 'package:woggle/board/word.dart';
import 'package:woggle/widgets/word_chip.dart';

class AllWords extends StatelessWidget {
  final List<Word>? workingWords;
  final List<FoundWord>? verifiedWords;
  final Function()? onSearch;
  final Function(String)? removeWord;
  final Function(String) getWord;
  const AllWords(this.workingWords, this.verifiedWords, this.onSearch, this.removeWord, this.getWord, {super.key});

  @override
  Widget build(BuildContext context) {
    if (workingWords == null) {
      if (onSearch != null) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: Theme.of(context).colorScheme.primary),
              onPressed: onSearch,
              child: Text('Search', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            ),
          ),
        );
      }
      return Container();
    }
    else if (workingWords!.isEmpty) { return const Center(child: Text('No words found!'),); }
    else if (workingWords!.isNotEmpty) {
      return Wrap(
        runSpacing: kIsWeb ? 12 : 0,
        children: workingWords!.map((word) {
          FoundWord? foundWord = verifiedWords?.firstWhereOrNull((verifiedWord) => verifiedWord.word.word == word.word);
          Color? backgroundColor = Colors.grey[700];
          if (foundWord != null) {
            if (foundWord.state == null || foundWord.state == FoundWordState.IS_POINTS) { backgroundColor = isPointsColor; }
            else if (foundWord.state == FoundWordState.IS_NOT_POINTS) { backgroundColor = isNotPointsColor; }
          }
          return WordChip(
            word,
            onLongPress: removeWord != null ? () {
              showModalBottomSheet(context: context, builder: (BuildContext modalContext) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      child: const Text('Remove from dictionary'),
                      onPressed: () {
                        removeWord!(word.word);
                        Navigator.pop(modalContext);
                      },
                    ),
                  ]
                );
              });
            } : null,
            color: backgroundColor,
            getWord: getWord,
          );
        }).toList(),
      );
    }
    return Container();
  }
}
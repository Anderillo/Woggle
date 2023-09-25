import 'package:boggle_solver/board/found_word.dart';
import 'package:boggle_solver/dialogs/definition_dialog.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class AllWords extends StatelessWidget {
  final List<String>? workingWords;
  final List<FoundWord>? verifiedWords;
  final Function()? onSearch;
  final Function(String)? removeWord;
  const AllWords(this.workingWords, this.verifiedWords, this.onSearch, this.removeWord, {super.key});

  @override
  Widget build(BuildContext context) {
    if (workingWords == null) {
      if (onSearch != null) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(elevation: 0),
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
        children: workingWords!.map((word) {
          FoundWord? foundWord = verifiedWords?.firstWhereOrNull((verifiedWord) => verifiedWord.word == word);
          Color? backgroundColor = Colors.grey[700];
          if (foundWord != null) {
            if (foundWord.state == null || foundWord.state == FoundWordState.IS_POINTS) { backgroundColor = isPointsColor; }
            else if (foundWord.state == FoundWordState.IS_NOT_POINTS) { backgroundColor = isNotPointsColor; }
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Chip(
              label: InkWell(
                onTap: () => showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) => DefinitionDialog(word),
                ),
                child: Text(word),
              ),
              deleteIcon: Icon(
                Icons.close_rounded,
                color: removeWord != null ? Theme.of(context).canvasColor : Theme.of(context).dividerColor,
              ),
              onDeleted: removeWord != null ? () => removeWord!(word) : null,
              backgroundColor: backgroundColor,
            ),
          );
        }).toList(),
      );
    }
    return Container();
  }
}
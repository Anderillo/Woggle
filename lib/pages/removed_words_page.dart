import 'package:boggle_solver/widgets/word_chip.dart';
import 'package:flutter/material.dart';

class RemovedWordsPage extends StatefulWidget {
  final Set<String> removedWords;
  final Function(String) unRemove;
  const RemovedWordsPage(this.removedWords, this.unRemove, {super.key});

  @override
  State<RemovedWordsPage> createState() => _RemovedWordsPageState();
}

class _RemovedWordsPageState extends State<RemovedWordsPage> {
  late Set<String> removedWords;
  @override
  void initState() {
    super.initState();
    removedWords = widget.removedWords;
  }

  @override
  Widget build(BuildContext context) {
    List<String> workingRemovedWords = [...removedWords];
    workingRemovedWords.sort();
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Removed Words'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              children: workingRemovedWords.map((word) => WordChip(
                word,
                actions: [
                  ChipAction(
                    Icons.rotate_left_rounded,
                    () {
                      setState(() => removedWords.remove(word));
                      widget.unRemove(word);
                    },
                  ),
                ],
              )).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
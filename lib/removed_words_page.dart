import 'package:flutter/material.dart';

class RemovedWordsPage extends StatefulWidget {
  final Set<String> removedWords;
  final Function(String) unRemove;
  const RemovedWordsPage(this.removedWords, this.unRemove, {super.key});

  @override
  State<RemovedWordsPage> createState() => _RemovedWordsPageState();
}

class _RemovedWordsPageState extends State<RemovedWordsPage> {
  @override
  Widget build(BuildContext context) {
    List<String> workingRemovedWords = [...widget.removedWords];
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
              children: workingRemovedWords.map((word) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Chip(
                  label: Text(word),
                  deleteIcon: Icon(
                    Icons.rotate_left_rounded,
                    color: Theme.of(context).canvasColor,
                  ),
                  onDeleted: () => widget.unRemove(word),
                  backgroundColor: Colors.grey[700],
                ),
              )).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
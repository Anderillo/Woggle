import 'package:boggle_solver/widgets/word_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DictionaryModificationsPage extends StatefulWidget {
  final Set<String> addedWords;
  final Function(String) removeWord;
  final Set<String> removedWords;
  final Function(String) addWord;
  const DictionaryModificationsPage(this.addedWords, this.removeWord, this.removedWords, this.addWord, {super.key});

  @override
  State<DictionaryModificationsPage> createState() => _DictionaryModificationsPageState();
}

class _DictionaryModificationsPageState extends State<DictionaryModificationsPage> {
  late Set<String> addedWords;
  late Set<String> removedWords;
  TextEditingController addWordsTextEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    addedWords = {...widget.addedWords};
    removedWords = {...widget.removedWords};
  }

  Widget buildAddedWordsTab() {
    List<String> workingAddedWords = [...addedWords];
    workingAddedWords.sort();
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              autofocus: false,
              controller: addWordsTextEditingController,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]'))],
              decoration: InputDecoration(
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(25))),
                hintText: 'Type new word',
                isDense: true,
                suffixIcon: IconButton(
                  onPressed: () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    String word = addWordsTextEditingController.text.trim().toLowerCase();
                    addWordsTextEditingController.clear();
                    bool isAdded = await widget.addWord(word);
                    if (isAdded) { setState(() => addedWords.add(word)); }
                    else { setState(() => removedWords.remove(word)); }
                  },
                  icon: const Icon(Icons.add_rounded, size: 22),
                ),
              ),
              onChanged: (String newString) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Wrap(
              children: workingAddedWords.map((word) => WordChip(
                word,
                actions: [
                  ChipAction(
                    Icons.remove_circle_outline_rounded,
                    () {
                      setState(() => addedWords.remove(word));
                      widget.removeWord(word);
                    },
                  ),
                ],
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRemovedWordsTab() {
    List<String> workingRemovedWords = [...removedWords];
    workingRemovedWords.sort();
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          children: workingRemovedWords.map((word) => WordChip(
            word,
            actions: [
              ChipAction(
                Icons.control_point_rounded,
                () {
                  setState(() => removedWords.remove(word));
                  widget.addWord(word);
                },
              ),
            ],
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Dictionary'),
      ),
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: 'Added Words (${addedWords.length})'),
                  Tab(text: 'Removed Words (${removedWords.length})'),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    buildAddedWordsTab(),
                    buildRemovedWordsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
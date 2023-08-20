import 'dart:math';

import 'package:boggle_solver/board/board.dart';
import 'package:boggle_solver/definition_dialog.dart';
import 'package:boggle_solver/dictionary/dictionary.dart';
import 'package:boggle_solver/removed_words_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

const int MIN_WORD_LENGTH_DEFAULT = 4;
class _MainAppState extends State<MainApp> {
  Dictionary dictionary = Dictionary();
  bool isDictionaryLoaded = false;
  Board? board;
  Set<String>? words;
  TextEditingController controller = TextEditingController();
  String boardString = '';
  bool get isSearchAvailable => isDictionaryLoaded && boardString.isNotEmpty && sqrt(boardString.replaceAll('qu', 'q').length).truncate() == sqrt(boardString.replaceAll('qu', 'q').length);
  Set<String>? removedWords;
  SharedPreferences? prefs;
  int minWordLength = MIN_WORD_LENGTH_DEFAULT;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    removedWords = {};
    removedWords!.addAll(prefs!.getStringList('removedWords')?.toList() ?? []);
    minWordLength = prefs!.getInt('minWordLength') ?? MIN_WORD_LENGTH_DEFAULT;
    setState(() {});
    
    String dictionaryFile = await DefaultAssetBundle.of(context).loadString('assets/dictionary.txt');
    for (String word in dictionaryFile.split('\n')) { if (!(removedWords!.contains(word.toLowerCase().trim()))) { dictionary.addWord(word); } }
    setState(() => isDictionaryLoaded = true);
  }

  Future<void> removeWord(String word) async {
    if (removedWords != null) {
      words?.remove(word);
      setState(() {});
      prefs ??= await SharedPreferences.getInstance();
      removedWords!.add(word);
      prefs!.setStringList('removedWords', removedWords!.toList());
    }
  }

  Future<void> unRemoveWord(String word) async {
    if (removedWords != null) {
      removedWords!.remove(word);
      dictionary.addWord(word);
      words = board!.search(dictionary);
      setState(() {});
      prefs ??= await SharedPreferences.getInstance();
      prefs!.setStringList('removedWords', removedWords!.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String>? workingWords;
    if (words != null) {
      workingWords = [...words!.toList()];
      workingWords.removeWhere((word) => removedWords?.contains(word) ?? false);
    }

    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              title: const Text('Boggle Solver'),
              actions: [
                TextButton(
                  onPressed: removedWords?.isNotEmpty ?? false ? () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => RemovedWordsPage(removedWords!, unRemoveWord)));
                  } : null,
                  child: Text(
                    'Removed Words',
                    style: TextStyle(color: removedWords?.isNotEmpty ?? false ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).disabledColor),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        textAlign: TextAlign.center,
                        controller: controller,
                        onChanged: (String newString) => setState(() {
                          boardString = newString;
                          words = null;
                        }),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.width - 120,
                        width: MediaQuery.of(context).size.width - 120,
                        child: buildBoard(context),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(workingWords == null ? '' : workingWords.isEmpty ? 'No words found!' : 'Total words: ${workingWords.length}'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text('Min word length: '),
                              DropdownButton(
                                value: minWordLength,
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text('1')),
                                  DropdownMenuItem(value: 2, child: Text('2')),
                                  DropdownMenuItem(value: 3, child: Text('3')),
                                  DropdownMenuItem(value: 4, child: Text('4')),
                                  DropdownMenuItem(value: 5, child: Text('5')),
                                  DropdownMenuItem(value: 6, child: Text('6')),
                                ],
                                onChanged: (value) async {
                                  minWordLength = value ?? MIN_WORD_LENGTH_DEFAULT;
                                  if (words != null) {
                                    board = Board(boardString, minWordLength);
                                    words = board!.search(dictionary);
                                  }
                                  setState(() {});

                                  prefs ??= await SharedPreferences.getInstance();
                                  prefs!.setInt('minWordLength', minWordLength);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (workingWords?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 20,),
                        Wrap(
                          children: workingWords!.map((word) => Padding(
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
                                color: removedWords != null ? Theme.of(context).disabledColor : Theme.of(context).dividerColor,
                              ),
                              onDeleted: () => removeWord(word),
                            ),
                          )).toList(),
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            floatingActionButton: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isSearchAvailable ? () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    board = Board(boardString, minWordLength);
                    words = board!.search(dictionary);
                    setState(() {});
                  } : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    color: Theme.of(context).canvasColor,
                    child: const Text('Search'),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget buildBoard(BuildContext context) {
    int dimension = sqrt(max(boardString.replaceAll('qu', 'q').length, 1)).ceil();
    List<String> letters = boardString.toLowerCase().split('');
    for (int i = 0; i < letters.length; i++) {
      if (letters[i] == 'q' && i + 1 < letters.length && letters[i + 1] == 'u') {
        letters[i] = 'qu';
        letters.removeAt(i + 1);
      }
    }

    return GridView.count(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: dimension,
      children: letters.map((letter) => Center(
        child: Text(
          letter,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      )).toList(),
    );
  }
}

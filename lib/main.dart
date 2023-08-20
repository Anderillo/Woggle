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

class _MainAppState extends State<MainApp> {
  Dictionary dictionary = Dictionary();
  bool isDictionaryLoaded = false;
  Board? board;
  Set<String> words = {};
  TextEditingController controller = TextEditingController();
  String boardString = '';
  bool get isSearchAvailable => isDictionaryLoaded && boardString.isNotEmpty && sqrt(boardString.length).truncate() == sqrt(boardString.length);
  Set<String>? removedWords;
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    removedWords = {};
    removedWords!.addAll(prefs!.getStringList('removedWords')?.toList() ?? []);
    setState(() {});
    
    String dictionaryFile = await DefaultAssetBundle.of(context).loadString('assets/dictionary.txt');
    for (String word in dictionaryFile.split('\n')) { if (!(removedWords!.contains(word.toLowerCase().trim()))) { dictionary.addWord(word); } }
    setState(() => isDictionaryLoaded = true);
  }

  Future<void> removeWord(String word) async {
    if (removedWords != null) {
      words.remove(word);
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
    List<String> workingWords = [...words.toList()];
    workingWords.removeWhere((word) => removedWords?.contains(word) ?? false);

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
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              textAlign: TextAlign.center,
                              controller: controller,
                              onChanged: (String newString) => setState(() {
                                boardString = newString;
                                words = {};
                              }),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.width,
                        width: MediaQuery.of(context).size.width,
                        child: buildBoard(context),
                      ),
                      if (workingWords.isNotEmpty) ...[
                        Text('Total words: ${workingWords.length}'),
                        const SizedBox(height: 20,),
                        Wrap(
                          children: workingWords.map((word) => Padding(
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
                    board = Board(boardString, 4);
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
    int dimension = sqrt(max(boardString.length, 1)).ceil();
    return GridView.count(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: dimension,
      children: List.generate(boardString.length, (index) {
        return Center(
          child: Text(
            boardString[index],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        );
      }),
    );
  }
}

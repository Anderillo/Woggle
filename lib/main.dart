import 'dart:async';
import 'dart:math';

import 'package:boggle_solver/board/board.dart';
import 'package:boggle_solver/board/dice.dart';
import 'package:boggle_solver/definition_dialog.dart';
import 'package:boggle_solver/dictionary/dictionary.dart';
import 'package:boggle_solver/min_word_length_dialog.dart';
import 'package:boggle_solver/removed_words_page.dart';
import 'package:boggle_solver/utils.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

const int MIN_WORD_LENGTH_DEFAULT = 3;
const int NUM_SECONDS = 180;
class _MainAppState extends State<MainApp> {
  Dictionary dictionary = Dictionary();
  bool isDictionaryLoaded = false;
  Board? board;
  Set<String>? words;
  TextEditingController boardStringController = TextEditingController();
  TextEditingController myWordsController = TextEditingController();
  String boardString = '';
  bool get isSearchAvailable => isDictionaryLoaded && boardString.isNotEmpty && sqrt(boardString.replaceAll('QU', 'Q').length).truncate() == sqrt(boardString.replaceAll('QU', 'Q').length);
  Set<String>? removedWords;
  SharedPreferences? prefs;
  int minWordLength = MIN_WORD_LENGTH_DEFAULT;
  late Dice dice;

  Timer? timer;
  int numSeconds = NUM_SECONDS;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    dice = Dice(4);
    prefs = await SharedPreferences.getInstance();
    removedWords = {};
    removedWords!.addAll(prefs!.getStringList('removedWords')?.toList() ?? []);
    minWordLength = prefs!.getInt('minWordLength') ?? MIN_WORD_LENGTH_DEFAULT;
    setState(() {});
    
    String dictionaryFile = await DefaultAssetBundle.of(context).loadString('assets/dictionary.txt');
    for (String word in dictionaryFile.split('\n')) { if (!(removedWords!.contains(word.toLowerCase().trim()))) { dictionary.addWord(word); } }
    setState(() => isDictionaryLoaded = true);
  }

  void startTimer(BuildContext buildContext) {
    setState(() => numSeconds = NUM_SECONDS);
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (numSeconds == 0) {
          setState(() {
            timer.cancel();
            this.timer = null;
          });
          showDialog(context: buildContext, builder: (BuildContext dialogContext) => AlertDialog(
            content: const Text('Time\'s up!'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Okei'))],
          ));
        }
        else { setState(() => numSeconds--); }
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
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
      if (words != null) { words = board!.search(dictionary); }
      setState(() {});
      prefs ??= await SharedPreferences.getInstance();
      prefs!.setStringList('removedWords', removedWords!.toList());
    }
  }

  String generate() {
    FocusManager.instance.primaryFocus?.unfocus();
    words = null;
    return dice.roll();
  }

  Widget buildMyWordsTab() {
    return const TextField(
      keyboardType: TextInputType.multiline,
      maxLines: 12,
    );
  }

  Widget buildAllWordsTab(BuildContext buildContext, List<String>? workingWords) {
    if (workingWords == null) {
      if (isSearchAvailable) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(elevation: 0),
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                board = Board(boardString, minWordLength);
                words = board!.search(dictionary);
                setState(() {});
              },
              child: Text('Search', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            ),
          ),
        );
      }
      return Container();
    }
    else if (workingWords.isEmpty) { return const Center(child: Text('No words found!'),); }
    else if (workingWords.isNotEmpty) {
      return Wrap(
        children: workingWords.map((word) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Chip(
            label: InkWell(
              onTap: () => showDialog(
                context: buildContext,
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
      );
    }
    return Container();
  }

  List<PopupMenuItem<String>> getAppBarActions(BuildContext buildContext) {
    return [
      if (boardString == '' || isSearchAvailable) PopupMenuItem<String>(
        value: 'New Game',
        onTap: () async {
          FocusManager.instance.primaryFocus?.unfocus();
          String generatedString = boardString;
          if (generatedString == '') {
            generatedString = generate();
            boardString = generatedString;
          }
          int dimension = sqrt(max(generatedString.replaceAll('QU', 'Q').length, 1)).ceil();
          String toShare = '\n\n\n';
          for (int i = 0; i < generatedString.length; i++) {
            String letter = generatedString[i];
            if (i < generatedString.length - 1 && generatedString[i] == 'Q' && generatedString[i + 1] == 'U') {
              letter += generatedString[i + 1];
              generatedString = generatedString.substring(0, i + 1) + generatedString.substring(i + 2);
            }
            toShare += EMOJI_ICONS[letter]!;
            if ((i + 1) % dimension == 0 && i < generatedString.length - 1) { toShare += '\n\n'; }
          }
          await Share.shareWithResult(toShare, subject: 'Boggle Board');
          boardStringController.text = boardString;
          // ignore: use_build_context_synchronously
          startTimer(buildContext);
          setState(() {});
        },
        child: const Text('New Game'),
      ),
      PopupMenuItem<String>(
        value: 'Min Word Length',
        child: Text('Min Word Length: $minWordLength'),
        onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) => showDialog(
          context: buildContext,
          builder: (BuildContext dialogContext) => MinWordLengthDialog(
            minWordLength,
            (value) async {
              minWordLength = value;
              if (words != null) {
                board = Board(boardString, minWordLength);
                words = board!.search(dictionary);
              }
              setState(() {});
        
              prefs ??= await SharedPreferences.getInstance();
              prefs!.setInt('minWordLength', minWordLength);
            },
          )),
        ),
      ),
      if (removedWords?.isNotEmpty ?? false) const PopupMenuItem<String>(
        value: 'Removed Words',
        child: Text('Removed Words'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    List<String>? workingWords;
    if (words != null) {
      workingWords = [...words!.toList()];
      workingWords.removeWhere((word) => removedWords?.contains(word) ?? false);
    }

    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC35500),
          brightness: Brightness.dark,
          primary: const Color(0xFFC35500),
          secondary: const Color(0xFF023A6A),
          onPrimary: const Color(0xFFC35500),
          onSecondary: Colors.white,
        ),
      ),
      home: Builder(
        builder: (builderContext) {
          List<PopupMenuItem<String>> appBarActions = getAppBarActions(builderContext);
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              title: const Text('Boggle Solver'),
              actions: [
                PopupMenuButton<String>(
                  enabled: appBarActions.isNotEmpty,
                  onSelected: (String result) {
                    if (result == 'Removed Words') { Navigator.push(builderContext, MaterialPageRoute(builder: (context) => RemovedWordsPage(removedWords!, unRemoveWord))); }
                  },
                  itemBuilder: (BuildContext context) => appBarActions,
                ),
              ],
            ),
            body: SafeArea(
              child: Container(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: Column(
                  children: [
                    Row(
                        children: [
                          TextButton(
                            onPressed: null,
                            child: Text(
                              timer != null ? '${numSeconds ~/ 60}:${(numSeconds % 60).toString().padLeft(2, '0')}' : '    ',
                              style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              textAlign: TextAlign.center,
                              controller: boardStringController,
                              inputFormatters: [UpperCaseTextFormatter()],
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'Enter the board',
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    FocusManager.instance.primaryFocus?.unfocus();
                                    boardStringController.clear();
                                    myWordsController.clear();
                                    setState(() {
                                      boardString = '';
                                      words = null;
                                      timer?.cancel();
                                      timer = null;
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                              ),
                              onChanged: (String newString) => setState(() {
                                boardString = newString.toUpperCase();
                                words = null;
                                timer?.cancel();
                                timer = null;
                              }),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              boardString = generate();
                              boardStringController.text = boardString;
                              myWordsController.clear();
                              words = null;
                              setState(() {});
                            },
                            icon: const Icon(Icons.restart_alt_rounded),
                          ),
                        ],
                      ),
                      Expanded(child: buildBoard()),
                      Expanded(child: buildTabs(builderContext, workingWords)),
                  ]
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget buildBoard() {
    List<String> letters = boardString.toUpperCase().split('');
    int dimension = sqrt(max(boardString.replaceAll('QU', 'Q').length, 1)).ceil();
    for (int i = 0; i < letters.length; i++) {
      if (letters[i] == 'Q' && i + 1 < letters.length && letters[i + 1] == 'U') {
        letters[i] = 'QU';
        letters.removeAt(i + 1);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;

        return SizedBox(
          height: availableHeight,
          width: availableHeight,
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: dimension,
            children: letters.map((letter) => Center(
              child: Text(
                letter,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            )).toList(),
          ),
        );
      },
    );
  }

  Widget buildTabs(BuildContext buildContext, List<String>? workingWords) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              const Tab(text: 'My Words'),
              Tab(text: 'All Words${workingWords == null ? '' : ' (${workingWords.length})'}'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  key: const PageStorageKey('myWords'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      key: const PageStorageKey('myWordsTextField'),
                      controller: myWordsController,
                      keyboardType: TextInputType.multiline,
                      minLines: 2,
                      maxLines: null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter words...',
                        isDense: true,
                      ),
                      enableSuggestions: false,
                      autocorrect: false,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  key: const PageStorageKey('allWords'),
                  child: buildAllWordsTab(buildContext, workingWords),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

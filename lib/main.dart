import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:boggle_solver/board/board.dart';
import 'package:boggle_solver/board/dice.dart';
import 'package:boggle_solver/definition_dialog.dart';
import 'package:boggle_solver/dictionary/dictionary.dart';
import 'package:boggle_solver/found_word.dart';
import 'package:boggle_solver/join_game_dialog.dart';
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
class _MainAppState extends State<MainApp> with TickerProviderStateMixin {
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

  late TabController tabController;
  bool userIsFindingWords = true;
  List<FoundWord>? verifiedWords;
  bool hasUnRemovedWord = false;

  @override
  void initState() {
    super.initState();
    init();
    tabController = TabController(
      initialIndex: 0,
      length: 2,
      vsync: this,
    )..addListener(() {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {});
    });
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
          FocusManager.instance.primaryFocus?.unfocus();
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
    userIsFindingWords = true;
    verifiedWords = null;
    return dice.roll();
  }

  Widget buildMyWordsTab() {
    return const TextField(
      keyboardType: TextInputType.multiline,
      maxLines: 12,
    );
  }

  Widget buildChipAction(BuildContext buildContext, IconData icon, Function() onTap) {
    double iconSize = 22;
    return InkWell(
      radius: iconSize * 0.45,
      onTap: onTap,
      child: Icon(
        icon,
        size: iconSize,
        color: Theme.of(buildContext).canvasColor,
      ),
    );
  }

  Widget buildWordChip(BuildContext buildContext, FoundWord word) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () => showDialog(
          context: buildContext,
          builder: (BuildContext dialogContext) => DefinitionDialog(word.word),
        ),
        onLongPress: word.state == null || word.state == FoundWordState.IS_POINTS || word.state == FoundWordState.IS_NOT_POINTS ? () {
          showModalBottomSheet(context: buildContext, builder: (BuildContext modalContext) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  child: const Text('Mark as fake word'),
                  onPressed: () {
                    setState(() => word.setState(FoundWordState.IS_NOT_WORD));
                    if (dictionary.hasWord(word.word).isWord) { removeWord(word.word); }
                    Navigator.pop(modalContext);
                  },
                ),
              ]
            );
          });
        } : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: word.getColor() ?? Colors.grey[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${word.word}${word.state == FoundWordState.IS_POINTS ? ': ${word.numPoints}' : ''}',
              style: TextStyle(
                color: Theme.of(buildContext).textTheme.bodyMedium?.color,
                decoration: word.state == FoundWordState.IS_NOT_POINTS ? TextDecoration.lineThrough : null,
                decorationThickness: 2,
              ),
            ),
            const SizedBox(width: 4),
            if (word.state == FoundWordState.IS_POINTS || word.state == FoundWordState.IS_NOT_POINTS) ...[
              const SizedBox(width: 4),
              buildChipAction(
                buildContext,
                Icons.close_rounded,
                () => setState(() => word.setState(null)),
              ),
            ],
            if (word.state == null) ...[
              const SizedBox(width: 4),
              buildChipAction(
                buildContext,
                Icons.remove_done_rounded,
                () => setState(() => word.setState(FoundWordState.IS_NOT_POINTS)),
              ),
              const SizedBox(width: 4),
              buildChipAction(
                buildContext,
                Icons.done_all_rounded,
                () => setState(() => word.setState(FoundWordState.IS_POINTS)),
              ),
            ],
            if (word.state == FoundWordState.IS_NOT_WORD) ...[
              const SizedBox(width: 4),
              buildChipAction(
                buildContext,
                Icons.keyboard_capslock_rounded,
                () {
                  setState(() => word.setState(null));
                  if (removedWords?.contains(word.word) ?? false) { unRemoveWord(word.word); }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildVerifiedWords(BuildContext buildContext) {
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
        else if (word1.state == FoundWordState.TOO_SHORT) { return -1; }
        else if (word2.state == FoundWordState.TOO_SHORT) { return 1; }
      }
      return word1.word.compareTo(word2.word);
    });
    int index = verifiedWords!.indexWhere((word) => [FoundWordState.IS_NOT_WORD, FoundWordState.IS_NOT_FOUND, FoundWordState.TOO_SHORT].contains(word.state));
    if (index < 0) { index = verifiedWords!.length; }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Wrap(children: verifiedWords!.sublist(0, index).map((word) => buildWordChip(buildContext, word)).toList()),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total points: ${verifiedWords!.fold(0, (total, word) => total += (word.numPoints == null || word.numPoints == -1 ? 0 : word.numPoints)!.toInt()).toString()}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (words != null && words!.isNotEmpty) Text(
              '${(verifiedWords!.sublist(0, index).length / words!.length * 100).toStringAsFixed(1)}% of all words',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const Divider(),
        Wrap(children: verifiedWords!.sublist(index).map((word) => buildWordChip(buildContext, word)).toList()),
        const SizedBox(height: kFloatingActionButtonMargin + 62,),
      ],
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
              color: removedWords != null ? Theme.of(buildContext).canvasColor : Theme.of(context).dividerColor,
            ),
            onDeleted: () => removeWord(word),
            backgroundColor: Colors.grey[700],
          ),
        )).toList(),
      );
    }
    return Container();
  }

  Future<void> startGame(BuildContext buildContext, {Function(String)? shareAction, String? existingBoardString}) async {
    String generatedString = existingBoardString ?? generate();
    boardString = generatedString;
    if (shareAction != null) { await shareAction(generatedString); }
    boardStringController.text = boardString;
    // ignore: use_build_context_synchronously
    startTimer(buildContext);
    setState(() {});
  }

  List<PopupMenuItem<String>> getAppBarActions(BuildContext buildContext) {
    return [
      PopupMenuItem<String>(
        value: 'New Game',
        onTap: () async {
          FocusManager.instance.primaryFocus?.unfocus();
          WidgetsBinding.instance.addPostFrameCallback((_) => showDialog(
            context: buildContext,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Start game with'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.people_rounded),
                      title: const Text('Boggle Solver users'),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        startGame(buildContext, shareAction: (String generatedString) async {
                          String toShare = await boardSecrets(generatedString, encrypt: true);
                          await Share.shareWithResult(toShare, subject: 'Boggle Board');
                        });
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_outline_rounded),
                      title: const Text('Non Boggle Solver users'),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        startGame(buildContext, shareAction: (String generatedString) async {
                          String toShare = '\n\n\n${convertStringToEmojis(generatedString)}';
                          await Share.shareWithResult(toShare, subject: 'Boggle Board');
                        });
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.diversity_3_rounded),
                      title: const Text('Mixed users'),
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        startGame(buildContext, shareAction: (String generatedString) async {
                          String toShareEncrypted = await boardSecrets(generatedString, encrypt: true);
                          await Share.shareWithResult(toShareEncrypted, subject: 'Boggle Board');
                          String toShare = '\n\n\n${convertStringToEmojis(generatedString)}';
                          await Share.shareWithResult(toShare, subject: 'Boggle Board');
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ));
        },
        child: const Text('New Game'),
      ),
      PopupMenuItem<String>(
        value: 'Join Game',
        onTap: () async {
          FocusManager.instance.primaryFocus?.unfocus();
          WidgetsBinding.instance.addPostFrameCallback((_) => showDialog(
            context: buildContext,
            builder: (BuildContext dialogContext) => JoinGameDialog((String decryptedString) => startGame(buildContext, existingBoardString: decryptedString)),
          ));
        },
        child: const Text('Join Game'),
      ),
      if (boardString != '') PopupMenuItem<String>(
        value: 'Share Board',
        onTap: () async {
          FocusManager.instance.primaryFocus?.unfocus();
          String toShare = '\n\n\n${convertStringToEmojis(boardString)}';
          await Share.shareWithResult(toShare, subject: 'Boggle Board');
        },
        child: const Text('Share Board'),
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
              setState(() {});
        
              prefs ??= await SharedPreferences.getInstance();
              prefs!.setInt('minWordLength', minWordLength);
            },
          )).then((value) {
            if (words != null) {
              board = Board(boardString, minWordLength);
              words = board!.search(dictionary);
            }
            if (!userIsFindingWords && verifiedWords != null) {
              for (var verifiedWord in verifiedWords!) {
                if (verifiedWord.state == null && verifiedWord.word.length < minWordLength) {
                  verifiedWord.setState(FoundWordState.TOO_SHORT);
                }
                else if (verifiedWord.state == FoundWordState.TOO_SHORT && verifiedWord.word.length >= minWordLength) {
                  verifiedWord.setState(null);
                }
              }
            }
            setState(() {});
          }),
        ),
      ),
      if (removedWords?.isNotEmpty ?? false) const PopupMenuItem<String>(
        value: 'Removed Words',
        child: Text('Removed Words'),
      ),
    ];
  }

  Future<void> verifyWords(BuildContext buildContext) async {
    showLoader(buildContext);
    List<String> myWords = myWordsController.text.trim().split('\n');
    List<FoundWord> foundWords = [];
    Dictionary tempDictionary = Dictionary();
    for (int i = 0; i < myWords.length; i++) {
      List<String> wordsToAdd = [];

      String currentWord = myWords[i];
      while (currentWord.split('/').length > 1) {
        wordsToAdd.add(currentWord.split('/')[0].trim());
        currentWord = currentWord.replaceFirst('/', '');
      }
      wordsToAdd.add(currentWord.trim());

      for (String word in wordsToAdd) {
        foundWords.add(FoundWord(word));
        tempDictionary.addWord(word);
      }
    }
    Set<String> searchedWords = Board(boardString, 1).search(tempDictionary);
    for (int i = 0; i < foundWords.length; i++) {
      if (!searchedWords.contains(foundWords[i].word)) {
        foundWords[i].setState(FoundWordState.IS_NOT_FOUND);
      }
      else {
        await getDefinition(foundWords[i].word).then((String definition) {}).catchError((error) {
          if (error is TimeoutException || error is SocketException) {
            if (!dictionary.hasWord(foundWords[i].word).isWord) { foundWords[i].setState(FoundWordState.IS_NOT_WORD); }
          }
          else { foundWords[i].setState(FoundWordState.IS_NOT_WORD); }
        });
      }
      if (foundWords[i].state == null && foundWords[i].word.length < minWordLength) { foundWords[i].setState(FoundWordState.TOO_SHORT); }
    }

    if (words == null) {
      board = Board(boardString, minWordLength);
      words = board!.search(dictionary);
    }

    setState(() => verifiedWords = foundWords);
    hideLoader();
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
                    if (result == 'Removed Words') {
                      Navigator.push(builderContext, MaterialPageRoute(builder: (context) => RemovedWordsPage(
                        removedWords!,
                        (String word) {
                          unRemoveWord(word);
                          hasUnRemovedWord = true;
                        }))
                      ).then((value) {
                        if (!userIsFindingWords && hasUnRemovedWord) {
                          verifyWords(builderContext);
                          hasUnRemovedWord = false;
                        }
                      });
                    }
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
                                      userIsFindingWords = true;
                                      verifiedWords = null;
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
            floatingActionButton: myWordsController.text.isNotEmpty && MediaQuery.of(context).viewInsets.bottom == 0 && tabController.index == 0 ? FloatingActionButton(
              elevation: 0,
              onPressed: userIsFindingWords ? () {
                verifyWords(builderContext);
                setState(() => userIsFindingWords = false);
              } : () {
                verifiedWords = null;
                setState(() => userIsFindingWords = true);
              },
              child: Icon(userIsFindingWords ? Icons.check_rounded : Icons.edit_outlined),
            ) : null,
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
    return Column(
      children: [
        TabBar(
          controller: tabController,
          tabs: [
            const Tab(text: 'My Words'),
            Tab(text: 'All Words${workingWords == null ? '' : ' (${workingWords.length})'}'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              SingleChildScrollView(
                key: const PageStorageKey('myWords'),
                child: userIsFindingWords ? Container(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    key: const PageStorageKey('myWordsTextField'),
                    controller: myWordsController,
                    keyboardType: TextInputType.multiline,
                    onChanged: (String word) => setState(() {}),
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
                ) : buildVerifiedWords(buildContext),
              ),
              SingleChildScrollView(
                key: const PageStorageKey('allWords'),
                child: buildAllWordsTab(buildContext, workingWords),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

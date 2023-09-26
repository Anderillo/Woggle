import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:boggle_solver/board/board.dart';
import 'package:boggle_solver/board/dice.dart';
import 'package:boggle_solver/board/found_word.dart';
import 'package:boggle_solver/dialogs/join_game_dialog.dart';
import 'package:boggle_solver/dialogs/min_word_length_dialog.dart';
import 'package:boggle_solver/dictionary/dictionary.dart';
import 'package:boggle_solver/pages/dictionary_modifications_page.dart';
import 'package:boggle_solver/utils/constants.dart';
import 'package:boggle_solver/utils/utils.dart';
import 'package:boggle_solver/widgets/all_words.dart';
import 'package:boggle_solver/widgets/verified_words.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  late Dictionary dictionary;
  bool isDictionaryLoaded = false;
  Board? board;
  Set<String>? words;
  TextEditingController boardStringController = TextEditingController();
  TextEditingController myWordsController = TextEditingController();
  String boardString = '';
  bool get isSearchAvailable => isDictionaryLoaded && boardString.isNotEmpty && sqrt(boardString.replaceAll('QU', 'Q').length).truncate() == sqrt(boardString.replaceAll('QU', 'Q').length);
  late Set<String> addedWords;
  late Set<String> removedWords;
  SharedPreferences? prefs;
  int minWordLength = Constants.MIN_WORD_LENGTH_DEFAULT;
  late Dice dice;

  Timer? timer;
  int numSeconds = Constants.NUM_SECONDS;

  late TabController tabController;
  bool userIsFindingWords = true;
  List<FoundWord>? verifiedWords;
  bool hasModifiedDictionary = false;
  int? boardDimension;

  @override
  void initState() {
    super.initState();
    dictionary = Dictionary(
      isWordAdded: (word) => addedWords.contains(word),
      isWordRemoved: (word) => removedWords.contains(word),
    );
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
    dice = Dice();
    addedWords = {};
    removedWords = {};
    prefs = await SharedPreferences.getInstance();
    addedWords.addAll(prefs!.getStringList('addedWords')?.toList() ?? []);
    removedWords.addAll(prefs!.getStringList('removedWords')?.toList() ?? []);
    minWordLength = prefs!.getInt('minWordLength') ?? Constants.MIN_WORD_LENGTH_DEFAULT;
    boardDimension = prefs!.getInt('boardDimension') ?? Constants.BOARD_DIMENSION_DEFAULT;
    setState(() {});
    generate(shouldUpdateUI: true);
    
    // ignore: use_build_context_synchronously
    String dictionaryFile = await DefaultAssetBundle.of(context).loadString('assets/dictionary.txt');
    for (String word in dictionaryFile.split('\n')) { dictionary.addWord(word); }
    setState(() => isDictionaryLoaded = true);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (numSeconds == 0) {
          setState(() {
            timer.cancel();
            this.timer = null;
          });
          FocusManager.instance.primaryFocus?.unfocus();
          showDialog(context: context, builder: (BuildContext dialogContext) => AlertDialog(
            content: const Text('Time\'s up!'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Okei'))],
          ));
        }
        else { setState(() => numSeconds--); }
      },
    );
  }

  Future<void> addWord(String word) async {
    prefs ??= await SharedPreferences.getInstance();
    if (removedWords.contains(word)) {
      removedWords.remove(word);
      prefs!.setStringList('removedWords', removedWords.toList());
    }
    else {
      addedWords.add(word);
      prefs!.setStringList('addedWords', addedWords.toList());
    }
    if (words != null) { words = board!.search(dictionary); }
    setState(() {});
  }

  Future<void> removeWord(String word) async {
    prefs ??= await SharedPreferences.getInstance();
    if (addedWords.contains(word)) {
      addedWords.remove(word);
      prefs!.setStringList('addedWords', addedWords.toList());
    }
    else {
      removedWords.add(word);
      prefs!.setStringList('removedWords', removedWords.toList());
    }
    words?.remove(word);
    setState(() {});
  }

  String generate({bool shouldUpdateUI = false}) {
    FocusManager.instance.primaryFocus?.unfocus();
    clearGame();
    words = null;
    userIsFindingWords = true;
    verifiedWords = null;
    String generated = dice.roll(boardDimension ?? Constants.BOARD_DIMENSION_DEFAULT);

    if (shouldUpdateUI) {
      boardString = generated;
      boardStringController.text = boardString;
      myWordsController.clear();
      numSeconds = Constants.NUM_SECONDS;
      startTimer();
      timer?.cancel();
      setState(() {});
    }
    return generated;
  }

  void clearGame() {
    boardStringController.clear();
    myWordsController.clear();

    boardString = '';
    words = null;
    timer?.cancel();
    timer = null;
    userIsFindingWords = true;
    verifiedWords = null;
    board = null;
    setState(() {});
    tabController.animateTo(0);
  }

  Future<void> startGame({Function(String)? shareAction, String? existingBoardString}) async {
    String generatedString = existingBoardString ?? generate();
    if (shareAction != null) { await shareAction(generatedString); }
    boardString = generatedString;
    boardStringController.text = boardString;
    setState(() => numSeconds = Constants.NUM_SECONDS);
    // ignore: use_build_context_synchronously
    startTimer();
  }

  Future<void> verifyWords() async {
    showLoader(context);
    List<String> myWords = myWordsController.text.trim().toLowerCase().split('\n');
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
        if (foundWords.firstWhereOrNull((foundWord) => foundWord.word == word) == null) {
          foundWords.add(FoundWord(word));
          tempDictionary.addWord(word);
        }
      }
    }
    Set<String> searchedWords = Board(boardString, 1).search(tempDictionary);
    for (FoundWord foundWord in foundWords) {
      if (!searchedWords.contains(foundWord.word)) {
        foundWord.setState(FoundWordState.IS_NOT_FOUND);
      }
      else {
        await getDefinition(foundWord.word).then((String definition) {}).catchError((error) {
          if (error is TimeoutException || error is SocketException) {
            if (!dictionary.hasWord(foundWord.word).isWord) { foundWord.setState(FoundWordState.IS_NOT_WORD); }
          }
          else { foundWord.setState(FoundWordState.IS_NOT_WORD); }
        });
      }
      if (foundWord.state == null && foundWord.word.length < minWordLength) { foundWord.setState(FoundWordState.IS_TOO_SHORT); }
    }

    if (words == null) {
      board = Board(boardString, minWordLength);
      words = board!.search(dictionary);
    }

    setState(() => verifiedWords = foundWords);
    hideLoader();
  }

  List<PopupMenuItem<String>> getAppBarActions() {
    return [
      PopupMenuItem<String>(
        value: 'New Game',
        onTap: () async {
          FocusManager.instance.primaryFocus?.unfocus();
          WidgetsBinding.instance.addPostFrameCallback((_) => showDialog(
            context: context,
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
                        startGame(shareAction: (String generatedString) async {
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
                        startGame(shareAction: (String generatedString) async {
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
                        startGame(shareAction: (String generatedString) async {
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
            context: context,
            builder: (BuildContext dialogContext) => JoinGameDialog((String decryptedString) {
              clearGame();
              startGame(existingBoardString: decryptedString);
            }),
          ));
        },
        child: const Text('Join Game'),
      ),
      if (boardString != '') PopupMenuItem<String>(
        value: 'Share Board',
        onTap: () async {
          FocusManager.instance.primaryFocus?.unfocus();
          String toShare = convertStringToEmojis(boardString);
          await Share.shareWithResult(toShare, subject: 'Boggle Board');
        },
        child: const Text('Share Board'),
      ),
      PopupMenuItem<String>(
        value: 'Min Word Length',
        child: Text('Min Word Length: $minWordLength'),
        onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) => showDialog(
          context: context,
          builder: (BuildContext dialogContext) => MinWordLengthDialog(
            minWordLength,
            (value) { setState(() => minWordLength = value); },
          )).then((value) async {
            prefs ??= await SharedPreferences.getInstance();
            prefs!.setInt('minWordLength', minWordLength);

            if (words != null) {
              board = Board(boardString, minWordLength);
              words = board!.search(dictionary);
            }
            if (!userIsFindingWords && verifiedWords != null) {
              for (var verifiedWord in verifiedWords!) {
                if (verifiedWord.state == null && verifiedWord.word.length < minWordLength) {
                  verifiedWord.setState(FoundWordState.IS_TOO_SHORT);
                }
                else if (verifiedWord.state == FoundWordState.IS_TOO_SHORT && verifiedWord.word.length >= minWordLength) {
                  verifiedWord.setState(null);
                }
              }
            }
            setState(() {});
          }),
        ),
      ),
      const PopupMenuItem<String>(
        value: 'Dictionary',
        child: Text('Dictionary'),
      ),
    ];
  }

  Widget buildMyWordsTab() {
    return const TextField(
      keyboardType: TextInputType.multiline,
      maxLines: 12,
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
                style: TextStyle(fontSize: MediaQuery.of(context).size.height / (dimension * 7), fontWeight: FontWeight.bold),
              ),
            )).toList(),
          ),
        );
      },
    );
  }

  Widget buildTabs(List<String>? workingWords) {
    return Column(
      children: [
        TabBar(
          controller: tabController,
          tabs: [
            Tab(text: 'My Words${verifiedWords == null ? '' : ' (${VerifiedWords.getNumVerifiedWords(verifiedWords)})'}'),
            Tab(text: 'All Words${workingWords == null ? '' : ' (${workingWords.length})'}'),
          ],
        ),
        const SizedBox(height: 8),
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
                ) : VerifiedWords(
                  verifiedWords,
                  words?.length,
                  () => setState(() {}),
                  addWord,
                  removeWord,
                ),
              ),
              SingleChildScrollView(
                key: const PageStorageKey('allWords'),
                child: AllWords(
                  workingWords,
                  verifiedWords,
                  isSearchAvailable ? () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    board = Board(boardString, minWordLength);
                    words = board!.search(dictionary);
                    setState(() {});
                  } : null,
                  (String word) => removeWord(word),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String>? workingWords;
    if (words != null) {
      workingWords = [...words!.toList()];
      workingWords.removeWhere((word) => removedWords.contains(word));
    }
    double timerControlIconSize = 14;
    List<PopupMenuItem<String>> appBarActions = getAppBarActions();
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Boggle Solver'),
        actions: [
          PopupMenuButton<String>(
            enabled: appBarActions.isNotEmpty,
            onSelected: (String result) {
              if (result == 'Dictionary') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DictionaryModificationsPage(
                  addedWords,
                  (String word) {
                    removeWord(word);
                    hasModifiedDictionary = true;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$word removed from dictionary')));
                  },
                  removedWords,
                  (String word) {
                    String message;
                    bool isAdded = false;
                    if (removedWords.contains(word)) {
                      message = '"$word" added back from removed words';
                      addWord(word);
                      hasModifiedDictionary = true;
                    }
                    else if (!dictionary.hasWord(word).isWord) {
                      message = '"$word" added to dictionary';
                      addWord(word);
                      hasModifiedDictionary = true;
                      isAdded = true;
                    }
                    else { message = '"$word" already in dictionary'; }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                    return isAdded;
                  }
                  ))
                ).then((value) {
                  if (!userIsFindingWords && hasModifiedDictionary) {
                    verifyWords();
                    hasModifiedDictionary = false;
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
          padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: timerControlIconSize,
                        width: timerControlIconSize,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: timerControlIconSize,
                        width: timerControlIconSize,
                        child: IconButton(
                          iconSize: timerControlIconSize,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          splashRadius: timerControlIconSize * 1.5,
                          icon: Icon(timer?.isActive ?? false ? Icons.pause_rounded : Icons.play_arrow_rounded, color: timer != null ? null : Colors.transparent,),
                          onPressed: timer != null ? () {
                            if (timer?.isActive ?? false) { timer?.cancel(); }
                            else { startTimer(); }
                            setState(() {});
                          } : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: timerControlIconSize,
                        width: timerControlIconSize,
                        child: (timer?.isActive ?? false) || numSeconds == Constants.NUM_SECONDS ? null : IconButton(
                          iconSize: timerControlIconSize,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          splashRadius: timerControlIconSize * 1.5,
                          icon: Icon(Icons.refresh_rounded, color: timer != null ? null : Colors.transparent),
                          onPressed: timer != null ? () { setState(() => numSeconds = Constants.NUM_SECONDS); } : null,
                        ),
                      ),
                    ],
                  ),
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
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                        FilteringTextInputFormatter.allow(RegExp('[A-Z]')),
                      ],
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Enter the board',
                        suffixIcon: IconButton(
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            clearGame();
                          },
                          icon: const Icon(Icons.close_rounded),
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
                  SizedBox(
                    height: 56,
                    width: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          onPressed: () => generate(shouldUpdateUI: true),
                          icon: const Icon(Icons.restart_alt_rounded),
                        ),
                        Positioned(
                          bottom: 0,
                          child: GestureDetector(
                            child: Text('${(boardDimension ?? Constants.BOARD_DIMENSION_DEFAULT).toString()}x${(boardDimension ?? Constants.BOARD_DIMENSION_DEFAULT).toString()}', style: TextStyle(color: Theme.of(context).colorScheme.secondary),),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return AlertDialog(
                                    title: const Text('Board Dimension'),
                                    content: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(5, (index) => index + 1).map((dimension) {
                                        return ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            elevation: 0,
                                            backgroundColor: dimension == boardDimension
                                              ? Theme.of(context).colorScheme.secondary
                                              : Theme.of(context).dividerColor,
                                            foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                            minimumSize: const Size.fromHeight(40),
                                          ),
                                          onPressed: () async {
                                            Navigator.pop(dialogContext);
                                            boardDimension = dimension;
                                            generate(shouldUpdateUI: true);
                                                
                                            prefs ??= await SharedPreferences.getInstance();
                                            prefs!.setInt('boardDimension', dimension);
                                          },
                                          child: Text('${dimension}x${dimension}'),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: timerControlIconSize, width: timerControlIconSize),
                ],
              ),
              Expanded(child: buildBoard()),
              Expanded(child: buildTabs(workingWords)),
            ]
          ),
        ),
      ),
      floatingActionButton: myWordsController.text.isNotEmpty && MediaQuery.of(context).viewInsets.bottom == 0 && tabController.index == 0 ? FloatingActionButton(
        elevation: 0,
        onPressed: userIsFindingWords ? () {
          verifyWords();
          setState(() => userIsFindingWords = false);
        } : () {
          verifiedWords = null;
          setState(() => userIsFindingWords = true);
        },
        child: Icon(userIsFindingWords ? Icons.check_rounded : Icons.edit_outlined),
      ) : null,
    );
  }
}
import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:woggle/board/board.dart';
import 'package:woggle/board/dice.dart';
import 'package:woggle/board/found_word.dart';
import 'package:woggle/board/word.dart';
import 'package:woggle/dialogs/join_game_dialog.dart';
import 'package:woggle/dictionary/dictionary.dart';
import 'package:woggle/dictionary/dictionary_node.dart';
import 'package:woggle/pages/dictionary_modifications_page.dart';
import 'package:woggle/pages/rules_page.dart';
import 'package:woggle/pages/settings_page.dart';
import 'package:woggle/utils/constants.dart';
import 'package:woggle/utils/utils.dart';
import 'package:woggle/widgets/all_words.dart';
import 'package:woggle/widgets/verified_words.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  late Dictionary dictionary;
  bool isDictionaryLoaded = false;
  Board? board;
  Set<Word>? words;
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
  bool? showTimerDuringPlay;

  final GlobalKey popupButtonKey = GlobalKey<State>(); 

  ScrollController myWordsScrollController = ScrollController();

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
    showTimerDuringPlay = prefs!.getBool('showTimerDuringPlay') ?? true;
    setState(() {});
    generate(shouldUpdateUI: true);
    
    // ignore: use_build_context_synchronously
    String dictionaryFile = await DefaultAssetBundle.of(context).loadString('assets/dictionary.txt');
    for (String line in dictionaryFile.split('\n')) { dictionary.addWord(line.split(' ')[0], line.split(' ').sublist(1).join(' ')); }
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

  void resetTimer() {
    numSeconds = Constants.NUM_SECONDS;
    startTimer();
    timer?.cancel();
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
      resetTimer();
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
    List<String> myWords = [];
    List<String> myWordsNewlines = myWordsController.text.trim().toLowerCase().split('\n');
    for (String word in myWordsNewlines) {
      if (word.trim().isNotEmpty) {
        myWords.addAll(word.split(',').map((w) => w.trim()).where((w) => w.isNotEmpty));
      }
    }
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
        if (foundWords.firstWhereOrNull((foundWord) => foundWord.word.word == word) == null) {
          foundWords.add(FoundWord(Word(word, null)));
          tempDictionary.addWord(word, null);
        }
      }
    }
    Set<Word> searchedWords = Board(boardString, 1).search(tempDictionary);
    for (FoundWord foundWord in foundWords) {
      if (searchedWords.firstWhereOrNull((word) => word.word == foundWord.word.word) == null) { foundWord.setState(FoundWordState.IS_NOT_FOUND); }
      WordSearchResult wordSearchResult = dictionary.hasWord(foundWord.word.word);
      if (!wordSearchResult.isWord) { foundWord.setState(FoundWordState.IS_NOT_WORD); }
      else { foundWord.word.definition = wordSearchResult.definition; }
      if (foundWord.state == null && foundWord.word.word.length < minWordLength) { foundWord.setState(FoundWordState.IS_TOO_SHORT); }
    }

    if (words == null) {
      board = Board(boardString, minWordLength);
      words = board!.search(dictionary);
    }

    setState(() => verifiedWords = foundWords);
    hideLoader();
  }

  List<PopupMenuItem<String>> getAppBarActions({bool isSocial = false}) {
    if (isSocial) {
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
                        title: const Text('Wogglers'),
                        onTap: () {
                          Navigator.pop(dialogContext);
                          startGame(shareAction: (String generatedString) async {
                            String toShare = await boardSecrets(generatedString, encrypt: true);
                            if (!kIsWeb) { await Share.shareWithResult(toShare, subject: 'Woggle Board'); }
                            else {
                              await Clipboard.setData(ClipboardData(text: toShare));
                              // ignore: use_build_context_synchronously
                              showSnackBar(context, 'Encrypted board copied successfully');
                            }
                          });
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.person_outline_rounded),
                        title: const Text('Non-Wogglers'),
                        onTap: () {
                          Navigator.pop(dialogContext);
                          startGame(shareAction: (String generatedString) async {
                            String toShare = '\n\n\n${convertStringToEmojis(generatedString)}';
                            if (!kIsWeb) { await Share.shareWithResult(toShare, subject: 'Woggle Board'); }
                            else {
                              await Clipboard.setData(ClipboardData(text: toShare));
                              // ignore: use_build_context_synchronously
                              showSnackBar(context, 'Board copied successfully');
                            }
                          });
                        },
                      ),
                      if (!kIsWeb) ListTile(
                        leading: const Icon(Icons.diversity_3_rounded),
                        title: const Text('Mixed users'),
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          startGame(shareAction: (String generatedString) async {
                            String toShareEncrypted = await boardSecrets(generatedString, encrypt: true);
                            await Share.shareWithResult(toShareEncrypted, subject: 'Woggle Board');
                            String toShare = '\n\n\n${convertStringToEmojis(generatedString)}';
                            await Share.shareWithResult(toShare, subject: 'Woggle Board');
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ));
          },
          child: const ListTile(title: Text('New Game')),
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
          child: const ListTile(title: Text('Join Game')),
        ),
        if (boardString != '') PopupMenuItem<String>(
          value: 'Share Board',
          onTap: () async {
            FocusManager.instance.primaryFocus?.unfocus();
            String toShare = convertStringToEmojis(boardString);
            if (!kIsWeb) { await Share.shareWithResult(toShare, subject: 'Woggle Board'); }
            else {
              await Clipboard.setData(ClipboardData(text: toShare));
              // ignore: use_build_context_synchronously
              showSnackBar(context, 'Board copied successfully');
            }
          },
          child: const ListTile(title: Text('Share Board')),
        ),
      ];
    }
    return [
      const PopupMenuItem<String>(
        value: 'Social',
        child: ListTile(
          title: Text('Social'),
          trailing: Icon(Icons.arrow_right_rounded),
        ),
      ),
      const PopupMenuItem<String>(
        value: 'Dictionary',
        child: ListTile(title: Text('Dictionary')),
      ),
      const PopupMenuItem<String>(
        value: 'Rules',
        child: ListTile(title: Text('Rules')),
      ),
      const PopupMenuItem<String>(
        value: 'Settings',
        child: ListTile(title: Text('Settings')),
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

  Word getWord(String word) => Word(word, dictionary.hasWord(word).definition);

  Widget buildTabs(List<Word>? workingWords) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600,),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: tabController,
              tabs: [
                Tab(text: 'My Words${verifiedWords == null ? '' : ' (${VerifiedWords.getNumVerifiedWords(verifiedWords)})'}'),
                Tab(text: 'All Words${workingWords == null ? '' : ' (${workingWords.length})'}'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: tabController,
              physics: kIsWeb ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
              children: [
                SingleChildScrollView(
                  key: const PageStorageKey('myWords'),
                  controller: myWordsScrollController,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: userIsFindingWords ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: TextField(
                        key: const PageStorageKey('myWordsTextField'),
                        controller: myWordsController,
                        keyboardType: TextInputType.multiline,
                        onChanged: (String word) => setState(() => verifiedWords = null),
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
                      getWord,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  key: const PageStorageKey('allWords'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      getWord,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showSubMenu() {
    final RenderBox popupButtonObject = popupButtonKey.currentContext?.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        popupButtonObject.localToGlobal(Offset.zero, ancestor: overlay),
        popupButtonObject.localToGlobal(popupButtonObject.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      elevation: 8.0, // default value
      items: getAppBarActions(isSocial: true),
      initialValue: null,
      position: position,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Word>? workingWords;
    if (words != null) {
      workingWords = [...words!.toList()];
      workingWords.removeWhere((word) => removedWords.contains(word.word));
    }
    double timerControlIconSize = 14;
    List<PopupMenuItem<String>> appBarActions = getAppBarActions();
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: RichText(
          text: TextSpan(
            style: GoogleFonts.varelaRound().copyWith(fontSize: 26),
            children: <TextSpan>[
              const TextSpan(text: 'W', style: TextStyle(color: Constants.primaryColor)),
              TextSpan(text: 'oggle', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            key: popupButtonKey,
            enabled: appBarActions.isNotEmpty,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
            onSelected: (String result) {
              if (result == 'Dictionary') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DictionaryModificationsPage(
                  addedWords,
                  (String word) {
                    removeWord(word);
                    hasModifiedDictionary = true;
                    showSnackBar(context, '$word removed from dictionary');
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
                    showSnackBar(context, message);
                    return isAdded;
                  }
                  ))
                ).then((value) {
                  if (hasModifiedDictionary) {
                    if (words != null) {
                      board = Board(boardString, minWordLength);
                      words = board!.search(dictionary);
                    }
                    if (!userIsFindingWords && verifiedWords != null) {
                      for (FoundWord foundWord in verifiedWords!) {
                        if (foundWord.state != FoundWordState.IS_NOT_FOUND && foundWord.state != FoundWordState.IS_TOO_SHORT) {
                          if (!dictionary.hasWord(foundWord.word.word).isWord) { foundWord.setState(FoundWordState.IS_NOT_WORD); }
                          else if (foundWord.state == FoundWordState.IS_NOT_WORD) { foundWord.setState(null); }
                        }
                      }
                    }
                    setState(() {});
                    hasModifiedDictionary = false;
                  }
                });
              }
              else if (result == 'Social') {
                showSubMenu();
              }
              else if (result == 'Rules') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => RulesPage(minWordLength, boardDimension ?? Constants.BOARD_DIMENSION_DEFAULT)));
              }
              else if (result == 'Settings') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(
                  minWordLength,
                  (newMinWordLength) async {
                    minWordLength = newMinWordLength;
                    setState(() {});
                    prefs ??= await SharedPreferences.getInstance();
                    prefs!.setInt('minWordLength', minWordLength);

                    if (words != null) {
                      board = Board(boardString, minWordLength);
                      words = board!.search(dictionary);
                    }
                    if (!userIsFindingWords && verifiedWords != null) {
                      for (var verifiedWord in verifiedWords!) {
                        if (verifiedWord.state == null && verifiedWord.word.word.length < minWordLength) {
                          verifiedWord.setState(FoundWordState.IS_TOO_SHORT);
                        }
                        else if (verifiedWord.state == FoundWordState.IS_TOO_SHORT && verifiedWord.word.word.length >= minWordLength) {
                          verifiedWord.setState(null);
                        }
                      }
                    }
                    setState(() {});
                  },
                  boardDimension ?? Constants.BOARD_DIMENSION_DEFAULT,
                  (dimension) async {
                    boardDimension = dimension;
                    generate(shouldUpdateUI: true);
                        
                    prefs ??= await SharedPreferences.getInstance();
                    prefs!.setInt('boardDimension', dimension);
                  },
                  showTimerDuringPlay ?? true,
                  (showTimer) async {
                    showTimerDuringPlay = showTimer;
                    setState(() {});
                        
                    prefs ??= await SharedPreferences.getInstance();
                    prefs!.setBool('showTimerDuringPlay', showTimerDuringPlay!);
                  }
                )));
              }
            },
            itemBuilder: (BuildContext context) => appBarActions,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Row(
                children: [
                  SizedBox(
                    height: timerControlIconSize * 2,
                    width: timerControlIconSize * 2,
                    child: IconButton(
                      iconSize: timerControlIconSize * 2,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      splashRadius: timerControlIconSize,
                      icon: Icon(
                        timer?.isActive ?? false ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: timer != null ? null : Colors.transparent,
                        size: timerControlIconSize,
                      ),
                      onPressed: timer != null ? () {
                        if (timer?.isActive ?? false) { timer?.cancel(); }
                        else { startTimer(); }
                        setState(() {});
                      } : null,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          right: 8,
                          child: boardString != '' && (timer == null || (!(timer!.isActive) && numSeconds < Constants.NUM_SECONDS)) ? Icon(
                            Icons.refresh_rounded,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 14,
                          ) : Container(),
                        ),
                        TextButton(
                          onPressed: boardString != '' && (timer == null || (!(timer!.isActive) && numSeconds < Constants.NUM_SECONDS)) ? () {
                            resetTimer();
                            setState(() {});
                           } : null,
                          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.secondary),
                          child: Container(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              '${numSeconds ~/ 60}:${(numSeconds % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(color: boardString != '' && ((showTimerDuringPlay ?? true) || !(timer?.isActive ?? false) || numSeconds == Constants.NUM_SECONDS) ? Theme.of(context).colorScheme.secondary : Colors.transparent, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
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
                        int newStringLength = newString.length;
                        if (sqrt(newStringLength).toInt() == sqrt(newStringLength)) {
                          resetTimer();
                        }
                        else {
                          timer?.cancel();
                          timer = null;
                        }
                      }),
                    ),
                  ),
                  IconButton(onPressed: () => generate(shouldUpdateUI: true), icon: const Icon(Icons.restart_alt_rounded)),
                  SizedBox(height: timerControlIconSize * 2, width: timerControlIconSize * 2),
                ],
              ),
            ),
            Expanded(child: buildBoard()),
            Expanded(child: buildTabs(workingWords)),
          ]
        ),
      ),
      floatingActionButton: myWordsController.text.isNotEmpty && MediaQuery.of(context).viewInsets.bottom == 0 && tabController.index == 0 ? FloatingActionButton(
        elevation: 0,
        onPressed: userIsFindingWords ? () {
          FocusManager.instance.primaryFocus?.unfocus();
          if (verifiedWords == null) { verifyWords(); }
          myWordsScrollController.jumpTo(0);
          setState(() => userIsFindingWords = false);
        } : () { setState(() => userIsFindingWords = true); },
        child: Icon(userIsFindingWords ? Icons.check_rounded : Icons.edit_outlined),
      ) : Container(),
    );
  }
}
import 'dart:math';

import 'package:woggle/board/word.dart';
import 'package:woggle/dictionary/dictionary.dart';
import 'package:woggle/dictionary/dictionary_node.dart';

class Board {
  late List<List<String>> board;
  final int minWordLength;

  Board(String boardString, this.minWordLength) {
    List<String> boardStringList = boardString.toLowerCase().split('');
    for (int i = 0; i < boardStringList.length; i++) {
      if (boardStringList[i] == 'q' && i + 1 < boardStringList.length && boardStringList[i + 1] == 'u') {
        boardStringList[i] = 'qu';
        boardStringList.removeAt(i + 1);
      }
    }
    int boardWidth = sqrt(boardStringList.length).toInt();
    board = [];
    for (int i = 0; i < boardWidth; i++) {
      board.add(boardStringList.sublist(i * boardWidth, (i + 1) * boardWidth));
    }
  }

  List<Word> searchHelper(Dictionary dictionary, List<List<bool>> visited, String word, int i, int j) {
    if (i < 0 || i >= visited.length || j < 0 || j >= visited.length || visited[i][j]) { return []; }
    String workingWord = word + board[i][j];
    visited[i][j] = true;
    List<Word> result = [];
    bool shouldContinue = true;
    if (workingWord.length >= minWordLength) {
      WordSearchResult searchResult = dictionary.hasWord(workingWord);
      if (!searchResult.hasChildren) { shouldContinue = false; }
      if (searchResult.isWord) { result.add(Word(workingWord, searchResult.definition)); }
    }
    if (shouldContinue) {
      result.addAll([
        ...searchHelper(dictionary, [for (List<bool> sublist in visited) [...sublist]], workingWord, i - 1, j - 1),
        ...searchHelper(dictionary, [for (List<bool> sublist in visited) [...sublist]], workingWord, i - 1, j),
        ...searchHelper(dictionary, [for (List<bool> sublist in visited) [...sublist]], workingWord, i - 1, j + 1),
        ...searchHelper(dictionary, [for (List<bool> sublist in visited) [...sublist]], workingWord, i, j - 1),
        ...searchHelper(dictionary, [for (List<bool> sublist in visited) [...sublist]], workingWord, i, j + 1),
        ...searchHelper(dictionary, [for (List<bool> sublist in visited) [...sublist]], workingWord, i + 1, j - 1),
        ...searchHelper(dictionary, [for (List<bool> sublist in visited) [...sublist]], workingWord, i + 1, j),
        ...searchHelper(dictionary, [for (List<bool> sublist in visited) [...sublist]], workingWord, i + 1, j + 1),
      ]);
    }
    return result;
  }

  Set<Word> search(Dictionary dictionary) {
    List<Word> results = [];
    for (int i = 0; i < board.length; i++) {
      for (int j = 0; j < board[i].length; j++) {
        List<List<bool>> visited = [];
        visited = List.generate(board.length, (index) => List.generate(board.length,  (_) => false));
        results.addAll(searchHelper(dictionary, visited, '', i, j));
      }
    }
    results.sort((word1, word2) {
      if (word1.word.length > word2.word.length) { return -1; }
      else if (word2.word.length > word1.word.length) { return 1; }
      return word1.word.compareTo(word2.word);
    });
    Set<String> uniqueWords = {};
    results.retainWhere((word) => uniqueWords.add(word.word));
    return results.toSet();
  }
}
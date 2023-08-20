import 'package:boggle_solver/dictionary/dictionary_node.dart';

class Dictionary {
  final DictionaryNode root = DictionaryNode();

  void addWord(String word) {
    root.addWord(word.toLowerCase().trim());
  }

  WordSearchResult hasWord(String word) {
    return root.hasWord(word);
  }
}
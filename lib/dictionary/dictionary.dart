import 'package:woggle/dictionary/dictionary_node.dart';

class Dictionary {
  final bool Function(String) isWordRemoved;
  final bool Function(String) isWordAdded;
  Dictionary({
    bool Function(String)? isWordRemoved,
    bool Function(String)? isWordAdded,
  }) : isWordRemoved = isWordRemoved ?? ((String word) => false),
      isWordAdded = isWordAdded ?? ((String word) => false);

  final DictionaryNode root = DictionaryNode();

  void addWord(String word, String? definition) {
    root.addWord(word.toLowerCase().trim(), definition?.trim());
  }

  WordSearchResult hasWord(String word) {
    WordSearchResult result = root.hasWord(word);
    if (isWordRemoved(word)) { result.isWord = false; }
    else if (isWordAdded(word)) { result.isWord = true; }
    return result;
  }
}
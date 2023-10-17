class WordSearchResult {
  bool isWord;
  final bool hasChildren;
  final String? definition;
  WordSearchResult(this.isWord, this.hasChildren, this.definition);
}

class DictionaryNode {
  Map<String, DictionaryNode> children = {};
  bool get hasChildren => children.isNotEmpty;
  bool isWordEnd = false;
  String? definition;

  DictionaryNode();

  void addWord(String word, String? definition) {
    if (word.isEmpty) { return; }
    String char = word[0];
    if (!children.containsKey(char)) { children[char] = DictionaryNode(); }
    String remainingWord = word.substring(1).trim();
    if (remainingWord.isNotEmpty) { children[char]!.addWord(remainingWord, definition); }
    else {
      children[char]!.isWordEnd = true;
      children[char]!.definition = definition;
    }
  }

  WordSearchResult hasWord(String word) {
    if (word.isEmpty) { return WordSearchResult(isWordEnd, hasChildren, definition); }
    String char = word[0];
    if (!children.containsKey(char)) { return WordSearchResult(false, false, null); }
    return children[char]!.hasWord(word.substring(1));
  }
}
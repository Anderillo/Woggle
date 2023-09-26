class WordSearchResult {
  bool isWord;
  final bool hasChildren;
  WordSearchResult(this.isWord, this.hasChildren);
}

class DictionaryNode {
  Map<String, DictionaryNode> children = {};
  bool get hasChildren => children.isNotEmpty;
  bool isWordEnd = false;

  DictionaryNode();

  void addWord(String word) {
    if (word.isEmpty) { return; }
    String char = word[0];
    if (!children.containsKey(char)) { children[char] = DictionaryNode(); }
    String remainingWord = word.substring(1).trim();
    if (remainingWord.isNotEmpty) { children[char]!.addWord(remainingWord); }
    else { children[char]!.isWordEnd = true; }
  }

  WordSearchResult hasWord(String word) {
    if (word.isEmpty) { return WordSearchResult(isWordEnd, hasChildren); }
    String char = word[0];
    if (!children.containsKey(char)) { return WordSearchResult(false, false); }
    return children[char]!.hasWord(word.substring(1));
  }
}
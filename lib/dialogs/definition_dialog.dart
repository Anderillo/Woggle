import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:woggle/board/word.dart';
import 'package:woggle/utils/utils.dart';

class DefinitionDialog extends StatefulWidget {
  final Word word;
  final Function(String)? getWord;
  const DefinitionDialog(this.word, this.getWord, {super.key});

  @override
  State<DefinitionDialog> createState() => _DefinitionDialogState();
}

class _DefinitionDialogState extends State<DefinitionDialog> {
  List<Word> wordsSoFar = [];
  @override
  void initState() {
    super.initState();
    wordsSoFar.add(widget.word);
    // getDefinition(widget.word).then((String definition) {
    //   if (!mounted) { return; }
    //   setState(() => this.definition = definition);
    // }).catchError((error) {
    //   String? message;
    //   if (!mounted) { return; }
    //   if (error is TimeoutException) { message = 'The request timed out.'; }
    //   else if (error is SocketException) { message = 'Internet connection error.'; }
    //   setState(() => definition = message ?? 'Sorry, no definition found.');
    // });
  }

  Widget buildDefinition(String? definition) {
    List<String> definitions = (definition ?? 'No definition found.').split(' / ');
    TextStyle linkStyle = TextStyle(color: Theme.of(context).colorScheme.secondary);
    List<Widget> definitionWidgets = [];
    for (int i = 0; i < definitions.length; i++) {
      List<TextSpan> spans = [];
      if (definitions.length > 1) { spans.add(TextSpan(text: '${i + 1}. ')); }
      List<String> words = definitions[i].split(' ');
      for (int j = 0; j < words.length; j++) {
        String word = words[j];
        if (word[0] != '[') { spans.add(TextSpan(text: j > 0 ? ' $word' : word.capitalize())); }
        else {
          String cleanedWord = word.replaceAll('[', '').replaceAll(']', '');
          if (widget.getWord == null) { spans.add(TextSpan(text: j > 0 ? ' $cleanedWord' : cleanedWord.capitalize())); }
          else {
            spans.add(TextSpan(
              text: j > 0 ? ' $cleanedWord' : cleanedWord.capitalize(),
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Word newWord = widget.getWord!(cleanedWord);
                  setState(() => wordsSoFar.add(newWord));
                }
            ));
          }
        }
      }
      definitionWidgets.add(Container(
        padding: const EdgeInsets.only(top: 16),
        child: RichText(text: TextSpan(children: spans)),
      ));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: definitionWidgets,
    );
  }

  Widget buildCloseButton() {
    double iconSize = 24;
    return IconButton(
      iconSize: iconSize * 1.5,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      splashRadius: iconSize * 0.75,
      icon: Icon(Icons.close_rounded, size: iconSize),
      onPressed: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    Word currentWord = wordsSoFar.last;
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(currentWord.word),
          buildCloseButton(),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: buildDefinition(currentWord.definition),
      ),
      actions: [
        TextButton(
          onPressed: wordsSoFar.length > 1 ? () => setState(() => wordsSoFar.removeLast()) : null,
          child: Text('Back', style: TextStyle(color: wordsSoFar.length > 1 ? null : Colors.transparent),),
        ),
        TextButton(
          onPressed: () async {
            final Uri url = Uri.parse('https://www.dictionary.com/browse/${currentWord.word}');
            if (!await launchUrl(url)) {
              SnackBar snackBar = SnackBar(
                content: Text('Could not launch Dictionary.com for "${currentWord.word}"'),
              );
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
          },
          child: const Text('Dictionary.com'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
    );
  }
}
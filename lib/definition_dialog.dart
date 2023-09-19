import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

class DefinitionDialog extends StatefulWidget {
  final String word;
  const DefinitionDialog(this.word, {super.key});

  @override
  State<DefinitionDialog> createState() => _DefinitionDialogState();
}

class _DefinitionDialogState extends State<DefinitionDialog> {
  String? definition;

  @override
  void initState() {
    super.initState();
    get(Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/${widget.word}')).then((Response definition) {
      if (!mounted) { return; }
      setState(() {
        try { this.definition = jsonDecode(definition.body)[0]['meanings'][0]['definitions'][0]['definition']; }
        catch (e) { this.definition = 'Sorry, no definition found.'; }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.word),
      content: definition != null
        ? Text(definition!)
        : const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator()],
        ),
      actions: [
        TextButton(
          onPressed: () async {
            final Uri url = Uri.parse('https://www.dictionary.com/browse/${widget.word}');
            if (!await launchUrl(url)) {
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
              SnackBar snackBar = SnackBar(
                content: Text('Could not launch Dictionary.com for "${widget.word}"'),
              );
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          },
          child: const Text('Dictionary.com'),
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
    );
  }
}
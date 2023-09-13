import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

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
    );
  }
}
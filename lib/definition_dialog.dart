import 'dart:async';
import 'dart:io';

import 'package:boggle_solver/utils.dart';
import 'package:flutter/material.dart';
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
    getDefinition(widget.word).then((String definition) {
      if (!mounted) { return; }
      setState(() => this.definition = definition);
    }).catchError((error) {
      String? message;
      if (!mounted) { return; }
      if (error is TimeoutException) { message = 'The request timed out.'; }
      else if (error is SocketException) { message = 'Internet connection error.'; }
      setState(() => definition = message ?? 'Sorry, no definition found.');
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
              SnackBar snackBar = SnackBar(
                content: Text('Could not launch Dictionary.com for "${widget.word}"'),
              );
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
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
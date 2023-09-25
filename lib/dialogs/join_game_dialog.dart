import 'package:boggle_solver/utils/utils.dart';
import 'package:flutter/material.dart';

class JoinGameDialog extends StatefulWidget {
  final Function(String) onStart;
  const JoinGameDialog(this.onStart, {super.key});

  @override
  State<JoinGameDialog> createState() => _JoinGameDialogState();
}

class _JoinGameDialogState extends State<JoinGameDialog> {
  final TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.75,
        child: TextField(
          autofocus: true,
          controller: textEditingController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Paste encrypted string here',
            isDense: true,
          ),
          onChanged: (String newString) => setState(() {}),
          maxLines: null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            showLoader(context);
            String? boardString;
            try { boardString = await boardSecrets(textEditingController.text, encrypt: false); }
            catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Decryption failed'))); }
            hideLoader();
            if (boardString != null) { widget.onStart(boardString); }
          },
          child: const Text('Start Game'),
        ),
      ],
    );
  }
}
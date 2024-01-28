import 'package:flutter/material.dart';
import 'package:woggle/dialogs/min_word_length_dialog.dart';

class SettingsPage extends StatefulWidget {
  final int minWordLength;
  final Function(int) onMinWordLengthChanged;
  final int boardDimension;
  final Function(int) onBoardDimensionChanged;
  final bool showTimer;
  final Function(bool) onShowTimerChanged;
  const SettingsPage(
    this.minWordLength,
    this.onMinWordLengthChanged,
    this.boardDimension,
    this.onBoardDimensionChanged,
    this.showTimer,
    this.onShowTimerChanged,
    {super.key}
  );

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int minWordLength;
  late int boardDimension;
  late bool showTimer;
  @override
  void initState() {
    super.initState();
    minWordLength = widget.minWordLength;
    boardDimension = widget.boardDimension;
    showTimer = widget.showTimer;
  }

  Widget buildSettingsItem(Widget icon, String title, Function()? onTap, {Widget? trailing}) {
    return ListTile(
      leading: icon,
      title: Text(title),
      onTap: onTap,
      trailing: trailing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, title: const Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSettingsItem(
                const Icon(Icons.text_rotation_none_rounded),
                'Min word length: $minWordLength',
                () => showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) => MinWordLengthDialog(
                    widget.minWordLength,
                    (value) => setState(() => minWordLength = value),
                  )).then((value) => widget.onMinWordLengthChanged(minWordLength)),
              ),
              buildSettingsItem(
                const Icon(Icons.apps_rounded),
                'Board dimension: ${boardDimension}x$boardDimension',
                () => showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Board Dimension'),
                      content: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) => index + 1).map((dimension) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: dimension == boardDimension
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).canvasColor,
                                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                minimumSize: const Size.fromHeight(40),
                              ),
                              onPressed: () async {
                                Navigator.pop(dialogContext);
                                boardDimension = dimension;
                                setState(() {});
                                widget.onBoardDimensionChanged(boardDimension);
                              },
                              child: Text('${dimension}x$dimension'),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
              buildSettingsItem(
                const Icon(Icons.timer_outlined),
                'Show timer during play',
                null,
                trailing: Switch(
                  value: showTimer,
                  onChanged: (value) {
                    showTimer = value;
                    setState(() {});
                    widget.onShowTimerChanged(showTimer);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
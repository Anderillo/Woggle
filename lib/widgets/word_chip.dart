import 'package:flutter/material.dart';
import 'package:woggle/board/word.dart';
import 'package:woggle/dialogs/definition_dialog.dart';

class WordChip extends StatelessWidget {
  final Word word;
  final String? wordExtension;
  final Function()? onLongPress;
  final Color? color;
  final TextStyle? wordStyle;
  final List<ChipAction>? frontActions;
  final List<ChipAction>? actions;
  final Function(String)? getWord;
  const WordChip(this.word, {this.wordExtension, this.onLongPress, this.color, this.wordStyle, this.frontActions, this.actions, this.getWord, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: () async {
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) => DefinitionDialog(word, getWord),
          );
        },
        onLongPress: onLongPress,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color ?? Colors.grey[700],
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (frontActions != null) ...frontActions!,
            SizedBox(width: frontActions?.isNotEmpty ?? false ? 2 : 16, height: 34),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '${word.word}${wordExtension ?? ''}',
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color).merge(wordStyle),
              ),
            ),
            SizedBox(width: actions?.isNotEmpty ?? false ? 2 : 16, height: 34),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}

class ChipAction extends StatelessWidget {
  final IconData icon;
  final Function() onTap;
  const ChipAction(this.icon, this.onTap, {super.key});
  
  @override
  Widget build(BuildContext context) {
    double iconSize = 22;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: IconButton(
          splashRadius: iconSize * 0.8,
          constraints: BoxConstraints(maxHeight: iconSize, maxWidth: iconSize),
          onPressed: onTap,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          icon: Icon(
            icon,
            size: iconSize,
            color: Theme.of(context).canvasColor,
          ),
        ),
      ),
    );
  }
}
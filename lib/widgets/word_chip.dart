import 'package:flutter/material.dart';
import 'package:woggle/dialogs/definition_dialog.dart';

class WordChip extends StatelessWidget {
  final String word;
  final String? wordExtension;
  final Function()? onLongPress;
  final Color? color;
  final TextStyle? wordStyle;
  final List<ChipAction> actions;
  const WordChip(this.word, {this.wordExtension, this.onLongPress, this.color, this.wordStyle, this.actions = const [], super.key});

  List<Widget> buildActions() {
    List<Widget> chipActions = [];
    for (ChipAction action in actions) {
      chipActions.addAll([
        const SizedBox(width: 4),
        action,
      ]);
    }
    return chipActions;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () => showDialog(
          context: context,
          builder: (BuildContext dialogContext) => DefinitionDialog(word),
        ),
        onLongPress: onLongPress,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color ?? Colors.grey[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$word${wordExtension ?? ''}',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color).merge(wordStyle),
            ),
            const SizedBox(width: 4),
            ...buildActions(),
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
    return IconButton(
      splashRadius: iconSize,
      constraints: BoxConstraints(maxHeight: iconSize, maxWidth: iconSize),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      icon: Icon(
        icon,
        size: iconSize,
        color: Theme.of(context).canvasColor,
      ),
    );
  }
}
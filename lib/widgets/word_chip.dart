import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WordChip extends StatelessWidget {
  final String word;
  final String? wordExtension;
  final Function()? onLongPress;
  final Color? color;
  final TextStyle? wordStyle;
  final List<ChipAction>? frontActions;
  final List<ChipAction>? actions;
  const WordChip(this.word, {this.wordExtension, this.onLongPress, this.color, this.wordStyle, this.frontActions, this.actions, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () async {
          final Uri url = Uri.parse('https://www.dictionary.com/browse/$word');
          if (!await launchUrl(url)) {
            SnackBar snackBar = SnackBar(
              content: Text('Could not launch Dictionary.com for "$word"'),
            );
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        },
        onLongPress: onLongPress,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color ?? Colors.grey[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
          // padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (frontActions != null) ...frontActions!,
            SizedBox(width: frontActions != null ? 2 : 16, height: 34),
            Text(
              '$word${wordExtension ?? ''}',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color).merge(wordStyle),
            ),
            SizedBox(width: actions != null ? 2 : 16, height: 34),
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
        padding: const EdgeInsets.all(6),
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
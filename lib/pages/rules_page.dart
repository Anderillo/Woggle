import 'package:flutter/material.dart';
import 'package:woggle/board/dice.dart';
import 'package:woggle/board/found_word.dart';
import 'package:woggle/utils/constants.dart';
import 'package:woggle/utils/utils.dart';

class RulesPage extends StatefulWidget {
  final int minWordLength;
  final int boardDimension;
  const RulesPage(this.minWordLength, this.boardDimension, {super.key});

  @override
  State<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends State<RulesPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 2500), vsync: this);
    Future.delayed(const Duration(milliseconds: 500), () => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildPointsItem(String contents) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        contents,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget buildPointsTable() {
    List<int> wordLengths = [widget.minWordLength - 1];
    while (wordLengths.last < 8) { wordLengths.add(wordLengths.last + 1); }
    return Container(
      padding: const EdgeInsets.all(16),
      child: Table(
        border: TableBorder.symmetric(inside: BorderSide(color: Theme.of(context).colorScheme.secondary)),
        children: [
          TableRow(
            children: [
              buildPointsItem('Length'),
              ...wordLengths.map((wordLength) => buildPointsItem(wordLength.toString() + (wordLength >= 8 ? '+' : ''))).toList()
            ],
          ),
          TableRow(children: [
            buildPointsItem('Points'),
              ...wordLengths.map((wordLength) => buildPointsItem(getPointsFromWordLength(wordLength).toString())).toList()
          ])
        ],
      ),
    );
  }

  Widget buildHeaderBlock(String contents) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Text(contents, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))],
      ),
    );
  }

  Widget buildBodyBlock(String contents) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(contents, style: const TextStyle(fontSize: 18)),
    );
  }

  Widget buildBoard() {
    String boardString = Dice().roll(widget.boardDimension);
    String wordToDraw = 'CORN';
    List<String> letters = [];
    for (int i = 0; i < widget.boardDimension * widget.boardDimension; i++) {
      if (i == 0) { letters.add(wordToDraw[0]); }
      else if (i == widget.boardDimension + 1) { letters.add(wordToDraw[1]); }
      else if (i == 1) { letters.add(wordToDraw[2]); }
      else if (i == widget.boardDimension) { letters.add(wordToDraw[3]); }
      else { letters.add(boardString[i]); }
    }

    double width = MediaQuery.of(context).size.width * 0.7;
    double fontSize = MediaQuery.of(context).size.height / (widget.boardDimension * 7);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: width,
          width: width,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: widget.boardDimension,
                children: letters.map((letter) => Center(
                  child: Text(
                    letter,
                    style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                  ),
                )).toList(),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double squareMiddle = width / widget.boardDimension / 2;
                  return CustomPaint(
                    painter: LinePainter(
                      _controller.value,
                      squareMiddle * 1.25,
                      [
                        Offset(squareMiddle, squareMiddle),
                        Offset(squareMiddle * 3, squareMiddle * 3),
                        Offset(squareMiddle * 3, squareMiddle),
                        Offset(squareMiddle, squareMiddle * 3),
                      ]
                    ),
                    child: Container(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildRuleItem(Widget icon, String instruction) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: icon,
      title: Text(instruction),
    );
  }

  Widget buildSpace() => const SizedBox(height: 20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Rules'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeaderBlock('How it Works'),
              buildBodyBlock('The goal of the game is to find words from the given grid.'),
              buildBoard(),
              buildBodyBlock('You can'),
              ...['Go in any direction', 'Cross your own path'].map((String instruction) => buildRuleItem(
                const Icon(Icons.check_circle_outline_outlined, color: isPointsColor,),
                instruction,
              )),
              buildBodyBlock('You cannot'),
              ...['Reuse letters', 'Skip letters'].map((String instruction) => buildRuleItem(
                const Icon(Icons.highlight_off_rounded, color: isNotWordColor),
                instruction,
              )),
              buildSpace(),
              buildBodyBlock('The lengths of your words will determine your total points.'),
              buildPointsTable(),
              buildSpace(),
              buildHeaderBlock('Playing the Game'),
              buildBodyBlock('Starting with whoever got the most words, take turns reading your lists.'),
              buildBodyBlock('If two people got the same word, both of you cross it off your lists. Otherwise, it counts as points!'),
              buildBodyBlock('Word Rules'),
              ...['English words', 'Archaic', 'Informal', 'Proper adjectives'].map((String instruction) => buildRuleItem(
                const Icon(Icons.check_circle_outline_outlined, color: isPointsColor),
                instruction,
              )),
              ...['Dialectal', 'Obsolete', 'Slang', 'Proper nouns'].map((String instruction) => buildRuleItem(
                const Icon(Icons.highlight_off_rounded, color: isNotWordColor),
                instruction,
              )),
              buildBodyBlock('Whoever gets the most points wins.'),
              buildSpace(),
              buildHeaderBlock('That\'s it! Happy Woggling!!'),
              buildSpace(),
            ],
          ),
        ),
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  final double percent;
  final double start;
  final List<Offset> points;

  LinePainter(this.percent, this.start, this.points);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Constants.primaryColor.withOpacity(0.6)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    double singleLinePercent = 1 / (points.length - 1);
    for (int i = 0; i < points.length - 1; i++) {
      double currentLinePercent = percent < singleLinePercent * i
        ? 0
        : (percent - singleLinePercent * i) / singleLinePercent;
      if (currentLinePercent > 1) { currentLinePercent = 1; }
      if (currentLinePercent > 0) {
        Offset p1 = points[i];
        Offset p2 = Offset(points[i].dx + (points[i + 1].dx - points[i].dx) * currentLinePercent, points[i].dy + (points[i + 1].dy - points[i].dy) * currentLinePercent);
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
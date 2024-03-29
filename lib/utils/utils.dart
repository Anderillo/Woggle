import 'dart:convert';
import 'dart:math';

import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart' hide Key;
import 'package:flutter/services.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:http/http.dart';
import 'package:woggle/board/dice.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

Future<String> getDefinition(String word) async {
  Response definition = await get(Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word')).timeout(const Duration(seconds: 3));
  return jsonDecode(definition.body)[0]['meanings'][0]['definitions'][0]['definition'];
}

void showLoader(BuildContext context) {
  Loader.show(
    context,
    progressIndicator: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary,),
    overlayColor: Theme.of(context).canvasColor.withOpacity(0.2),
  );
}
void hideLoader() => Loader.hide();

String convertStringToEmojis(String boardString) {
  int dimension = sqrt(max(boardString.replaceAll('QU', 'Q').length, 1)).ceil();
  String emojiString = '';
  for (int j = 0; j < dimension; j++) { emojiString += '━━━'; }
  emojiString += '\n|';
  for (int i = 0; i < boardString.length; i++) {
    String letter = boardString[i];
    if (i < boardString.length - 1 && boardString[i] == 'Q' && boardString[i + 1] == 'U') {
      letter += boardString[i + 1];
      boardString = boardString.substring(0, i + 1) + boardString.substring(i + 2);
    }
    emojiString += EMOJI_ICONS[letter]!;
    if ((i + 1) % dimension == 0) {
      if (i < boardString.length - 1) {
        emojiString += '|\n|';
        for (int j = 0; j < dimension; j++) { emojiString += '  　  '; }
        emojiString += '|\n|';
      }
      else {
        emojiString += '|\n';
        for (int j = 0; j < dimension; j++) { emojiString += '━━━'; }
      }
    }
  }
  return emojiString;
}

Future<String> boardSecrets(String boardString, {required bool encrypt}) async {
  Map<String, dynamic> secrets = json.decode(await rootBundle.loadString('assets/secrets.json'));
  Key key = Key.fromBase64(secrets['encryption_key']);
  IV iv = IV.fromBase64(secrets['encryption_iv']);
  Encrypter encrypter = Encrypter(AES(key));
  if (!encrypt) { return encrypter.decrypt(Encrypted.fromBase64(boardString), iv: iv); }
  return encrypter.encrypt(boardString, iv: iv).base64;
}

int getPointsFromWordLength(int wordLength) {
  if (wordLength < 3) { return 0; }
  else if (wordLength == 3 || wordLength == 4) { return 1; }
  else if (wordLength == 5) { return 2; }
  else if (wordLength == 6) { return 3; }
  else if (wordLength == 7) { return 5; }
  else if (wordLength >= 8) { return 11; }
  return -1;
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

void showSnackBar(BuildContext context, String message) {
  SnackBar snackBar = SnackBar(
    content: Text(message),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
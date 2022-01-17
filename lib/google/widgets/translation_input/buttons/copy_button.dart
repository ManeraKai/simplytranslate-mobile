import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/main_localizations.dart';

class CopyToClipboardButton extends StatelessWidget {
  final text;
  const CopyToClipboardButton(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onPressed: text == ''
          ? null
          : () => Clipboard.setData(ClipboardData(text: text)).then(
                (value) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: Duration(seconds: 2),
                    width: 160,
                    content: Text(
                      AppLocalizations.of(context)!.copied_to_clipboard,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
      icon: Icon(Icons.copy),
    );
  }
}
import 'package:flutter/material.dart';
import 'app_translations.dart';

extension TranslationExtension on String {
  String tr(BuildContext context) {
    return AppLocalizations.of(context)!.translate(this);
  }
}

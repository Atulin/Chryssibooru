import 'package:flutter/material.dart';

class Markup {
  static RegExp url = new RegExp(r'/"([^"]+)":(\S+)/i');

  static parseToHtml(String text) {
    String out = 'x ';
    Iterable<Match> matches = url.allMatches(text);
    for (var m in matches) {
      debugPrint(m.toString());
      out += m.toString();
    }
    out += text;
    return out;
  }
}
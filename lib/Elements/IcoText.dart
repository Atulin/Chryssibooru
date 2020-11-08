import 'package:flutter/material.dart';

class IcoText extends StatelessWidget {
  const IcoText(
      {Key key,
      @required this.text,
      @required this.icon,
      @required this.color,
      this.reverse = false})
      : super(key: key);

  final String text;
  final IconData icon;
  final Color color;

  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
        ),
        Text(
          text,
          style: TextStyle(color: color),
        ),
      ],
      textDirection: reverse
        ? TextDirection.rtl
        : TextDirection.ltr,
    );
  }
}

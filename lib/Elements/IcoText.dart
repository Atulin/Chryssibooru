import 'package:material_ui/material_ui.dart';

class IcoText extends StatelessWidget {
  const IcoText({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    this.reverse = false,
  });

  final String text;
  final IconData icon;
  final Color color;

  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: reverse ? TextDirection.rtl : TextDirection.ltr,
      children: [
        Icon(icon, color: color),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }
}

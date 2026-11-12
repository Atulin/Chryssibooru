import 'package:chryssibooru/Enums/EQuality.dart';
import 'package:flutter/material.dart';
import 'package:chryssibooru/Enums/ESortMethod.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.safe,
    required this.questionable,
    required this.explicit,
    required this.safeChanged,
    required this.questionableChanged,
    required this.explicitChanged,
    required this.quality,
    required this.qualityChanged,
    required this.sortMethod,
    required this.sortMethodChanged,
  });

  final bool safe;
  final bool questionable;
  final bool explicit;

  final ValueChanged<bool> safeChanged;
  final ValueChanged<bool> questionableChanged;
  final ValueChanged<bool> explicitChanged;

  final Quality quality;
  final ValueChanged<Quality> qualityChanged;

  final ESortMethod sortMethod;
  final ValueChanged<ESortMethod> sortMethodChanged;

  @override
  FilterSheetState createState() => FilterSheetState();
}

class FilterSheetState extends State<FilterSheet> {
  bool _safe = true;
  bool _questionable = false;
  bool _explicit = false;

  Quality? _quality;
  ESortMethod? _sortMethod;

  @override
  void initState() {
    _safe = widget.safe;
    _questionable = widget.questionable;
    _explicit = widget.explicit;
    _quality = widget.quality;
    _sortMethod = widget.sortMethod;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CheckboxListTile(
          title: Text('Safe'),
          value: _safe,
          onChanged: (bool? newValue) {
            setState(() {
              _safe = newValue ?? false;
              widget.safeChanged(_safe);
            });
          },
          dense: true,
        ),
        CheckboxListTile(
          title: Text('Questionable'),
          value: _questionable,
          onChanged: (bool? newValue) {
            setState(() {
              _questionable = newValue ?? false;
              widget.questionableChanged(_questionable);
            });
          },
          dense: true,
        ),
        CheckboxListTile(
          title: Text('Explicit'),
          value: _explicit,
          onChanged: (bool? newValue) {
            setState(() {
              _explicit = newValue ?? false;
              widget.explicitChanged(_explicit);
            });
          },
          dense: true,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Text('Image quality:'),
            ),
            DropdownButton<Quality>(
              value: _quality,
              items: Quality.values.map((Quality q) {
                return DropdownMenuItem<Quality>(value: q, child: Text(q.name));
              }).toList(),
              onChanged: (Quality? q) {
                if (q == null) return;
                setState(() {
                  _quality = q;
                  widget.qualityChanged(q);
                });
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Text('Sort by:'),
            ),
            DropdownButton<ESortMethod>(
              value: _sortMethod,
              items: ESortMethod.values.map((ESortMethod s) {
                return DropdownMenuItem<ESortMethod>(
                  value: s,
                  child: Text(s.name()),
                );
              }).toList(),
              onChanged: (ESortMethod? s) {
                if (s == null) return;
                setState(() {
                  _sortMethod = s;
                  widget.sortMethodChanged(s);
                });
              },
            ),
          ],
        ),
        ListTile(),
      ],
    );
  }
}

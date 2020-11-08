import 'package:chryssibooru/Helpers.dart';
import 'package:flutter/material.dart';

class FilterSheet extends StatefulWidget {
  FilterSheet({
    @required this.safe, @required this.questionable, @required this.explicit,
    @required this.safeChanged, @required this.questionableChanged, @required this.explicitChanged,
    @required this.quality, @required this.qualityChanged,
    @required this.sortMethod, @required this.sortMethodChanged
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
  _FilterSheet createState() => _FilterSheet();
}

class _FilterSheet extends State<FilterSheet> {
  bool _safe;
  bool _questionable;
  bool _explicit;

  Quality _quality;
  ESortMethod _sortMethod;

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
    return new Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        new CheckboxListTile(
          title: new Text('Safe'),
          value: _safe,
          onChanged: (bool newValue) {
            setState(() {
              _safe = newValue;
              widget.safeChanged(newValue);
            });
          },
          dense: true,
        ),
        new CheckboxListTile(
          title: new Text('Questionable'),
          value: _questionable,
          onChanged: (bool newValue) {
            setState(() {
              _questionable = newValue;
              widget.questionableChanged(newValue);
            });
          },
          dense: true,
        ),
        new CheckboxListTile(
          title: new Text('Explicit'),
          value: _explicit,
          onChanged: (bool newValue) {
            setState(() {
              _explicit = newValue;
              widget.explicitChanged(newValue);
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

            new DropdownButton<Quality>(
              value: _quality,
                items: Quality.values.map((Quality q) {
                  return DropdownMenuItem<Quality> (
                    value: q,
                    child: Text(q.toString().split('.')[1]),
                  );
                }).toList(),
                onChanged: (Quality q) {
                  setState(() {
                    _quality = q;
                    widget.qualityChanged(q);
                  });
                }
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

            new DropdownButton<ESortMethod>(
                value: _sortMethod,
                items: ESortMethod.values.map((ESortMethod s) {
                  return DropdownMenuItem<ESortMethod> (
                    value: s,
                    child: Text(s.toString().split('.')[1]),
                  );
                }).toList(),
                onChanged: (ESortMethod s) {
                  setState(() {
                    _sortMethod = s;
                    widget.sortMethodChanged(s);
                  });
                }
            ),
          ],
        ),
        new ListTile(

        ),
      ],
    );
  }
}
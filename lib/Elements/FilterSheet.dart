import 'package:flutter/material.dart';

class FilterSheet extends StatefulWidget {
  FilterSheet({
    @required this.safe, @required this.questionable, @required this.explicit,
    @required this.safeChanged, @required this.questionableChanged, @required this.explicitChanged
  });

  final bool safe;
  final bool questionable;
  final bool explicit;
  final ValueChanged safeChanged;
  final ValueChanged questionableChanged;
  final ValueChanged explicitChanged;

  @override
  _FilterSheet createState() => _FilterSheet();
}

class _FilterSheet extends State<FilterSheet> {
  bool _safe;
  bool _questionable;
  bool _explicit;

  @override
  void initState() {
    _safe = widget.safe;
    _questionable = widget.questionable;
    _explicit = widget.explicit;
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
        new ListTile(

        )
      ],
    );
  }
}
import 'package:chryssibooru/API.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryModal extends StatefulWidget {
  HistoryModal({@required this.repo});

  final DerpisRepo repo;

  @override
  _HistoryModal createState() => _HistoryModal();
}

class _HistoryModal extends State<HistoryModal> {
  List<String> _history = List<String>();
  DerpisRepo _repo;

  @override
  void initState() {
    _repo = widget.repo;
    super.initState();
  }

  void _getSearchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList("history");
    });
  }

  void _removeSearchFromHistory(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList("history") ?? new List<String>();

    if (history == null) return;

    history.removeAt(index);
    prefs.setStringList("history", history);

    _getSearchHistory();
  }

  @override
  Widget build(BuildContext context) {
    _getSearchHistory();
    return new AlertDialog(
      title: new Text("History"),
      content: new ListView.builder(
          itemCount: _history.length,
          itemBuilder: (BuildContext context, int index) {
            return new InkWell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_history[index]),
              ),
              onTap: () {
                if (_history[index] != _repo.query) {
                  _repo.derpis = new List<Derpi>();
                  _repo.page = 1;
                  _repo.query = _history[index];
                  setState(() {
                    _repo.loadDerpis();
                  });
                }
              },
              onLongPress: () {
                _removeSearchFromHistory(index);
              },
            );
          }),
      actions: <Widget>[
        // usually buttons at the bottom of the dialog
        new FlatButton(
          child: new Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

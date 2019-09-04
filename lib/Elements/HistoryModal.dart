import 'package:chryssibooru/API.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class HistoryModal extends StatefulWidget {
  HistoryModal({@required this.repo});

  final DerpisRepo repo;

  @override
  _HistoryModal createState() => _HistoryModal();
}

class _HistoryModal extends State<HistoryModal> {
  List<String> _history = List<String>();
  DerpisRepo _repo;
  Color _dismissColor = Colors.red;

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

  void _addSearchToFavourites(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList("history") ?? new List<String>();
    List<String> favourites = prefs.getStringList("favourites") ?? new List<String>();

    if (favourites == null) return;

    favourites.add(history[index]);
    prefs.setStringList("favourites", favourites);
  }

  @override
  Widget build(BuildContext context) {
    _getSearchHistory();
    return new AlertDialog(
      contentPadding: EdgeInsets.all(0.0),
      title: new Container(
        child: Text("History"),
        padding: EdgeInsets.only(bottom: 3.0),
        decoration: new BoxDecoration(
            border:
                new Border(bottom: BorderSide(width: 1.0, color: Colors.grey))),
      ),
      content: new ListView.builder(
          padding: EdgeInsets.only(top: 5.0),
          itemCount: _history != null ? _history.length : 0,
          itemBuilder: (BuildContext context, int index) {
            return new Dismissible(
                key: Key(_history[index]),
                background: Container(
                  color: _dismissColor,
                ),
                onDismissed: (direction) {
                  _removeSearchFromHistory(index);
                },
                child: InkWell(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
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
                    _addSearchToFavourites(index);
                  },
                ));
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

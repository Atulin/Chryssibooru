import 'package:chryssibooru/API.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavouritesModal extends StatefulWidget {
  FavouritesModal({@required this.repo});

  final DerpisRepo repo;

  @override
  _FavouritesModal createState() => _FavouritesModal();
}

class _FavouritesModal extends State<FavouritesModal> {
  List<String> _favourites = List<String>();
  DerpisRepo _repo;
  Color _dismissColor = Colors.red;

  @override
  void initState() {
    _repo = widget.repo;
    super.initState();
  }

  void _getSearchFavourites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _favourites = prefs.getStringList("favourites");
    });
  }

  void _removeSearchFromFavourites(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favourites = prefs.getStringList("favourites") ?? new List<String>();

    if (favourites == null) return;

    favourites.removeAt(index);
    prefs.setStringList("favourites", favourites);

    _getSearchFavourites();
  }

  @override
  Widget build(BuildContext context) {
    _getSearchFavourites();
    return new AlertDialog(
      contentPadding: EdgeInsets.all(0.0),
      title: new Container(
        child: Text("Favourites"),
        padding: EdgeInsets.only(bottom: 3.0),
        decoration: new BoxDecoration(
            border:
                new Border(bottom: BorderSide(width: 1.0, color: Colors.grey))),
      ),
      content: new ListView.builder(
          padding: EdgeInsets.only(top: 5.0),
          itemCount: _favourites != null ? _favourites.length : 0,
          itemBuilder: (BuildContext context, int index) {
            return new Dismissible(
                key: Key(_favourites[index]),
                background: Container(
                  color: _dismissColor,
                ),
                onDismissed: (direction) {
                  _removeSearchFromFavourites(index);
                },
                child: InkWell(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
                    child: Text(_favourites[index]),
                  ),
                  onTap: () {
                    if (_favourites[index] != _repo.query) {
                      _repo.derpis = new List<Derpi>();
                      _repo.page = 1;
                      _repo.query = _favourites[index];
                      setState(() {
                        _repo.loadDerpis();
                      });
                    }
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

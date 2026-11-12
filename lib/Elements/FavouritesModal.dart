import 'package:chryssibooru/DerpisRepo.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavouritesModal extends StatefulWidget {
  const FavouritesModal({
    super.key,
    required this.repo,
    required this.callback,
  });

  final DerpisRepo repo;
  final ValueChanged<String> callback;

  @override
  FavouritesModalState createState() => FavouritesModalState();
}

class FavouritesModalState extends State<FavouritesModal> {
  List<String> _favourites = [];
  DerpisRepo? _repo;
  final Color _dismissColor = Colors.red;

  @override
  void initState() {
    _repo = widget.repo;
    _getSearchFavourites();
    super.initState();
  }

  void _getSearchFavourites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _favourites = prefs.getStringList('favourites') ?? [];
    });
  }

  void _removeSearchFromFavourites(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favourites = prefs.getStringList('favourites') ?? [];

    if (index < favourites.length) {
      favourites.removeAt(index);
      await prefs.setStringList('favourites', favourites);
    }

    _getSearchFavourites();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.all(0.0),
      title: Container(
        padding: EdgeInsets.only(bottom: 3.0),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(width: 1.0, color: Colors.grey)),
        ),
        child: Text("Favourites"),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          padding: EdgeInsets.only(top: 5.0),
          itemCount: _favourites.length,
          itemBuilder: (BuildContext context, int index) {
            return Dismissible(
              key: ValueKey('favourite-$index-${_favourites[index]}'),
              background: Container(color: _dismissColor),
              onDismissed: (direction) {
                _removeSearchFromFavourites(index);
              },
              child: InkWell(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                    top: 10.0,
                    bottom: 10.0,
                  ),
                  child: Text(_favourites[index]),
                ),
                onTap: () {
                  if (_favourites[index] != _repo!.query) {
                    _repo!.page = 1;
                    _repo!.query = _favourites[index];
                    widget.callback(_favourites[index]);
                    _repo!.newSearch();
                    Navigator.of(context).pop();
                  }
                },
              ),
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

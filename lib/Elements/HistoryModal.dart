import 'package:chryssibooru/DerpisRepo.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryModal extends StatefulWidget {
  const HistoryModal({super.key, required this.repo, required this.callback});

  final DerpisRepo repo;
  final ValueChanged<String> callback;

  @override
  HistoryModalState createState() => HistoryModalState();
}

class HistoryModalState extends State<HistoryModal> {
  List<String> _history = [];
  DerpisRepo? _repo;
  final Color _dismissColor = Colors.red;

  @override
  void initState() {
    _repo = widget.repo;
    _getSearchHistory();
    super.initState();
  }

  void _getSearchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _history = (prefs.getStringList('history') ?? []).reversed.toList();
    });
  }

  void _removeSearchFromHistory(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('history') ?? [];

    if (index < history.length) {
      history.removeAt(index);
      await prefs.setStringList('history', history);
    }

    _getSearchHistory();
  }

  void _addSearchToFavourites(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('history') ?? [];
    List<String> favourites = prefs.getStringList('favourites') ?? [];

    if (index < history.length) {
      favourites.add(history[index]);
      await prefs.setStringList('favourites', favourites);
    }
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
        child: Text("History"),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          padding: EdgeInsets.only(top: 5.0),
          itemCount: _history.length,
          itemBuilder: (BuildContext context, int index) {
            // Index in the stored (non-reversed) list.
            final storedIndex = _history.length - 1 - index;
            return Dismissible(
              key: ValueKey('history-$storedIndex-${_history[index]}'),
              background: Container(color: _dismissColor),
              onDismissed: (direction) {
                _removeSearchFromHistory(storedIndex);
              },
              child: InkWell(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                    top: 10.0,
                    bottom: 10.0,
                  ),
                  child: Text(_history[index]),
                ),
                onTap: () {
                  if (_history[index] != _repo!.query) {
                    _repo!.page = 1;
                    _repo!.query = _history[index];
                    widget.callback(_history[index]);
                    _repo!.newSearch();
                    Navigator.of(context).pop();
                  }
                },
                onLongPress: () {
                  _addSearchToFavourites(storedIndex);
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

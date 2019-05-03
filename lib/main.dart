import 'dart:async';

import 'package:chryssibooru/API.dart';
import 'package:chryssibooru/ImageList.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chryssibooru',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        fontFamily: 'Montserrat',
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ScrollController _scrollController;

  String _key = "";

  bool _safe = true;
  bool _questionable = false;
  bool _explicit = false;

  String _query = "";

  int _page = 1;

  Future<List<Derpi>> _derpis;

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(_loadDerpisListener);
    super.initState();
  }

  void _loadDerpisListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
      _loadDerpis();
    }
  }

  void _loadDerpis() {
    setState(() {
      _derpis = searchImages(_query, _safe, _questionable, _explicit, _key, _page);
    });
  }

  void _saveKey(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("key", key);
  }

  void _getKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _key = prefs.getString("key");
  }

  @override
  Widget build(BuildContext context) {
    _getKey();
    return Scaffold(
//      appBar: AppBar(
//        title: Text(widget.title),
//      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<List<Derpi>>(
              future: _derpis,// fetchDerpi("https://derpibooru.org/search.json?q=pinkie+pie"),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return new Expanded(
                    child: new GridView.builder(
                      controller: _scrollController,
                      itemCount: snapshot.data.length,
                      cacheExtent: 0.5,
                      physics: BouncingScrollPhysics(),
                      gridDelegate: new SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200.0,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0),
                      itemBuilder: (BuildContext context, int index) {
                        return new GestureDetector(
                          onTap: () {},
                          child: new Card(
                            child: Padding(
                              padding: EdgeInsets.all(0.2),
                              child: ClipRRect(
                                borderRadius: new BorderRadius.all(Radius.circular(10.0)),
                                child: new CachedNetworkImage(
                                  imageUrl: "https:"+snapshot.data[index].representations.medium,
                                  placeholder: (context, url) => new Image(image: AssetImage('assets/logo.png')),
                                  errorWidget: (context, url, error) => new Icon(Icons.error),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0)
                              )
                            ),
                            elevation: 5,
                          ),
                        );
                      },
                    )
                  );
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }

                // By default, show a loading spinner
                return new Image(image: AssetImage('assets/logo.png'));
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Transform.translate(
        offset: Offset(0.0, -1 * MediaQuery.of(context).viewInsets.bottom),
        child: BottomAppBar(
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: new Icon(Icons.menu),
                onPressed: () {},
              ),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Please enter a search term'
                  ),
                  onSubmitted: (text) {
                    _query = text;
                    _loadDerpis();
                  },
                ),
              ),
              IconButton(
                icon: new Icon(Icons.filter_list),
                onPressed: () {
                  filterSheet();
                },
              ),
            ],
          ),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  // BOTTOM SHEET
  void filterSheet() {
    showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new CheckboxListTile(
                title: new Text('Safe'),
                value: _safe,
                onChanged: (bool newValue) {
                  setState(() {
                    _safe = newValue;
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
                  });
                },
                dense: true,
              ),
              new ListTile(
                leading: new Icon(Icons.photo_album),
                title: new Text('Photos'),
                onTap: () => () {},
              ),
              new ListTile(
                leading: new Icon(Icons.videocam),
                title: new Text('Video'),
                onTap: () => () {},
              ),
              new TextField(
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter your API key'
                ),
                onSubmitted: (text) {
                  _saveKey(text);

                },
              )
            ],
          );
        });
  }
}

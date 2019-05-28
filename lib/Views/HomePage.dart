import 'package:cached_network_image/cached_network_image.dart';
import 'package:chryssibooru/API.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:chryssibooru/Views/ImageViewer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';



class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  HomePageState createState() => HomePageState();
}



class HomePageState extends State<HomePage> {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey();

  ScrollController _scrollController;
  double lastScrollPosition = 0.0;

  DerpisRepo repo;

  @override
  didChangeDependencies() {
    repo = Provider.of<DerpisRepo>(context);

    super.didChangeDependencies();
  }

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(_loadDerpisListener);
    super.initState();
  }

  void _loadDerpisListener() {
    if (_scrollController.position.maxScrollExtent - _scrollController.offset < 400.0
        && !_scrollController.position.outOfRange
        && repo.loaded) {
      repo.page++;
      setState(() {
        repo.loadDerpis();
      });
    }
  }

  void _saveKey(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("key", key);
  }

  void _getKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    repo.key = prefs.getString("key") ?? "";
  }


  @override
  Widget build(BuildContext context) {
    _getKey();

    return Scaffold(
      key: _scaffoldKey,
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Expanded(
                child: (){
                  if (repo.derpis == null || repo.derpis.length <= 0) {
                    return new Image(image: AssetImage('assets/logo-medium.png'));
                  } else {
                    return new GridView.builder(
                      controller: _scrollController,
                      itemCount: repo.derpis.length,
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
                                borderRadius:new BorderRadius.all(Radius.circular(10.0)),
                                child: (){
                                  if(repo.derpis[index].mimeType != MimeType.VIDEO_WEBM){
                                    return new CachedNetworkImage(
                                      imageUrl:"https:" + repo.derpis[index].representations.thumb,
                                      placeholder: (context, url) => new Image(image: AssetImage('assets/logo-medium.png')),
                                      errorWidget: (context, url, error) => new Icon(Icons.error),
                                      fit: BoxFit.cover,
                                    );
                                  } else {
                                    return new Center(
                                      child: Text('WEBM'),
                                    );
                                  }
                                }()
                              ),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                            elevation: 5,
                          ),
                          onTapDown: (_) {
//                            Navigator.pushNamed(context, '/view', arguments: index);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ImageViewer(
                                    index: index,
                                  )),
                            );
                          },
                        );
                      },
                    );
                  }
                }()

            )
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
                onPressed: () {
                  _scaffoldKey.currentState.openDrawer();
                },
              ),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Please enter a search term'),
                  onSubmitted: (text) {
                    if (text != repo.query) {
                      repo.derpis = new List<Derpi>();
                      repo.page = 1;
                      repo.setParams(text);
                      setState(() {
                        repo.loadDerpis();
                      });
                    }
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

      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              child: Image(image: AssetImage('assets/logo-medium.png')),
              decoration: BoxDecoration(
                  color: Color.fromARGB(255, 15, 84, 108)
              ),
            ),
            ListTile(
              title: Text("Enter API key"),
              subtitle: Text("Get it on Derpibooru in account settings", style: TextStyle(fontSize: 10.0)),
              onTap: showKeySheet,
            )
          ],
        ),
      ),
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
                value: repo.safe,
                onChanged: (bool newValue) {
                  setState(() {
                    repo.safe = newValue;
                  });
                },
                dense: true,
              ),
              new CheckboxListTile(
                title: new Text('Questionable'),
                value: repo.questionable,
                onChanged: (bool newValue) {
                  setState(() {
                    repo.questionable = newValue;
                  });
                },
                dense: true,
              ),
              new CheckboxListTile(
                title: new Text('Explicit'),
                value: repo.explicit,
                onChanged: (bool newValue) {
                  setState(() {
                    repo.explicit = newValue;
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
            ],
          );
        });
  }

  void showKeySheet() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    showModalBottomSheet<void>(
        context: _scaffoldKey.currentContext,
        builder: (BuildContext context) {
          return Padding(
            padding: EdgeInsets.fromLTRB(10.0, 1.0, 10.0, MediaQuery.of(context).viewInsets.bottom),
            child: new TextField(
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: prefs.getString("key") ?? "Your API key here"
              ),
              onSubmitted: (text) {
                _saveKey(text);
              },
              autofocus: true,
            ),
          );
        }
    );
  }
}
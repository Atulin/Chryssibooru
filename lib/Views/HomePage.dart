import 'package:chryssibooru/API.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:chryssibooru/Elements/FavouritesModal.dart';
import 'package:chryssibooru/Elements/FilterSheet.dart';
import 'package:chryssibooru/Elements/HistoryModal.dart';
import 'package:chryssibooru/Views/ImageViewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_advanced_networkimage/transition.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Helpers.dart';



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

  List<String> searchHistory;

  bool _s = true;
  bool _q = false;
  bool _e = false;

  int cacheSize = 0;
  void getCacheSize() async {
    var cs = await DiskCache().cacheSize();
    setState(() {
      cacheSize = cs;
    });
  }
  void cleanCache() async {
    await DiskCache().clear();
    getCacheSize();
  }


  @override
  didChangeDependencies() {
    repo = Provider.of<DerpisRepo>(context);

    super.didChangeDependencies();
  }

  @override
  void initState() {
    getCacheSize();
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
    setState(() {
      repo.key = key;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("key", key);
  }

  void _getKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      repo.key = prefs.getString("key") ?? "";
    });
  }

  void _saveSearch(String search) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList("history") ?? new List<String>();

    if (history != null && history.indexOf(search) < 0) {
      if (history.length >= 50) history.removeAt(0);
      history.add(search);
    } else return;

    prefs.setStringList("history", history);
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
                      itemBuilder: (BuildContext c, int index) {
                        return new GestureDetector(
                          child: new Card(
                            child: Padding(
                              padding: EdgeInsets.all(0.2),
                              child: ClipRRect(
                                borderRadius:new BorderRadius.all(Radius.circular(10.0)),
                                child: (){
                                  String url = "https:" + repo.derpis[index].representations.thumb;
                                  if(repo.derpis[index].mimeType == MimeType.VIDEO_WEBM){
                                    List<String> parts = url.split('.');
                                    parts[parts.length-1] = 'gif';
                                    url = parts.join('.');
                                  }
                                  return new TransitionToImage(
                                    image: AdvancedNetworkImage(
                                        url,
                                        useDiskCache: true,
                                        cacheRule: CacheRule(maxAge: const Duration(days: 7))
                                    ),
                                    placeholder: SvgPicture.asset('assets/logo.svg'),
                                    loadingWidgetBuilder: (double progress) => Center(
                                      child: CircularProgressIndicator(
                                        value: progress,
                                        semanticsValue: progress.toString(),
                                      ),
                                    ),
                                    fit: BoxFit.cover,
                                  );
                                }()
                              ),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                            elevation: 5,
                          ),
                          onTap: () {
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
                    if (text != repo.query || _s != repo.safe || _q != repo.questionable || _e != repo.explicit) {
                      repo.derpis = new List<Derpi>();
                      repo.page = 1;
                      repo.query = text;
                      repo.setRatings(_s, _q, _e);
                      _saveSearch(text);
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
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return FilterSheet(
                        safe: _s,
                        safeChanged: (value) {
                          _s = value;
                        },
                        questionable: _q,
                        questionableChanged: (value) {
                          _q = value;
                        },
                        explicit: _e,
                        explicitChanged: (value) {
                          _e = value;
                        },
                      );
                    },
                  );
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
              child: SvgPicture.asset('assets/logo.svg'),
              decoration: BoxDecoration(
                color: Colors.black
              ),
            ),
            ListTile(
              title: Text("Enter API key"),
              subtitle: Text("Get it on Derpibooru in account settings", style: TextStyle(fontSize: 12.0)),
              leading: Icon(Icons.vpn_key),
              onTap: showKeySheet,
            ),
            ListTile(
              title: Text("Cache size: "+parseFileSize(cacheSize)),
              subtitle: Text("Tap to recalculate, hold to clean", style: TextStyle(fontSize: 12.0)),
              leading: Icon(Icons.folder_open),
              onTap: getCacheSize,
              onLongPress: cleanCache,
            ),
            ListTile(
              title: Text("History"),
              subtitle: Text("See your previous searches", style: TextStyle(fontSize: 12.0)),
              leading: Icon(Icons.history),
              onTap:  () => showDialog(
                context: context,
                builder: (BuildContext context) {
                  return new HistoryModal(
                    repo: repo,
                  );
                }
              ),
            ),
            ListTile(
              title: Text("Favourites"),
              subtitle: Text("See your favourite searches", style: TextStyle(fontSize: 12.0)),
              leading: Icon(Icons.favorite),
              onTap:  () => showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return new FavouritesModal(
                      repo: repo,
                    );
                  }
              ),
            ),
            Divider(),
            ListTile(
              title: Text("Buy me a coffe"),
              subtitle: Text("Or two, I don't judge", style: TextStyle(fontSize: 12.0)),
              leading: Icon(Icons.free_breakfast),
              onTap: () => openInBrowser("https://ko-fi.com/angius"),
            ),
            AboutListTile(
              applicationIcon: SvgPicture.asset('assets/logo.svg', height: 20, width: 20,),
              icon: Icon(Icons.info_outline),
              aboutBoxChildren: <Widget>[
                ListTile(
                  title: Text("Github"),
                  leading: Icon(Icons.compare_arrows),
                  onTap: () => openInBrowser("https://github.com/Atulin/Chryssibooru"),
                  dense: true,
                ),
              ]
            )
          ],
        ),
      ),
    );
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
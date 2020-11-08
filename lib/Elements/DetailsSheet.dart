import 'package:chryssibooru/API/v2/API.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:chryssibooru/Elements/IcoText.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share/share.dart';
import 'package:provider/provider.dart' as p;

import '../Helpers.dart';

class DetailsSheet extends StatefulWidget {
  DetailsSheet({
    @required this.derpi
  });

  final Derpi derpi;

  @override
  _DetailsSheet createState() => _DetailsSheet();
}

class _DetailsSheet extends State<DetailsSheet> {

  Derpi _derpi;
  List<Tag> _tags;
  DerpisRepo _repo;


  @override
  void didChangeDependencies() {
    _repo = p.Provider.of<DerpisRepo>(context);
    super.didChangeDependencies();
  }

  @override
  void initState(){
    _derpi = widget.derpi;
    _tags = widget.derpi.tags;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8.0, vertical: 1.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(_derpi.id.toString()),
              ButtonBar(
                children: <Widget>[
                  Container(
                    height: 30,
                    width: 30,
                    child: InkWell(
                      borderRadius:
                      BorderRadius.all(Radius.circular(50.0)),
                      child: Icon(Icons.share),
                      onTap: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Container(
                                height: 100.0,
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    FlatButton(
                                      onPressed: () => Share.share("https://derpibooru.org/" +_derpi.id.toString()),
                                      child:Text("Derpibooru post"),
                                    ),
                                    FlatButton(
                                      onPressed: () => Share.share("https:" + _derpi.representations.full),
                                      child: Text("Direct image"),
                                    )
                                  ],
                                ),
                              );
                            });
                      },
                      onLongPress: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("Share"),
                              );
                            });
                      },
                    ),
                  ),
                  Container(
                    height: 30,
                    width: 30,
                    child: InkWell(
                      borderRadius:
                      BorderRadius.all(Radius.circular(50.0)),
                      child: Icon(Icons.link),
                      onTap: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Container(
                                height: 100.0,
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    FlatButton(
                                      onPressed: () => openInBrowser("https://derpibooru.org/" +_derpi.id.toString()),
                                      child:Text("Derpibooru post"),
                                    ),
                                    FlatButton(
                                      onPressed: () => openInBrowser("https:" +_derpi.representations.full),
                                      child: Text("Direct image"),
                                    )
                                  ],
                                ),
                              );
                            });
                      },
                      onLongPress: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("Open in browser"),
                              );
                            });
                      },
                    ),
                  ),
                  Container(
                    height: 30,
                    width: 30,
                    child: InkWell(
                      borderRadius:
                      BorderRadius.all(Radius.circular(50.0)),
                      child: Icon(Icons.content_copy),
                      onTap: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Container(
                                height: 100.0,
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    FlatButton(
                                      onPressed: () => Clipboard.setData(new ClipboardData(
                                          text: "https://derpibooru.org/" +_derpi.id.toString())
                                      ),
                                      child:
                                      Text("Derpibooru post"),
                                    ),
                                    FlatButton(
                                      onPressed: () => Clipboard.setData(new ClipboardData(
                                          text: "https:" + _derpi.representations.full)
                                      ),
                                      child: Text("Direct image"),
                                    )
                                  ],
                                ),
                              );
                            });
                      },
                      onLongPress: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("Copy direct link"),
                              );
                            });
                      },
                    ),
                  ),
                  Container(
                    height: 30,
                    width: 30,
                    child: InkWell(
                      borderRadius:
                      BorderRadius.all(Radius.circular(50.0)),
                      child: Icon(Icons.file_download),
                      onTap: () =>
                          downloadImage(_derpi.representations.full),
                      onLongPress: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("Download"),
                              );
                            });
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        ConstrainedBox(
          constraints: new BoxConstraints(maxHeight: 100.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Spacer(flex: 10),
                IcoText(
                    text: _derpi.commentCount.toString(),
                    icon: Icons.chat_bubble_outline,
                    color: Color.fromARGB(255, 176, 153, 221)
                ),
                Spacer(),
                IcoText(
                    text: _derpi.faves.toString(),
                    icon: Icons.star_border,
                    color: Colors.amber,
                ),
                Spacer(),
                IcoText(
                    text: (_derpi.score - _derpi.downvotes).toString(),
                    icon: Icons.arrow_upward,
                    color: Colors.green,
                    reverse: true,
                ),
                Text(_derpi.score.toString()),
                IcoText(
                    text: _derpi.downvotes.toString(),
                    icon: Icons.arrow_downward,
                    color: Colors.red
                ),
                Spacer(flex: 10),
              ],
            ),
          ),
        ),
        ConstrainedBox(
          constraints: new BoxConstraints(maxHeight: 100.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 8.0, vertical: 4.0),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Text(_derpi.description),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 4.0, vertical: 1.0),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Wrap(
                spacing: 5,
                runSpacing: -5,
                alignment: WrapAlignment.center,
                children: [
                  for (final tag in _tags)
                    GestureDetector(
                      child: Chip(
                        padding: EdgeInsets.all(0),
                        label: Text(tag.label),
                        backgroundColor: {
                          TagType.ARTIST: Colors.blue,
                          TagType.OC: Colors.green,
                          TagType.SPOILER: Colors.red,
                        }[tag.type] ??
                            Colors.grey,
                      ),
                      onTap: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (BuildContext c) {
                              return Container(
                                height: 150.0,
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    FlatButton(
                                      onPressed: () async {
                                        _repo.derpis = new List<Derpi>();
                                        _repo.addTag(tag.label);
                                        await _repo.loadDerpis();
                                        // setState(() {
                                        //   _id = 0;
                                        //   _pageController
                                        //       .jumpToPage(0);
                                        // });
                                      },
                                      child: Text("Add to search"),
                                    ),
                                    FlatButton(
                                      onPressed: () async {
                                        _repo.derpis = new List<Derpi>();
                                        _repo.removeTag(tag.label);
                                        await _repo.loadDerpis();
                                        // setState(() {
                                        //   _id = 0;
                                        //   _pageController
                                        //       .jumpToPage(0);
                                        // });
                                      },
                                      child: Text("Remove from search"),
                                    ),
                                    FlatButton(
                                      onPressed: () async {
                                        _repo.derpis = new List<Derpi>();
                                        _repo.query = tag.label;
                                        await _repo.loadDerpis();
                                        // setState(() {
                                        //   _id = 0;
                                        //   _pageController
                                        //       .jumpToPage(0);
                                        // });
                                      },
                                      child: Text("New search"),
                                    )
                                  ],
                                ),
                              );
                            });
                      },
                    )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }



}
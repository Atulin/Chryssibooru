import 'package:chryssibooru/DerpisRepo.dart';
import 'package:chryssibooru/Views/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Provider<DerpisRepo>(
      builder: (c) => DerpisRepo(),
      child: MaterialApp(
        title: 'Chryssibooru',
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.teal,
          fontFamily: 'Montserrat',
        ),
home: HomePage(),
//        initialRoute: '/',
//        routes: <String, WidgetBuilder>{
//          '/': (context) => HomePage(title: 'Flutter Demo Home Page'),
//          '/view': (context) => ImageViewer(title: 'Flutter Demo Home Page'),
//        },
      ),
    );
  }
}
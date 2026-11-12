import 'package:chryssibooru/DerpisRepo.dart';
import 'package:chryssibooru/Views/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as p;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return p.ListenableProvider<DerpisRepo>(
      create: (c) => DerpisRepo(),
      child: MaterialApp(
        title: 'Chryssibooru',
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.teal,
          fontFamily: 'Montserrat',
          // Material 2 is used intentionally: the app's visual identity is
          // based on Material 2 component styling (BottomAppBar, Chips,
          // DropdownButton, Cards).
          useMaterial3: false,
        ),
        home: HomePage(),
      ),
    );
  }
}

import 'package:chryssibooru/DerpisRepo.dart';
import 'package:chryssibooru/Views/HomePage.dart';
import 'package:material_ui/material_ui.dart';
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
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.dark,
          ),
          fontFamily: 'Montserrat',
          // Material 3 is the default of the material_ui library.
        ),
        home: HomePage(),
      ),
    );
  }
}

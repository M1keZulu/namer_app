import 'dart:convert';
import 'dart:io';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

Future<void> createFile(var favorites) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/favorites.json');
  await file.writeAsString(jsonEncode(favorites));
}

Future<List<String>> readFile() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/favorites.json');
  if (await file.exists()) {
    var json = jsonDecode(await file.readAsString());
    var pairs = <String>[];
    for (var x in json) {
      pairs.add(x);
    }
    return pairs;
  }
  return <String>[];
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 250, 4, 148)),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var favorites = <String>[];

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  void toggleFavorite() async {
    final currentString = current.toString();
    if (favorites.contains(currentString)) {
      favorites.remove(currentString);
    } else {
      favorites.add(currentString);
    }
    await createFile(favorites);
    notifyListeners();
  }

  void deleteFavorite(String pair) {
    if (favorites.contains(pair)) {
      favorites.remove(pair);
      notifyListeners();
    }
  }

  void read() async {
    favorites = await readFile();
    notifyListeners();
  }

  void clearFavorites() {
    favorites = [];
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Provider.of<MyAppState>(context, listen: false).read();
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
      case 1:
        page = FavoritesPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: false,
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite),
                  label: Text('Favorites'),
                ),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: page,
            ),
          ),
        ],
      ),
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current.toString();

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: SizedBox(
                  width: pair.length * 20,
                  height: 100,
                  child: LayoutBuilder(builder: (context, constraints) {
                    double fontSize = constraints.maxWidth /
                        5; // Adjust this factor as needed
                    return Center(
                        child: Text(pair,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: fontSize,
                            )));
                  }))),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var favorites = appState.favorites;

    if (favorites.isEmpty) {
      return Center(child: Text("No Favorites added."));
    }

    return ListView(children: [
      ElevatedButton(
        onPressed: () {
          appState.clearFavorites();
        },
        child: Text('Clear'),
      ),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Text('You have ${favorites.length} favorites:'),
      ),
      for (var pair in favorites)
        ListTile(
          leading: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => appState.deleteFavorite(pair),
          ),
          title: Text(pair),
          enabled: true,
        ),
    ]);
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: pair.asPascalCase,
        ),
      ),
    );
  }
}

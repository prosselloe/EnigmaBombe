import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'enigma_screen.dart';
import 'bombe_screen.dart';
import 'history_screen.dart';
import 'turing_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => EnigmaState()),
        ChangeNotifierProvider(create: (context) => BombeState()),
      ],
      child: MaterialApp(
        title: 'Enigma & Bombe Simulator',
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.grey[900],
          scaffoldBackgroundColor: Colors.grey[850],
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey[900],
            elevation: 4,
          ),
          cardColor: Colors.grey[900],
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.yellow),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: Colors.grey[700],
            labelStyle: const TextStyle(color: Colors.white),
          ),
          textTheme: const TextTheme(
            titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white70),
          ),
          tabBarTheme: TabBarThemeData(
            labelColor: Colors.yellow,
            unselectedLabelColor: Colors.white70,
            indicator: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.yellow, width: 2)),
            ),
          ),
        ),
        home: const MainNavigator(),
      ),
    );
  }
}

class MainNavigator extends StatelessWidget {
  const MainNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Enigma & Bombe: Desxifrant la Història'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.lock_outline), text: 'Enigma'),
              Tab(icon: Icon(Icons.explore_outlined), text: 'Bombe'),
              Tab(icon: Icon(Icons.memory), text: 'Turing'),
              Tab(icon: Icon(Icons.history_edu_outlined), text: 'Història'),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [
              EnigmaScreen(),
              BombeScreen(),
              TuringScreen(),
              HistoryScreen(),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'pages/tasbih_page.dart';
import 'pages/qibla_compass.dart';
import 'pages/zikir_by_voice.dart';

void main() {
  runApp(const TapItApp());
}

class TapItApp extends StatelessWidget {
  const TapItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapIt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeNavigation(),
    );
  }
}

class HomeNavigation extends StatefulWidget {
  const HomeNavigation({super.key});

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _selectedIndex = 0;

  // ✅ Tabs (Pages)
  final List<Widget> _pages = [
    const TasbihPage(),
    const QiblaCompass(),
    const ZikirByVoicePage(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fingerprint),
            label: 'Tasbih',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Qibla',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'Zikir by Voice',
          ),
        ],
      ),

    );
  }
}

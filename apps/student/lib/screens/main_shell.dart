import 'package:flutter/material.dart';
import 'package:rankset_core/rankset_core.dart';

import 'home_screen.dart';
import 'practice_screen.dart';
import 'profile_screen.dart';
import 'ranking_screen.dart';

/// Primary navigation: Home, Practice, Rank, Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  PracticeMode _practiceMode = PracticeMode.exams;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            onOpenPractice: (mode) => setState(() {
              _practiceMode = mode;
              _index = 1;
            }),
          ),
          PracticeScreen(initialMode: _practiceMode),
          const RankingScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: pal.card,
        indicatorColor: pal.tint,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Practice'),
          NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined),
              selectedIcon: Icon(Icons.leaderboard),
              label: 'Rank'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

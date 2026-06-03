import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const CyberApp());
}

class CyberApp extends StatelessWidget {
  const CyberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Cercles lumineux en arrière-plan pour l'effet de lueur néon
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00FFCC).withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00FF66).withOpacity(0.1),
              ),
            ),
          ),
          
          // Contenu de la page active
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _pages[_currentIndex],
          ),
        ],
      ),
      
      // Barre de navigation style Glassmorphism floutée
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FFCC).withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              backgroundColor: Colors.white.withOpacity(0.05),
              selectedItemColor: const Color(0xFF00FFCC),
              unselectedItemColor: Colors.white38,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.bolt, size: 28), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.analytics, size: 28), label: 'Stats'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- PAGE 1 : ACCUEIL INTERACTIF ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _counter = 0;
  double _scale = 1.0;

  void _incrementCounter() {
    setState(() {
      _counter++;
      _scale = 0.85; // Effet d'enfoncement
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => _scale = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'PROJET NEXUS',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.black,
                letterSpacing: 2,
                color: Color(0xFF00FFCC),
                shadows: [Shadow(color: Color(0xFF00FFCC), blurRadius: 12)],
              ),
            ),
            const Text(
              'iOS Core Engine Actif',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const Spacer(),
            
            // Carte principale avec effet miroir / Glassmorphism
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.radar, size: 50, color: Color(0xFF00FF66)),
                        const SizedBox(height: 15),
                        const Text(
                          'PULSIONS DU SYSTÈME',
                          style: TextStyle(fontSize: 14, letterSpacing: 1.5, color: Colors.white38),
                        ),
                        const SizedBox(height: 5),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                          child: Text(
                            '$_counter',
                            key: ValueKey<int>(_counter),
                            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            
            // Bouton principal animé
            Center(
              child: AnimatedScale(
                scale: _scale,
                duration: const Duration(milliseconds: 100),
                child: GestureDetector(
                  onTap: _incrementCounter,
                  child: Container(
                    height: 65,
                    width: 65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00FFCC),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FFCC).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const Icon(Icons.add, color: Color(0xFF0B0F19), size: 32),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

// --- PAGE 2 : STATS / APERÇU DE LISTE SYSTÈME ---
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> modules = [
      {'name': 'Mémoire Tampon', 'status': 'Stable', 'icon': Icons.memory, 'color': const Color(0xFF00FFCC)},
      {'name': 'Liaison GitHub Actions', 'status': 'Prêt', 'icon': Icons.cloud_done, 'color': const Color(0xFF00FF66)},
      {'name': 'Chiffrement Signature', 'status': 'Bypass (--no-codesign)', 'icon': Icons.security, 'color': Colors.orangeAccent},
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'MONITEUR',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.black, letterSpacing: 2),
            ),
            const SizedBox(height: 25),
            
            // Génération de la liste animée de modules
            Expanded(
              child: ListView.builder(
                itemCount: modules.length,
                itemBuilder: (context, index) {
                  final mod = modules[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Icon(mod['icon'], color: mod['color'], size: 28),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mod['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(mod['status'], style: const TextStyle(color: Colors.white38, fontSize: 13)),
                            ],
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: mod['color']),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dart_ssh2/dart_ssh2.dart';

void main() {
  runApp(const CyberSSHApp());
}

class CyberSSHApp extends StatelessWidget {
  const CyberSSHApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070A12),
        primaryColor: const Color(0xFF00FFCC),
      ),
      home: const MainDashboard(),
    );
  }
}

// Modèle de données pour les serveurs sauvegardés
class SSHPreset {
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;

  SSHPreset({
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
  });
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedTab = 0;
  
  // Liste de presets en mémoire (Modulaire)
  final List<SSHPreset> _presets = [
    SSHPreset(name: 'VPS-Main-Server', host: '192.168.1.50', port: 22, username: 'root', password: 'password123'),
  ];

  // Commandes rapides pré-enregistrées
  final List<String> _quickCommands = [
    'ls -la',
    'top -b -n 1',
    'netstat -tuln',
    'python3 --version',
  ];

  // Variables pour la session active
  SSHClient? _client;
  SSHSession? _session;
  final List<String> _terminalLogs = ['[SYSTEM] Console prête. En attente de connexion...'];
  final TextEditingController _cmdController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isConnected = false;

  // Connexion SSH
  Future<void> _connectToSSH(SSHPreset preset) async {
    setState(() {
      _terminalLogs.add('[CONNECTING] Liaison vers ${preset.host}:${preset.port}...');
      _selectedTab = 1; // Basculer sur l'onglet Terminal
    });

    try {
      final socket = await SSHSocket.connect(preset.host, preset.port, timeout: const Duration(seconds: 10));
      final client = SSHClient(
        socket,
        username: preset.username,
        onPasswordRequest: () => preset.password,
      );

      // Attente de l'authentification
      await client.authenticated;
      final session = await client.shell();

      setState(() {
        _client = client;
        _session = session;
        _isConnected = true;
        _terminalLogs.add('[SUCCESS] Authentification réussie. Shell actif.\n');
      });

      // Écoute des paquets de retour du serveur
      session.stdout.transform(utf8.decoder).listen((data) {
        setState(() {
          _terminalLogs.add(data);
        });
        _scrollToBottom();
      });

      session.stderr.transform(utf8.decoder).listen((data) {
        setState(() {
          _terminalLogs.add('[ERROR] $data');
        });
        _scrollToBottom();
      });

    } catch (e) {
      setState(() {
        _terminalLogs.add('[FAIL] Erreur de connexion: $e');
      });
    }
  }

  // Envoi d'une commande au serveur
  void _sendCommand(String cmd) {
    if (_session == null || !_isConnected) return;
    if (cmd.trim().isEmpty) return;

    _session!.write(utf8.encode('$cmd\n') as Uint8List);
    _cmdController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PARADOX SSH', style: TextStyle(fontFamily: 'Courier', letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F1424),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 15),
            child: CircleAvatar(
              radius: 6,
              backgroundColor: _isConnected ? const Color(0xFF00FF66) : Colors.redAccent,
            ),
          )
        ],
      ),
      body: _selectedTab == 0 ? _buildPresetsTab() : _buildTerminalTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        backgroundColor: const Color(0xFF0F1424),
        selectedItemColor: const Color(0xFF00FFCC),
        unselectedItemColor: Colors.white38,
        onTap: (index) => setState(() => _selectedTab = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dns), label: 'Presets'),
          BottomNavigationBarItem(icon: Icon(Icons.terminal), label: 'Terminal'),
        ],
      ),
    );
  }

  // ONGLET 1 : Liste des Serveurs et Configuration
  Widget _buildPresetsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _presets.length,
      itemBuilder: (context, index) {
        final item = _presets[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00FFCC).withOpacity(0.15)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(15),
            leading: const Icon(Icons.terminal, color: Color(0xFF00FFCC), size: 35),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text('${item.username}@${item.host}:${item.port}', style: const TextStyle(fontFamily: 'Courier', color: Colors.white54)),
            trailing: const Icon(Icons.bolt, color: Color(0xFF00FF66)),
            onTap: () => _connectToSSH(item),
          ),
        );
      },
    );
  }

  // ONGLET 2 : Console et Boutons Modulaires
  Widget _buildTerminalTab() {
    return Column(
      children: [
        // Zone d'affichage des logs du terminal
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF020408),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Text(
                _terminalLogs.join('\n'),
                style: const TextStyle(fontFamily: 'Courier', fontSize: 13, color: Color(0xFF00FF66)),
              ),
            ),
          ),
        ),

        // BARRE MODULAIRE : Commandes rapides pré-enregistrées
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(
            children: _quickCommands.map((cmd) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  backgroundColor: const Color(0xFF1E293B),
                  side: BorderSide(color: const Color(0xFF00FFCC).withOpacity(0.3)),
                  label: Text(cmd, style: const TextStyle(fontFamily: 'Courier', color: Colors.white)),
                  onPressed: () => _sendCommand(cmd),
                ),
              );
            }).toList(),
          ),
        ),

        // Champ d'entrée de commandes
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _cmdController,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: const TextStyle(fontFamily: 'Courier', color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Exécuter une commande...',
                      hintStyle: TextStyle(color: Colors.white24),
                    ),
                    onSubmitted: _sendCommand,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF00FFCC)),
                onPressed: () => _sendCommand(_cmdController.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

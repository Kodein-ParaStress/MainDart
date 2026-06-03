import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const NetScannerApp());
}

class NetScannerApp extends StatelessWidget {
  const NetScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090D16),
      ),
      home: const ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _subnetController = TextEditingController(text: '192.168.1');
  final List<Map<String, dynamic>> _discoveredDevices = [];
  
  bool _isScanning = false;
  double _progress = 0.0;
  String _currentScanningIP = '';
  
  late AnimationController _radarController;

  // Liste des ports standards à tester sur chaque machine détectée
  final List<int> _commonPorts = [21, 22, 23, 80, 443, 445, 3000, 5000, 5500, 1234, 12345, 6767, 8080];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _subnetController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  // Fonction principale de scan asynchrone
  Future<void> _startNetworkScan() async {
    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
      _progress = 0.0;
    });
    _radarController.repeat();

    String subnet = _subnetController.text.trim();
    int totalHosts = 50; // Limité à 50 pour éviter les timeouts trop longs en arrière-plan

    for (int i = 1; i <= totalHosts; i++) {
      if (!_isScanning) break;

      String targetIP = '$subnet.$i';
      setState(() {
        _currentScanningIP = targetIP;
        _progress = i / totalHosts;
      });

      try {
        // Tente une connexion ping/socket rapide (timeout court de 150ms pour rester fluide)
        final socket = await Socket.connect(targetIP, 80, timeout: const Duration(milliseconds: 150));
        socket.destroy();
        await _registerDevice(targetIP);
      } catch (_) {
        // Si le port 80 ne répond pas, on teste le port 443 ou 22 pour confirmer la présence de la machine
        try {
          final socket = await Socket.connect(targetIP, 443, timeout: const Duration(milliseconds: 150));
          socket.destroy();
          await _registerDevice(targetIP);
        } catch (_) {
          // Machine non détectée ou hors ligne
        }
      }
    }

    setState(() {
      _isScanning = false;
      _currentScanningIP = 'Scan terminé';
    });
    _radarController.stop();
  }

  // Si une machine répond, on scanne ses ports ouverts principaux
  Future<void> _registerDevice(String ip) async {
    List<int> openPorts = [];
    
    for (int port in _commonPorts) {
      try {
        final socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 100));
        openPorts.add(port);
        socket.destroy();
      } catch (_) {}
    }

    setState(() {
      _discoveredDevices.add({
        'ip': ip,
        'ports': openPorts.isEmpty ? ['Aucun port standard détecté'] : openPorts.map((p) => '$p').toList(),
      });
    });
  }

  void _stopScan() {
    setState(() {
      _isScanning = false;
      _currentScanningIP = 'Scan interrompu';
    });
    _radarController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NET SCANNER v1.0', style: TextStyle(fontFamily: 'Courier', letterSpacing: 2, color: Color(0xFF00FFCC))),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          if (_isScanning)
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.redAccent),
              onPressed: _stopScan,
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuration du sous-réseau
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00FFCC).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.router, color: Color(0xFF00FFCC)),
                  const SizedBox(width: 15),
                  const Text('Plage : ', style: TextStyle(color: Colors.white60)),
                  Expanded(
                    child: TextField(
                      controller: _subnetController,
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 18),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '192.168.1',
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_isScanning,
                    ),
                  ),
                  const Text('.X (1-50)', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bouton de déclenchement
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _startNetworkScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FFCC),
                  foregroundColor: const Color(0xFF090D16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.white10,
                ),
                icon: _isScanning 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white30))
                  : const Icon(Icons.radar),
                label: Text(_isScanning ? 'RECHERCHE EN COURS...' : 'LANCER LE SCAN LAN', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),

            // Statut et barre de progression
            if (_isScanning || _currentScanningIP.isNotEmpty) ...[
              Text('Analyse : $_currentScanningIP', style: const TextStyle(fontFamily: 'Courier', color: Colors.white70)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white10,
                color: const Color(0xFF00FFCC),
                minHeight: 4,
              ),
              const SizedBox(height: 20),
            ],

            const Text('APPAREILS DÉTECTÉS', style: TextStyle(fontSize: 14, letterSpacing: 1.5, color: Colors.white38, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Liste des résultats
            Expanded(
              child: _discoveredDevices.isEmpty
                  ? Center(
                      child: Text(
                        _isScanning ? 'Écoute du réseau...' : 'Aucun appareil détecté.\nLance un scan.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white38, fontFamily: 'Courier'),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _discoveredDevices.length,
                      itemBuilder: (context, index) {
                        final device = _discoveredDevices[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00FF66).withOpacity(0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.devices, color: Color(0xFF00FF66), size: 30),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device['ip'],
                                      style: const TextStyle(fontSize: 18, fontFamily: 'Courier', fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Ports ouverts : ${device['ports'].join(', ')}',
                                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6), fontFamily: 'Courier'),
                                    ),
                                  ],
                                ),
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

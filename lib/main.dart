import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// Bog'langan fayllar
import 'mdp_transpiler.dart';
import 'mdp_run.dart';
import 'mdp_installer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ModderFileSystem.init();
  runApp(const ModderOS());
}

/// ===========================================================================
/// 1. MODDER FILE SYSTEM (Xotira va Papkalar)
/// ===========================================================================
class ModderFileSystem {
  static late Directory rootDir;
  static late Directory appsDir;

  static Future<void> init() async {
    final base = await getApplicationSupportDirectory();
    rootDir = Directory("${base.path}/ModderOS");
    appsDir = Directory("${rootDir.path}/Apps");

    if (!await rootDir.exists()) await rootDir.create(recursive: true);
    if (!await appsDir.exists()) await appsDir.create(recursive: true);

    _createDefaultPackages();
  }

  static void _createDefaultPackages() {
    final explorerPath = "${appsDir.path}/explorer.mdp";
    if (!File(explorerPath).existsSync()) {
      File(explorerPath).writeAsStringSync("""
title("File Explorer")
icon("📂")
text("Tizim xotirasi: C:\\\\ModderOS\\\\Apps", bold="true")
item(title="telegram.mdp", sub="Messenger", icon="💎", onClick="install")
item(title="payme.mdp", sub="Banking", icon="💳", onClick="install")
item(title="market.mdp", sub="App Store", icon="📦", onClick="install")
      """);
    }
  }
}

/// ===========================================================================
/// 2. MODDER KERNEL (Boshqaruv, Soat, Bildirishnomalar)
/// ===========================================================================
class ModderKernel extends ChangeNotifier {
  static final ModderKernel _instance = ModderKernel._internal();
  factory ModderKernel() => _instance;
  ModderKernel._internal();

  List<ModderProcess> processes = [];
  List<String> notifications = [];
  String currentTime = "";
  bool isControlPanelOpen = false;

  void boot() {
    _startClock();
    addNotification("ModderOS muvaffaqiyatli yuklandi");
  }

  void _startClock() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      currentTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      notifyListeners();
    });
  }

  void addNotification(String msg) {
    notifications.add(msg);
    if (notifications.length > 5) notifications.removeAt(0);
    notifyListeners();
    Future.delayed(const Duration(seconds: 5), () {
      notifications.remove(msg);
      notifyListeners();
    });
  }

  void launchApp(String id) {
    final path = "${ModderFileSystem.appsDir.path}/$id.mdp";
    if (!File(path).existsSync()) {
      addNotification("Xato: $id topilmadi");
      return;
    }
    if (processes.any((p) => p.id == id)) return;

    processes.add(ModderProcess(
      id: id,
      source: File(path).readAsStringSync(),
      position: Offset(100.0 + (processes.length * 30), 80.0),
    ));
    addNotification("$id ishga tushirildi");
    notifyListeners();
  }

  void killProcess(String id) {
    processes.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void toggleControlPanel() {
    isControlPanelOpen = !isControlPanelOpen;
    notifyListeners();
  }
}

class ModderProcess {
  final String id, source;
  Offset position;
  ModderProcess(
      {required this.id, required this.source, required this.position});
}

/// ===========================================================================
/// 3. MAIN UI SHELL (Sovereign Interface)
/// ===========================================================================
class ModderOS extends StatelessWidget {
  const ModderOS({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SovereignShell(),
    );
  }
}

class SovereignShell extends StatefulWidget {
  const SovereignShell({super.key});
  @override
  State<SovereignShell> createState() => _SovereignShellState();
}

class _SovereignShellState extends State<SovereignShell> {
  final kernel = ModderKernel();

  @override
  void initState() {
    super.initState();
    kernel.boot();
    kernel.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onSecondaryTapUp: (d) => _showContextMenu(context, d.globalPosition),
        child: Stack(
          children: [
            // 1. Wallpaper & Grid
            const Positioned.fill(child: ModderBackground()),

            // 2. Desktop Icons
            Positioned(
              left: 20,
              top: 60,
              child: DesktopIcon(id: "explorer", name: "Explorer", icon: "📂"),
            ),

            // 3. App Windows
            for (var p in kernel.processes)
              Positioned(
                left: p.position.dx,
                top: p.position.dy,
                child: GestureDetector(
                  onPanUpdate: (d) => setState(() => p.position += d.delta),
                  child: MDPRunner(
                    source: p.source,
                    appId: p.id,
                    onClose: () => kernel.killProcess(p.id),
                  ),
                ),
              ),

            // 4. System Bar (Top)
            _buildSystemBar(),

            // 5. Notifications
            _buildNotificationArea(),

            // 6. Control Panel Overlay
            if (kernel.isControlPanelOpen) const ControlPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 35,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          border: Border(bottom: BorderSide(color: Colors.white12)),
        ),
        child: Row(
          children: [
            const Icon(Icons.shield, size: 16, color: Colors.cyanAccent),
            const SizedBox(width: 10),
            const Text("ModderOS Sovereign",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(kernel.currentTime, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 15),
            GestureDetector(
              onTap: kernel.toggleControlPanel,
              child: const Icon(Icons.tune, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationArea() {
    return Positioned(
      top: 45,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: kernel.notifications
            .map((n) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(n, style: const TextStyle(fontSize: 12)),
                ))
            .toList(),
      ),
    );
  }

  // CONTEXT MENU FIX
  void _showContextMenu(BuildContext context, Offset pos) {
    showMenu<Object>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx, pos.dy),
      elevation: 10,
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      items: <PopupMenuEntry<Object>>[
        PopupMenuItem(
          onTap: () => kernel.addNotification("Yangi papka yaratildi"),
          child: const _MenuRow(Icons.create_new_folder, "Yangi papka"),
        ),
        PopupMenuItem(
          onTap: () => setState(() {}),
          child: const _MenuRow(Icons.refresh, "Yangilash"),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () => kernel.toggleControlPanel(),
          child: const _MenuRow(Icons.settings, "Tizim sozlamalari"),
        ),
      ],
    );
  }
}

/// ===========================================================================
/// 4. ADDITIONAL COMPONENTS
/// ===========================================================================

class DesktopIcon extends StatefulWidget {
  final String id, name, icon;
  const DesktopIcon(
      {super.key, required this.id, required this.name, required this.icon});
  @override
  State<DesktopIcon> createState() => _DesktopIconState();
}

class _DesktopIconState extends State<DesktopIcon> {
  bool isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onDoubleTap: () => ModderKernel().launchApp(widget.id),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isHovered ? Colors.white10 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 5),
              Text(widget.name, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      right: 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 300,
            height: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.black54,
                border: Border.all(color: Colors.white10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("CONTROL PANEL",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const Divider(height: 30),
                _controlRow(Icons.wifi, "Wi-Fi Network", "Connected"),
                _controlRow(Icons.bluetooth, "Bluetooth", "Active"),
                _controlRow(Icons.dark_mode, "Dark Mode", "Enabled"),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => exit(0),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent),
                    child: const Text("SHUTDOWN"),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controlRow(IconData icon, String title, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.cyanAccent),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
              Text(status,
                  style: const TextStyle(fontSize: 10, color: Colors.white54)),
            ],
          )
        ],
      ),
    );
  }
}

class ModderBackground extends StatelessWidget {
  const ModderBackground({super.key});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
              colors: [Color(0xFF0D0D0D), Colors.black], radius: 1.5),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MenuRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.cyanAccent),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

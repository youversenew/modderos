import 'dart:ui';
import 'package:flutter/material.dart';
import 'mdp_transpiler.dart'; // Transpiler bilan bog'lanish

class MDPRunner extends StatefulWidget {
  final String source; // .mdp fayl kodi
  final String appId; // Ilova ID si
  final VoidCallback onClose; // Yopish funksiyasi

  const MDPRunner({
    super.key,
    required this.source,
    required this.appId,
    required this.onClose,
  });

  @override
  State<MDPRunner> createState() => _MDPRunnerState();
}

class _MDPRunnerState extends State<MDPRunner> {
  late String appTitle;
  late String appIcon;
  bool isMinimized = false;
  bool isMaximized = false;

  @override
  void initState() {
    super.initState();
    // Ilova metadata (Title va Icon) ni manbadan ajratib olish
    appTitle =
        _extractMetadata(widget.source, 'title') ?? widget.appId.toUpperCase();
    appIcon = _extractMetadata(widget.source, 'icon') ?? "🚀";
  }

  // .mdp ichidan title("...") va icon("...") ni qidiradi
  String? _extractMetadata(String source, String key) {
    final regExp = RegExp('$key\\("([^"]+)"\\)');
    final match = regExp.firstMatch(source);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    if (isMinimized) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMaximized ? 0 : 12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            width: isMaximized ? MediaQuery.of(context).size.width : 850,
            height: isMaximized ? MediaQuery.of(context).size.height : 550,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(isMaximized ? 0 : 12),
              border:
                  Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              children: [
                // 1. SYSTEM WINDOW FRAME (TITLEBAR)
                _buildTitleBar(),

                // 2. APP CONTENT (MDP ENGINE)
                Expanded(
                  child: ClipRRect(
                    child: MDPTranspiler.transpile(widget.source, context),
                  ),
                ),

                // 3. WINDOW STATUS BAR (Hidden by default, can be enabled)
                _buildStatusBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Windows EXE uslubidagi Titlebar
  Widget _buildTitleBar() {
    return GestureDetector(
      onDoubleTap: () => setState(() => isMaximized = !isMaximized),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border:
              Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: Row(
          children: [
            // App Icon & Name
            Text(appIcon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Text(
              appTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),

            // Window Controls (Minimize, Maximize, Close)
            _winControl(Icons.remove, Colors.white38, () {
              setState(() => isMinimized = true);
            }),
            const SizedBox(width: 12),
            _winControl(
              isMaximized ? Icons.unfold_less : Icons.crop_square,
              Colors.white38,
              () => setState(() => isMaximized = !isMaximized),
            ),
            const SizedBox(width: 12),
            _winControl(
                Icons.close, Colors.redAccent.withOpacity(0.8), widget.onClose),
          ],
        ),
      ),
    );
  }

  Widget _winControl(IconData icon, Color color, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.03))),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 10, color: Colors.greenAccent),
          const SizedBox(width: 5),
          Text(
            "ModderRuntime: PID ${widget.appId.hashCode.toString().substring(0, 4)} - Active",
            style: const TextStyle(fontSize: 9, color: Colors.white24),
          ),
          const Spacer(),
          const Text("v1.0.0",
              style: TextStyle(fontSize: 9, color: Colors.white24)),
        ],
      ),
    );
  }
}

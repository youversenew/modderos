import 'dart:ui';
import 'package:flutter/material.dart';

// Paket haqida ma'lumot modeli
class MDPPackageMetadata {
  final String name;
  final String version;
  final String developer;
  final String description;
  final String icon;
  final List<String> permissions;
  final double sizeMb;

  MDPPackageMetadata({
    required this.name,
    this.version = "1.0.0",
    this.developer = "Unknown Developer",
    this.description = "Tavsif mavjud emas.",
    this.icon = "📦",
    this.permissions = const ["Internetga kirish", "Fayllarni o'qish"],
    this.sizeMb = 15.5,
  });
}

class MDPInstaller extends StatefulWidget {
  final MDPPackageMetadata metadata;
  final VoidCallback onInstallComplete;
  final VoidCallback onCancel;

  const MDPInstaller({
    super.key,
    required this.metadata,
    required this.onInstallComplete,
    required this.onCancel,
  });

  @override
  State<MDPInstaller> createState() => _MDPInstallerState();
}

class _MDPInstallerState extends State<MDPInstaller> {
  int _currentStep = 0; // 0: Welcome, 1: Permissions, 2: Installing, 3: Success
  double _installProgress = 0.0;
  String _installPath = "C:\\ModderOS\\Programs\\";
  bool _isAgreed = false;

  void _startInstallation() {
    setState(() => _currentStep = 2);
    // O'rnatish jarayonini simulyatsiya qilish (Extraction)
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      setState(() {
        _installProgress += 0.02;
      });
      if (_installProgress >= 1.0) {
        setState(() => _currentStep = 3);
        return false;
      }
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            width: 550,
            height: 400,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                // Installer Header
                _buildHeader(),

                // Content Switcher
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: _buildStepContent(),
                  ),
                ),

                // Footer Buttons
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      color: Colors.white.withOpacity(0.05),
      child: Row(
        children: [
          const Icon(Icons.install_desktop, size: 16, color: Colors.cyanAccent),
          const SizedBox(width: 10),
          Text(
            "${widget.metadata.name} o'rnatuvchisi",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: widget.onCancel,
          )
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: // Welcome & Info
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.metadata.icon,
                    style: const TextStyle(fontSize: 50)),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.metadata.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(
                        "Versiya: ${widget.metadata.version} | ${widget.metadata.sizeMb} MB",
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            const Text("Tavsif:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(widget.metadata.description,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const Spacer(),
            Text(
                "O'rnatish manzili: $_installPath${widget.metadata.name.toLowerCase()}",
                style: const TextStyle(fontSize: 10, color: Colors.cyanAccent)),
          ],
        );

      case 1: // Permissions
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tizim ruxsatnomalari so'rovi:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            const Text("Ushbu ilova ishlashi uchun quyidagi ruxsatlar kerak:",
                style: TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 10),
            ...widget.metadata.permissions.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.security,
                          size: 14, color: Colors.amberAccent),
                      const SizedBox(width: 10),
                      Text(p, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )),
            const Spacer(),
            Row(
              children: [
                Checkbox(
                    value: _isAgreed,
                    activeColor: Colors.cyanAccent,
                    onChanged: (val) => setState(() => _isAgreed = val!)),
                const Expanded(
                    child: Text("Foydalanish shartlariga roziman",
                        style: TextStyle(fontSize: 11))),
              ],
            )
          ],
        );

      case 2: // Installing Progress
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("O'rnatilmoqda...",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _installProgress,
                minHeight: 10,
                backgroundColor: Colors.white10,
                color: Colors.cyanAccent,
              ),
            ),
            const SizedBox(height: 10),
            Text("${(_installProgress * 100).toInt()}%",
                style: const TextStyle(color: Colors.cyanAccent)),
            const SizedBox(height: 20),
            const Text(
                "Fayllar 'C:\\ModderOS\\Apps' papkasiga nusxalanmoqda...",
                style: TextStyle(fontSize: 10, color: Colors.white38)),
          ],
        );

      case 3: // Success
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 80, color: Colors.greenAccent),
            const SizedBox(height: 20),
            Text("${widget.metadata.name} muvaffaqiyatli o'rnatildi!",
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
                "Endi ilovani ish stolida ko'rishingiz va ishga tushirishingiz mumkin.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white70)),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentStep < 2)
            TextButton(
                onPressed: widget.onCancel,
                child: const Text("Bekor qilish",
                    style: TextStyle(color: Colors.white38))),
          const SizedBox(width: 15),
          if (_currentStep == 0)
            ElevatedButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: const Text("Keyingisi"),
            ),
          if (_currentStep == 1)
            ElevatedButton(
              onPressed: _isAgreed ? _startInstallation : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black),
              child: const Text("O'rnatish"),
            ),
          if (_currentStep == 3)
            ElevatedButton(
              onPressed: widget.onInstallComplete,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black),
              child: const Text("Tayyor"),
            ),
        ],
      ),
    );
  }
}

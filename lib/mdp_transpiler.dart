import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart'
    as http; // http paketini pubspec.yaml ga qo'shish kerak

class MDPTranspiler {
  static Widget transpile(String source, BuildContext context) {
    return _MDPRuntimeWidget(source: source);
  }
}

class _MDPRuntimeWidget extends StatefulWidget {
  final String source;
  const _MDPRuntimeWidget({required this.source});

  @override
  State<_MDPRuntimeWidget> createState() => _MDPRuntimeWidgetState();
}

class _MDPRuntimeWidgetState extends State<_MDPRuntimeWidget> {
  Map<String, dynamic> appData =
      {}; // Networkdan kelgan yoki input ma'lumotlari
  bool isLoading = false;
  bool isSidebarOpen = true;

  @override
  void initState() {
    super.initState();
    _executeInitialLogic();
  }

  // .mdp ichida fetch() bo'lsa ma'lumot yuklaydi
  void _executeInitialLogic() async {
    if (widget.source.contains('fetch(')) {
      final regExp = RegExp(r'fetch\(url="([^"]+)"\)');
      final match = regExp.firstMatch(widget.source);
      if (match != null) {
        setState(() => isLoading = true);
        try {
          final response = await http.get(Uri.parse(match.group(1)!));
          if (response.statusCode == 200) {
            setState(() => appData = json.decode(response.body));
          }
        } catch (e) {
          debugPrint("Network Error: $e");
        } finally {
          setState(() => isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent));

    List<Widget> bodyElements = [];
    List<Widget> sidebarElements = [];
    bool parsingSidebar = false;

    final lines = widget.source.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      // Sidebar bloklari
      if (line == 'sidebar_start()') {
        parsingSidebar = true;
        continue;
      }
      if (line == 'sidebar_end()') {
        parsingSidebar = false;
        continue;
      }

      Widget element = _parseLineToWidget(line);

      if (parsingSidebar) {
        sidebarElements.add(element);
      } else {
        bodyElements.add(element);
      }
    }

    return Row(
      children: [
        // UNIVERSAL SIDEBAR
        if (sidebarElements.isNotEmpty && isSidebarOpen)
          _buildModderSidebar(sidebarElements),

        // MAIN CONTENT
        Expanded(
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: bodyElements,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _parseLineToWidget(String line) {
    final params = _parseParams(line);

    // 1. MODDER BUTTON
    if (line.startsWith('button(')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _getColor(params['color'] ?? 'blue'),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => _handleAction(params['onClick']),
          child: Text(params['text'] ?? "Button",
              style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    // 2. MODDER INPUT
    if (line.startsWith('input(')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextField(
          decoration: InputDecoration(
            hintText: params['placeholder'] ?? "Kiritish...",
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
          onChanged: (val) => appData[params['var'] ?? 'temp'] = val,
        ),
      );
    }

    // 3. MODDER SELECT (Dropdown)
    if (line.startsWith('select(')) {
      List<String> options =
          (params['options'] ?? "Option1,Option2").split(',');
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: DropdownButtonFormField(
          decoration: _inputDecoration("Tanlang"),
          items: options
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) {},
        ),
      );
    }

    // 4. MODDER ITEM (Telegram style)
    if (line.startsWith('item(')) {
      return ListTile(
        leading: CircleAvatar(
            backgroundColor: Colors.blueGrey,
            child: Text(params['icon'] ?? "U")),
        title: Text(params['title'] ?? "User"),
        subtitle: Text(params['sub'] ?? "Message content..."),
        trailing: Text(params['time'] ?? ""),
        onTap: () => _handleAction(params['onClick']),
      );
    }

    // 5. MODDER CARD (Payme style)
    if (line.startsWith('card(')) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [_getColor(params['color'] ?? 'indigo'), Colors.black]),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(params['label'] ?? "CARD",
                style: const TextStyle(fontSize: 10, color: Colors.white60)),
            const SizedBox(height: 10),
            Text(params['value'] ?? "0.0 UZS",
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(params['number'] ?? "**** ****",
                style: const TextStyle(letterSpacing: 2)),
          ],
        ),
      );
    }

    // 6. MODDER TEXT
    if (line.startsWith('text(')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          params['value'] ?? line.substring(5, line.length - 1),
          style: TextStyle(
            fontSize: double.tryParse(params['size'] ?? '16') ?? 16,
            fontWeight:
                params['bold'] == 'true' ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // Sidebar Dizayni
  Widget _buildModderSidebar(List<Widget> elements) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.black26,
        border:
            Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("MENU",
                  style: TextStyle(
                      letterSpacing: 2, color: Colors.white38, fontSize: 10)),
            ),
            ...elements,
          ],
        ),
      ),
    );
  }

  void _handleAction(String? action) {
    if (action == null) return;
    if (action == 'open_modal') {
      _showModderModal();
    } else if (action == 'toggle_sidebar') {
      setState(() => isSidebarOpen = !isSidebarOpen);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Action: $action")));
    }
  }

  void _showModderModal() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.grey[900],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("ModderOS Modal"),
          content:
              const Text("Bu universal modal tizimi. .mdp orqali chaqirildi."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"))
          ],
        ),
      ),
    );
  }

  Map<String, String> _parseParams(String line) {
    Map<String, String> map = {};
    final regExp = RegExp(r'(\w+)="([^"]+)"');
    final matches = regExp.allMatches(line);
    for (var m in matches) {
      map[m.group(1)!] = m.group(2)!;
    }
    return map;
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }

  Color _getColor(String name) {
    switch (name) {
      case 'blue':
        return Colors.blueAccent;
      case 'red':
        return Colors.redAccent;
      case 'green':
        return Colors.greenAccent;
      case 'indigo':
        return Colors.indigoAccent;
      default:
        return Colors.blueGrey;
    }
  }
}

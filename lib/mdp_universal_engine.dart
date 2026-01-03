import 'package:flutter/material.dart';
import 'dart:ui';

/// MODDER UNIVERSAL ENGINE v1.0
/// Bu engine .mdp fayllarini real-vaqtda murakkab Flutter widgetlariga aylantiradi.
class MDPTranspiler {
  static Widget transpile(String source) {
    try {
      List<Widget> rootElements = [];
      List<String> lines = source.split('\n');

      // Global state (Ilova ichidagi ma'lumotlar uchun)
      Map<String, dynamic> appState = {};

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#')) continue;

        // 1. Layout Tizimi (Column, Row, Stack)
        if (line.startsWith('row_start()')) {
          /* Keyingi elementlar rowga tushadi simulyatsiyasi */
        }

        // 2. Telegram: Kontaktlar yoki Xabarlar uchun ListTile
        if (line.startsWith('item(')) {
          var params = _parseParams(line);
          rootElements.add(ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Text(params['icon'] ?? "U"),
            ),
            title: Text(params['title'] ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(params['sub'] ?? ""),
            trailing: Text(params['time'] ?? ""),
          ));
        }

        // 3. Payme/Banking: Katta karta (Card)
        if (line.startsWith('card(')) {
          var params = _parseParams(line);
          rootElements.add(Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF00B4DB), Color(0xFF0083B0)]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(params['label'] ?? "BALANCE",
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 10),
                Text(params['value'] ?? "0.00 UZS",
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text(params['number'] ?? "**** **** **** ****",
                    style: const TextStyle(letterSpacing: 2)),
              ],
            ),
          ));
        }

        // 4. Play Market/Google: Grid ko'rinishidagi Ikonkalar
        if (line.startsWith('app_grid(')) {
          var apps = (line.substring(9, line.length - 1)).split(';');
          rootElements.add(GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            children: apps.map((app) {
              var p = app.split(':');
              return Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.android, color: Colors.greenAccent),
                  ),
                  const SizedBox(height: 5),
                  Text(p[0], style: const TextStyle(fontSize: 10)),
                ],
              );
            }).toList(),
          ));
        }

        // 5. Standart Elementlar (Text, Button, Input, Image)
        if (line.startsWith('text(')) {
          rootElements.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(line.substring(6, line.length - 2),
                style: const TextStyle(fontSize: 16)),
          ));
        }

        if (line.startsWith('img(')) {
          rootElements.add(ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(line.substring(5, line.length - 2),
                height: 150, width: double.infinity, fit: BoxFit.cover),
          ));
        }

        if (line.startsWith('button(')) {
          rootElements.add(SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: Text(line.substring(8, line.length - 2)),
            ),
          ));
        }
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rootElements),
      );
    } catch (e) {
      return Center(
          child: Text("Transpilation Error: $e",
              style: const TextStyle(color: Colors.red)));
    }
  }

  // Parametrlarni ajratib olish: key="value"
  static Map<String, String> _parseParams(String line) {
    Map<String, String> map = {};
    final regExp = RegExp(r'(\w+)="([^"]+)"');
    final matches = regExp.allMatches(line);
    for (var m in matches) {
      map[m.group(1)!] = m.group(2)!;
    }
    return map;
  }
}

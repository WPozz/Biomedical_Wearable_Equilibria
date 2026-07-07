import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/providers/settings_provider.dart';
import 'dart:math';
import '../data/video_archive.dart';
import 'video_player.dart';

String _translateCategory(String cat, bool isItalian) {
  if (!isItalian || cat.isEmpty) return cat;
  switch (cat) {
    case "NECK AND CERVICAL": return "COLLO E CERVICALE";
    case "SHOULDERS AND UPPER BACK": return "SPALLE E SCHIENA ALTA";
    case "BACK AND LUMBAR": return "SCHIENA E LOMBARE";
    case "ARMS AND ELBOWS": return "BRACCIA E GOMITI";
    case "WRISTS AND HANDS": return "POLSI E MANI";
    case "LEGS AND ANKLES": return "GAMBE E CAVIGLIE";
    default: return cat;
  }
}


//  BODY ZONE LAYOUT
class BodyZoneLayout {
  final double cx;
  final double s;

  final double headR, headCY;
  final double neckW, neckH, neckX, neckY;
  final double torsoW, torsoX, torsoTopY, torsoTopH, torsoBotY, torsoBotH;
  final double armGap, armW, armH, armY, armLX, armRX;
  final double handW, handH, handY, handLX, handRX;
  final double legGap, legW, legH, legY, legLX, legRX;

  BodyZoneLayout({required this.cx, required this.s})
      : headR = 22.0 * s,
        headCY = 24.0 * s,
        neckW = 16.0 * s,
        neckH = 14.0 * s,
        neckX = cx - (16.0 * s) / 2,
        neckY = (24.0 * s) + (22.0 * s),
        torsoW = 92.0 * s,
        torsoX = cx - (92.0 * s) / 2,
        torsoTopY = (24.0 * s) + (22.0 * s) + (14.0 * s) + 4 * s,
        torsoTopH = 72.0 * s,
        torsoBotY = (24.0 * s) + (22.0 * s) + (14.0 * s) + 4 * s + 72.0 * s + 4.0 * s,
        torsoBotH = 72.0 * s,
        armGap = 4.0 * s,
        armW = 24.0 * s,
        armH = 110.0 * s,
        armY = (24.0 * s) + (22.0 * s) + (14.0 * s) + 4 * s,
        armLX = (cx - (92.0 * s) / 2) - (24.0 * s) - 4.0 * s,
        armRX = (cx - (92.0 * s) / 2) + (92.0 * s) + 4.0 * s,
        handW = 24.0 * s,
        handH = 36.0 * s,
        handY = (24.0 * s) + (22.0 * s) + (14.0 * s) + 4 * s + 110.0 * s + 4.0 * s,
        handLX = (cx - (92.0 * s) / 2) - (24.0 * s) - 4.0 * s,
        handRX = (cx - (92.0 * s) / 2) + (92.0 * s) + 4.0 * s,
        legGap = 4.0 * s,
        legW = 36.0 * s,
        legH = 155.0 * s,
        legY = (24.0 * s) + (22.0 * s) + (14.0 * s) + 4 * s + 72.0 * s + 4.0 * s + 72.0 * s + 4.0 * s,
        legLX = cx - (36.0 * s) - (4.0 * s) / 2,
        legRX = cx + (4.0 * s) / 2;

  Map<String, List<Rect>> get zoneRects => {
        "NECK AND CERVICAL": [
          Rect.fromLTWH(cx - headR, 0, headR * 2, headCY + headR + neckH + 4 * s),
        ],
        "SHOULDERS AND UPPER BACK": [
          Rect.fromLTWH(torsoX, torsoTopY, torsoW, torsoTopH),
        ],
        "BACK AND LUMBAR": [
          Rect.fromLTWH(torsoX, torsoBotY, torsoW, torsoBotH),
        ],
        "ARMS AND ELBOWS": [
          Rect.fromLTWH(armLX, armY, armW, armH),
          Rect.fromLTWH(armRX, armY, armW, armH),
        ],
        "WRISTS AND HANDS": [
          Rect.fromLTWH(handLX, handY, handW, handH),
          Rect.fromLTWH(handRX, handY, handW, handH),
        ],
        "LEGS AND ANKLES": [
          Rect.fromLTWH(legLX, legY, legW, legH),
          Rect.fromLTWH(legRX, legY, legW, legH),
        ],
      };
}

class PainSelectionScreen extends StatefulWidget {
  const PainSelectionScreen({super.key});

  @override
  State<PainSelectionScreen> createState() => _PainSelectionScreenState();
}

class _PainSelectionScreenState extends State<PainSelectionScreen> {
  String _zonaSelezionata = "";

  static const double canvasW = 300.0;
  static const double canvasH = 580.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isItalian = context.watch<SettingsProvider>().isItalian;

    final layout = BodyZoneLayout(cx: canvasW / 2, s: 1.5);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 120,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isItalian ? "Scegli l'area \ndi focus" : "Choose your \nfocus area",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 32,
            height: 1.1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: canvasW,
                height: canvasH,
                child: _buildFigura(layout),
              ),
            ),
            const SizedBox(height: 24),
            if (_zonaSelezionata.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    Text(
                      _translateCategory(_zonaSelezionata, isItalian),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        List<ExerciseVideo> filteredVideos = videoArchive
                            .where((v) => v.category == _zonaSelezionata)
                            .toList();
                        if (filteredVideos.isNotEmpty) {
                          final randomVideo = filteredVideos[Random().nextInt(filteredVideos.length)];
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => VideoPlayerScreen(video: randomVideo)),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 65),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 3,
                      ),
                      child: Text(
                        isItalian ? "Conferma" : "Confirm",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildFigura(BodyZoneLayout layout) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: SilhouettePainter(
              color: Theme.of(context).colorScheme.onSurface,
              selectedZone: _zonaSelezionata,
              layout: layout,
            ),
          ),
        ),
        for (final entry in layout.zoneRects.entries)
          for (final rect in entry.value) _hit(rect: rect, label: entry.key),
      ],
    );
  }

  Widget _hit({required Rect rect, required String label}) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      child: GestureDetector(
        onTap: () => setState(() {
          _zonaSelezionata = _zonaSelezionata == label ? "" : label;
        }),
        child: Container(width: rect.width, height: rect.height, color: Colors.transparent),
      ),
    );
  }
}


//  SILHOUETTE PAINTER

class SilhouettePainter extends CustomPainter {
  final Color color;
  final String selectedZone;
  final BodyZoneLayout layout;

  static const Color _hl = Color(0xFFE24B4A);

  const SilhouettePainter({
    required this.color,
    required this.selectedZone,
    required this.layout,
  });

  Paint _p(String zone) => Paint()
    ..color = selectedZone == zone ? _hl : color
    ..style = PaintingStyle.fill;

  RRect _rr(double x, double y, double w, double h, {double r = 8}) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r * layout.s));

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(Offset(layout.cx, layout.headCY), layout.headR, _p("NECK AND CERVICAL"));
    canvas.drawRRect(_rr(layout.neckX, layout.neckY, layout.neckW, layout.neckH, r: 4), _p("NECK AND CERVICAL"));
    canvas.drawRRect(_rr(layout.torsoX, layout.torsoTopY, layout.torsoW, layout.torsoTopH), _p("SHOULDERS AND UPPER BACK"));
    canvas.drawRRect(_rr(layout.torsoX, layout.torsoBotY, layout.torsoW, layout.torsoBotH), _p("BACK AND LUMBAR"));
    canvas.drawRRect(_rr(layout.armLX, layout.armY, layout.armW, layout.armH, r: 10), _p("ARMS AND ELBOWS"));
    canvas.drawRRect(_rr(layout.armRX, layout.armY, layout.armW, layout.armH, r: 10), _p("ARMS AND ELBOWS"));
    canvas.drawRRect(_rr(layout.handLX, layout.handY, layout.handW, layout.handH, r: 10), _p("WRISTS AND HANDS"));
    canvas.drawRRect(_rr(layout.handRX, layout.handY, layout.handW, layout.handH, r: 10), _p("WRISTS AND HANDS"));
    canvas.drawRRect(_rr(layout.legLX, layout.legY, layout.legW, layout.legH, r: 12), _p("LEGS AND ANKLES"));
    canvas.drawRRect(_rr(layout.legRX, layout.legY, layout.legW, layout.legH, r: 12), _p("LEGS AND ANKLES"));
  }

  @override
  bool shouldRepaint(covariant SilhouettePainter old) =>
      old.selectedZone != selectedZone ||
      old.color != color ||
      old.layout.s != layout.s ||
      old.layout.cx != layout.cx;
}
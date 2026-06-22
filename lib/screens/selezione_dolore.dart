import 'package:flutter/material.dart';
import 'dart:math';
import '../data/video_archive.dart';
import 'video_player.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';




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

class SelezioneDoloreScreen extends StatefulWidget {
  const SelezioneDoloreScreen({super.key});

  @override
  State<SelezioneDoloreScreen> createState() => _SelezioneDoloreScreenState();
}

class _SelezioneDoloreScreenState extends State<SelezioneDoloreScreen> {
  String _zonaSelezionata = "";

  static const double canvasW = 300.0;
  static const double canvasH = 580.0;
  static const double cx = canvasW / 2; // 150

  static const double _s = 1.5;

  // Testa
  static const double headR  = 22.0 * _s;
  static const double headCY = 24.0 * _s;

  // Collo
  static const double neckW = 16.0 * _s;
  static const double neckH = 14.0 * _s;
  static const double neckX = cx - neckW / 2;
  static const double neckY = headCY + headR;

  // Torso
  static const double torsoW    = 92.0 * _s;
  static const double torsoX    = cx - torsoW / 2;
  static const double torsoTopY = neckY + neckH + 4 * _s;
  static const double torsoTopH = 72.0 * _s;
  static const double torsoGap  = 4.0 * _s;
  static const double torsoBotY = torsoTopY + torsoTopH + torsoGap;
  static const double torsoBotH = 72.0 * _s;

  // Braccia
  static const double armGap = 4.0 * _s;
  static const double armW   = 24.0 * _s;
  static const double armH   = 110.0 * _s;
  static const double armY   = torsoTopY;
  static const double armLX  = torsoX - armW - armGap;
  static const double armRX  = torsoX + torsoW + armGap;

  // Polsi/mani
  static const double handW  = 24.0 * _s;
  static const double handH  = 36.0 * _s;
  static const double handY  = armY + armH + armGap;
  static const double handLX = armLX;
  static const double handRX = armRX;

  // Gambe
  static const double legGap = 4.0 * _s;
  static const double legW   = 36.0 * _s;
  static const double legH   = 155.0 * _s;
  static const double legY   = torsoBotY + torsoBotH + legGap;
  static const double legLX  = cx - legW - legGap / 2;
  static const double legRX  = cx + legGap / 2;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isItalian = context.watch<SettingsProvider>().isItalian;

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
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: SilhouettePainter(
                          color: colorScheme.onSurface,
                          selectedZone: _zonaSelezionata,
                        ),
                      ),
                    ),
                    _hit(left: cx - headR,  top: 0,         w: headR * 2, h: headCY + headR + neckH + 4 * _s, label: "NECK AND CERVICAL"),
                    _hit(left: torsoX,      top: torsoTopY, w: torsoW,    h: torsoTopH,                        label: "SHOULDERS AND UPPER BACK"),
                    _hit(left: torsoX,      top: torsoBotY, w: torsoW,    h: torsoBotH,                        label: "BACK AND LUMBAR"),
                    _hit(left: armLX,       top: armY,      w: armW,      h: armH,                             label: "ARMS AND ELBOWS"),
                    _hit(left: armRX,       top: armY,      w: armW,      h: armH,                             label: "ARMS AND ELBOWS"),
                    _hit(left: handLX,      top: handY,     w: handW,     h: handH,                            label: "WRISTS AND HANDS"),
                    _hit(left: handRX,      top: handY,     w: handW,     h: handH,                            label: "WRISTS AND HANDS"),
                    _hit(left: legLX,       top: legY,      w: legW,      h: legH,                             label: "LEGS AND ANKLES"),
                    _hit(left: legRX,       top: legY,      w: legW,      h: legH,                             label: "LEGS AND ANKLES"),
                  ],
                ),
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

  Widget _hit({required double left, required double top, required double w, required double h, required String label}) {
    return Positioned(
      left: left, top: top,
      child: GestureDetector(
        onTap: () => setState(() {
          _zonaSelezionata = _zonaSelezionata == label ? "" : label;
        }),
        child: Container(width: w, height: h, color: Colors.transparent),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  SILHOUETTE PAINTER
// ---------------------------------------------------------------------------
class SilhouettePainter extends CustomPainter {
  final Color color;
  final String selectedZone;

  static const Color _hl = Color(0xFFE24B4A);
  static const double cx    = 150;
  static const double _s    = 1.5;
  static const double headR  = 22.0 * _s;
  static const double headCY = 24.0 * _s;
  static const double neckW  = 16.0 * _s;
  static const double neckH  = 14.0 * _s;
  static const double neckX  = cx - neckW / 2;
  static const double neckY  = headCY + headR;
  static const double torsoW    = 92.0 * _s;
  static const double torsoX    = cx - torsoW / 2;
  static const double torsoTopY = neckY + neckH + 4 * _s;
  static const double torsoTopH = 72.0 * _s;
  static const double torsoGap  = 4.0 * _s;
  static const double torsoBotY = torsoTopY + torsoTopH + torsoGap;
  static const double torsoBotH = 72.0 * _s;
  static const double armGap = 4.0 * _s;
  static const double armW   = 24.0 * _s;
  static const double armH   = 110.0 * _s;
  static const double armY   = torsoTopY;
  static const double armLX  = torsoX - armW - armGap;
  static const double armRX  = torsoX + torsoW + armGap;
  static const double handW  = 24.0 * _s;
  static const double handH  = 36.0 * _s;
  static const double handY  = armY + armH + armGap;
  static const double handLX = armLX;
  static const double handRX = armRX;
  static const double legGap = 4.0 * _s;
  static const double legW   = 36.0 * _s;
  static const double legH   = 155.0 * _s;
  static const double legY   = torsoBotY + torsoBotH + legGap;
  static const double legLX  = cx - legW - legGap / 2;
  static const double legRX  = cx + legGap / 2;

  const SilhouettePainter({required this.color, required this.selectedZone});

  Paint _p(String zone) => Paint()
    ..color = selectedZone == zone ? _hl : color
    ..style = PaintingStyle.fill;

  RRect _rr(double x, double y, double w, double h, {double r = 8}) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r * _s));

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(Offset(cx, headCY), headR,                _p("NECK AND CERVICAL"));
    canvas.drawRRect(_rr(neckX, neckY, neckW, neckH, r: 4),     _p("NECK AND CERVICAL"));
    canvas.drawRRect(_rr(torsoX, torsoTopY, torsoW, torsoTopH),  _p("SHOULDERS AND UPPER BACK"));
    canvas.drawRRect(_rr(torsoX, torsoBotY, torsoW, torsoBotH),  _p("BACK AND LUMBAR"));
    canvas.drawRRect(_rr(armLX,  armY,  armW,  armH,  r: 10),   _p("ARMS AND ELBOWS"));
    canvas.drawRRect(_rr(armRX,  armY,  armW,  armH,  r: 10),   _p("ARMS AND ELBOWS"));
    canvas.drawRRect(_rr(handLX, handY, handW, handH, r: 10),   _p("WRISTS AND HANDS"));
    canvas.drawRRect(_rr(handRX, handY, handW, handH, r: 10),   _p("WRISTS AND HANDS"));
    canvas.drawRRect(_rr(legLX,  legY,  legW,  legH,  r: 12),   _p("LEGS AND ANKLES"));
    canvas.drawRRect(_rr(legRX,  legY,  legW,  legH,  r: 12),   _p("LEGS AND ANKLES"));
  }

  @override
  bool shouldRepaint(covariant SilhouettePainter old) =>
      old.selectedZone != selectedZone || old.color != color;
}
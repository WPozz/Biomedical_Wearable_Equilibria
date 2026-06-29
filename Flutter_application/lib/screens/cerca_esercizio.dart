import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/video_archive.dart';
import 'video_player.dart';
import 'package:flutter_application/providers/settings_provider.dart';

String _translateCategory(String cat, bool isItalian) {
  if (!isItalian) return cat;
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

class CercaEsercizioScreen extends StatefulWidget {
  const CercaEsercizioScreen({super.key});

  @override
  State<CercaEsercizioScreen> createState() => _CercaEsercizioScreenState();
}

class _CercaEsercizioScreenState extends State<CercaEsercizioScreen> {
  Set<String> _zoneSelected = {};
  double _minutiSelected = 5;
  bool _qualsiasiTempo = false;
  bool _tutteLeZone = false;

  static const double _baseW = 200.0;
  static const double _baseH = 580.0 / 1.5;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isItalian = context.watch<SettingsProvider>().isItalian;

    return Scaffold(
      appBar: AppBar(
        title: Text(isItalian ? "Trova l'esercizio giusto" : "Find the right exercise"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          CheckboxListTile(
            title: Text(isItalian ? "Qualsiasi durata" : "Any duration"),
            value: _qualsiasiTempo,
            onChanged: (val) => setState(() => _qualsiasiTempo = val!),
          ),
          Opacity(
            opacity: _qualsiasiTempo ? 0.3 : 1.0,
            child: IgnorePointer(
              ignoring: _qualsiasiTempo,
              child: Column(
                children: [
                  Text(
                    isItalian ? "${_minutiSelected.toInt()} minuti" : "${_minutiSelected.toInt()} minutes",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.primary),
                  ),
                  Slider(
                    value: _minutiSelected,
                    min: 1, max: 15, divisions: 14,
                    label: "${_minutiSelected.toInt()} min",
                    onChanged: (val) => setState(() => _minutiSelected = val),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          CheckboxListTile(
            title: Text(isItalian ? "Tutte le zone del corpo" : "All body areas"),
            value: _tutteLeZone,
            onChanged: (val) => setState(() {
              _tutteLeZone = val!;
              if (_tutteLeZone) _zoneSelected = {};
            }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              _tutteLeZone
                  ? (isItalian ? "ZONA: TUTTE" : "AREA: ALL")
                  : _zoneSelected.isEmpty
                      ? (isItalian ? "Tocca una o più zone sulla figura" : "Tap one or more areas on the figure")
                      : _zoneSelected.map((z) => _translateCategory(z, isItalian)).join(" + "),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.secondary),
            ),
          ),

        
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calcola la scala massima che entra nello spazio disponibile
                final double scaleW = constraints.maxWidth / _baseW;
                final double scaleH = constraints.maxHeight / _baseH;
                final double scale = (scaleW < scaleH ? scaleW : scaleH) * 0.9;

                final double canvasW = _baseW * scale;
                final double canvasH = _baseH * scale;

                return Center(
                  child: SizedBox(
                    width: canvasW,
                    height: canvasH,
                    child: Opacity(
                      opacity: _tutteLeZone ? 0.3 : 1.0,
                      child: _buildFigura(colorScheme, scale, canvasW),
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 65),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () {
                final risultati = videoArchive.where((v) {
                  bool zoneMatch = _tutteLeZone || _zoneSelected.isEmpty || _zoneSelected.contains(v.category);
                  bool timeMatch = _qualsiasiTempo || v.durationMinutes <= _minutiSelected;
                  return zoneMatch && timeMatch;
                }).toList();
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => RisultatiRicercaScreen(videoFiltrati: risultati, isItalian: isItalian),
                ));
              },
              child: Text(
                isItalian ? "MOSTRA RISULTATI" : "SHOW RESULTS",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFigura(ColorScheme colorScheme, double s, double canvasW) {
    final double cx = canvasW / 2;

    final double headR  = 22.0 * s;
    final double headCY = 24.0 * s;
    final double neckH  = 14.0 * s;
    final double neckY  = headCY + headR;
    final double torsoW    = 92.0 * s;
    final double torsoX    = cx - torsoW / 2;
    final double torsoTopY = neckY + neckH + 4 * s;
    final double torsoTopH = 72.0 * s;
    final double torsoGap  = 4.0 * s;
    final double torsoBotY = torsoTopY + torsoTopH + torsoGap;
    final double torsoBotH = 72.0 * s;
    final double armGap = 4.0 * s;
    final double armW   = 24.0 * s;
    final double armH   = 110.0 * s;
    final double armY   = torsoTopY;
    final double armLX  = torsoX - armW - armGap;
    final double armRX  = torsoX + torsoW + armGap;
    final double handW  = 24.0 * s;
    final double handH  = 36.0 * s;
    final double handY  = armY + armH + armGap;
    final double handLX = armLX;
    final double handRX = armRX;
    final double legGap = 4.0 * s;
    final double legW   = 36.0 * s;
    final double legH   = 155.0 * s;
    final double legY   = torsoBotY + torsoBotH + legGap;
    final double legLX  = cx - legW - legGap / 2;
    final double legRX  = cx + legGap / 2;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: SilhouettePainter(
              color: colorScheme.onSurface,
              selectedAreas: _zoneSelected,
              isDisabled: _tutteLeZone,
              cx: cx, s: s,
            ),
          ),
        ),
        if (!_tutteLeZone) ...[
          _hit(left: cx - headR,  top: 0,         w: headR * 2, h: headCY + headR + neckH + 4 * s, label: "NECK AND CERVICAL"),
          _hit(left: torsoX,      top: torsoTopY, w: torsoW,    h: torsoTopH,                       label: "SHOULDERS AND UPPER BACK"),
          _hit(left: torsoX,      top: torsoBotY, w: torsoW,    h: torsoBotH,                       label: "BACK AND LUMBAR"),
          _hit(left: armLX,       top: armY,      w: armW,      h: armH,                            label: "ARMS AND ELBOWS"),
          _hit(left: armRX,       top: armY,      w: armW,      h: armH,                            label: "ARMS AND ELBOWS"),
          _hit(left: handLX,      top: handY,     w: handW,     h: handH,                           label: "WRISTS AND HANDS"),
          _hit(left: handRX,      top: handY,     w: handW,     h: handH,                           label: "WRISTS AND HANDS"),
          _hit(left: legLX,       top: legY,      w: legW,      h: legH,                            label: "LEGS AND ANKLES"),
          _hit(left: legRX,       top: legY,      w: legW,      h: legH,                            label: "LEGS AND ANKLES"),
        ],
      ],
    );
  }

  Widget _hit({required double left, required double top, required double w, required double h, required String label}) {
    return Positioned(
      left: left, top: top,
      child: GestureDetector(
        onTap: () => setState(() {
          final newSet = Set<String>.from(_zoneSelected);
          newSet.contains(label) ? newSet.remove(label) : newSet.add(label);
          _zoneSelected = newSet;
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
  final Set<String> selectedAreas;
  final bool isDisabled;
  final double cx;
  final double s;

  static const Color _hl = Color(0xFFE24B4A);

  const SilhouettePainter({
    required this.color,
    required this.cx,
    required this.s,
    this.selectedAreas = const {},
    this.isDisabled = false,
  });

  Paint _p(String zone) => Paint()
    ..color = (!isDisabled && selectedAreas.contains(zone)) ? _hl : color
    ..style = PaintingStyle.fill;

  RRect _rr(double x, double y, double w, double h, {double r = 8}) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r * s));

  @override
  void paint(Canvas canvas, Size size) {
    final double headR  = 22.0 * s;
    final double headCY = 24.0 * s;
    final double neckW  = 16.0 * s;
    final double neckH  = 14.0 * s;
    final double neckX  = cx - neckW / 2;
    final double neckY  = headCY + headR;
    final double torsoW    = 92.0 * s;
    final double torsoX    = cx - torsoW / 2;
    final double torsoTopY = neckY + neckH + 4 * s;
    final double torsoTopH = 72.0 * s;
    final double torsoGap  = 4.0 * s;
    final double torsoBotY = torsoTopY + torsoTopH + torsoGap;
    final double torsoBotH = 72.0 * s;
    final double armGap = 4.0 * s;
    final double armW   = 24.0 * s;
    final double armH   = 110.0 * s;
    final double armY   = torsoTopY;
    final double armLX  = torsoX - armW - armGap;
    final double armRX  = torsoX + torsoW + armGap;
    final double handW  = 24.0 * s;
    final double handH  = 36.0 * s;
    final double handY  = armY + armH + armGap;
    final double handLX = armLX;
    final double handRX = armRX;
    final double legGap = 4.0 * s;
    final double legW   = 36.0 * s;
    final double legH   = 155.0 * s;
    final double legY   = torsoBotY + torsoBotH + legGap;
    final double legLX  = cx - legW - legGap / 2;
    final double legRX  = cx + legGap / 2;

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
      old.selectedAreas != selectedAreas ||
      old.color != color ||
      old.isDisabled != isDisabled ||
      old.s != s;
}

// ---------------------------------------------------------------------------
//  RISULTATI RICERCA
// ---------------------------------------------------------------------------
class RisultatiRicercaScreen extends StatelessWidget {
  final List<ExerciseVideo> videoFiltrati;
  final bool isItalian;

  const RisultatiRicercaScreen({super.key, required this.videoFiltrati, required this.isItalian});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isItalian ? "${videoFiltrati.length} video trovati" : "${videoFiltrati.length} videos found"),
      ),
      body: videoFiltrati.isEmpty
          ? Center(child: Text(isItalian
              ? "Nessun esercizio trovato. Prova ad aumentare la durata!"
              : "No exercises found. Try increasing the duration!"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: videoFiltrati.length,
              itemBuilder: (context, index) {
                final v = videoFiltrati[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(video: v),
                    )),
                    child: Column(
                      children: [
                        Image.network(
                          "https://img.youtube.com/vi/${v.youtubeId}/hqdefault.jpg",
                          height: 200, width: double.infinity, fit: BoxFit.cover,
                        ),
                        ListTile(
                          title: Text(v.getTitle(isItalian), style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${_translateCategory(v.category, isItalian)} • ${v.durationMinutes} min"),
                          trailing: const Icon(Icons.play_circle_fill, color: Colors.red, size: 35),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
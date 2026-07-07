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
                final double scaleW = constraints.maxWidth / _baseW;
                final double scaleH = constraints.maxHeight / _baseH;
                final double scale = (scaleW < scaleH ? scaleW : scaleH) * 0.9;

                final double canvasW = _baseW * scale;
                final double canvasH = _baseH * scale;

                final layout = BodyZoneLayout(cx: canvasW / 2, s: scale);

                return Center(
                  child: SizedBox(
                    width: canvasW,
                    height: canvasH,
                    child: Opacity(
                      opacity: _tutteLeZone ? 0.3 : 1.0,
                      child: _buildFigure(layout),
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
                  builder: (context) => SearchResults(videoFiltrati: risultati, isItalian: isItalian),
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

   Widget _buildFigure(BodyZoneLayout layout) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: SilhouettePainter(
              color: Theme.of(context).colorScheme.onSurface,
              selectedAreas: _zoneSelected,
              isDisabled: _tutteLeZone,
              layout: layout,
            ),
          ),
        ),
        if (!_tutteLeZone)
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
          final newSet = Set<String>.from(_zoneSelected);
          newSet.contains(label) ? newSet.remove(label) : newSet.add(label);
          _zoneSelected = newSet;
        }),
        child: Container(width: rect.width, height: rect.height, color: Colors.transparent),
      ),
    );
  }
}

//  SILHOUETTE PAINTER

class SilhouettePainter extends CustomPainter {
  final Color color;
  final Set<String> selectedAreas;
  final bool isDisabled;
  final BodyZoneLayout layout;

  static const Color _hl = Color(0xFFE24B4A);

  const SilhouettePainter({
    required this.color,
    required this.layout,
    this.selectedAreas = const {},
    this.isDisabled = false,
  });

  Paint _p(String zone) => Paint()
    ..color = (!isDisabled && selectedAreas.contains(zone)) ? _hl : color
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
      old.selectedAreas != selectedAreas ||
      old.color != color ||
      old.isDisabled != isDisabled ||
      old.layout.s != layout.s ||
      old.layout.cx != layout.cx;
}

//  SEARCH RESULTS

class SearchResults extends StatelessWidget {
  final List<ExerciseVideo> videoFiltrati;
  final bool isItalian;

  const SearchResults({super.key, required this.videoFiltrati, required this.isItalian});

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
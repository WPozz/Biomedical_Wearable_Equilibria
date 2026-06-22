import 'package:flutter/material.dart';
import '../data/video_archive.dart';
import 'video_player.dart';
import 'cerca_esercizio.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class EserciziScreen extends StatefulWidget {
  const EserciziScreen({super.key});

  @override
  State<EserciziScreen> createState() => _EserciziScreenState();
}

class _EserciziScreenState extends State<EserciziScreen> {
  late List<ExerciseVideo> _randomQuickVideos;

  @override
  void initState() {
    super.initState();
    _generateRandomVideos();
  }

  void _generateRandomVideos() {
    var copy = List<ExerciseVideo>.from(videoArchive);
    copy.shuffle(); 
    _randomQuickVideos = copy.take(4).toList(); 
  }

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isItalian = context.watch<SettingsProvider>().isItalian;

    return Scaffold(
      appBar: AppBar(
        title: Text(isItalian ? "Libreria esercizi" : "Exercise library", style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BOTTONE RICERCA
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const CercaEsercizioScreen())
                ).then((_) {
                  setState(() {
                    _generateRandomVideos();
                  });
                }),
                icon: const Icon(Icons.manage_search_rounded, size: 28),
                label: Text(isItalian ? "CERCA PER PARTE DEL CORPO E TEMPO" : "SEARCH BY BODY PART AND TIME"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 65),
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(isItalian ? "Scelti per te" : "Quick picks", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),

            // Lista randomica
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GridView.builder(
                shrinkWrap: true, 
                physics: const NeverScrollableScrollPhysics(), 
                itemCount: _randomQuickVideos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,          
                  crossAxisSpacing: 8,        
                  mainAxisSpacing: 8,         
                  childAspectRatio: 1.3,      
                ),
                itemBuilder: (context, index) {
                  final video = _randomQuickVideos[index];
                  return _buildQuickCard(context, video, isItalian);
                },
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(isItalian ? "Tutti" : "All", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),

            // ListView completo
            ListView.builder(
              shrinkWrap: true, 
              physics: const NeverScrollableScrollPhysics(), 
              itemCount: videoArchive.length,
              itemBuilder: (context, index) {
                final video = videoArchive[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      "https://img.youtube.com/vi/${video.youtubeId}/default.jpg",
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(video.getTitle(isItalian), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${_translateCategory(video.category, isItalian)} • ${video.durationMinutes} min"),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(video: video)
                  )),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCard(BuildContext context, ExerciseVideo video, bool isItalian) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(video: video)
          ));
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: NetworkImage("https://img.youtube.com/vi/${video.youtubeId}/hqdefault.jpg"),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.4),
                BlendMode.darken,
              ),
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0), 
              child: Text(
                video.getTitle(isItalian),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14, 
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
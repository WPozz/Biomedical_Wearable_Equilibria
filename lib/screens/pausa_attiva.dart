import 'package:flutter/material.dart';
import '../screens/selezione_dolore.dart';
import 'dart:math'; 
import '../data/video_archive.dart'; 
import 'video_player.dart';

class PausaAttivaScreen extends StatelessWidget {
  const PausaAttivaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 100,
        title: Text(
          "Pick your break",
          style: TextStyle(
            color: colorScheme.onSurface, 
            fontWeight: FontWeight.bold,
            fontSize: 32, 
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // --- TOTAL BODY ---
                _buildOptionCard(
                  context: context,
                  title: "Full body",
                  duration: "3 min",
                  icon: Icons.accessibility_new_rounded,
                  cardColor: colorScheme.primary, 
                  contentColor: colorScheme.onPrimary, 
                  onTap: () {
                    // 1. Filtro
                    final totalBodyVideos = videoArchive
                        .where((v) => v.category == "FULL BODY")
                        .toList();

                    if (totalBodyVideos.isNotEmpty) {
                      // 2. Random
                      final randomVideo = totalBodyVideos[Random().nextInt(totalBodyVideos.length)];
                      
                      // 3. Player
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerScreen(video: randomVideo),
                        ),
                      );
                    } else {
                      // Caso archivio vuoto
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No Full Body videos available")),
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 24),

                // --- SOLLIEVO MIRATO ---
                _buildOptionCard(
                  context: context,
                  title: "Targeted relief",
                  duration: "5 min",
                  icon: Icons.ads_click_rounded,
                  cardColor: colorScheme.tertiary, 
                  contentColor: colorScheme.onTertiary, 
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SelezioneDoloreScreen()),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String duration,
    required IconData icon,
    required Color cardColor,
    required Color contentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 54, color: contentColor),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: contentColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: contentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  duration,
                  style: TextStyle(
                    color: contentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
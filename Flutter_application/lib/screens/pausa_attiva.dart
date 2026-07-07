import 'package:flutter/material.dart';
import 'package:flutter_application/screens/selezione_dolore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/providers/settings_provider.dart';
import 'dart:math';
import '../data/video_archive.dart';
import 'video_player.dart';

class ActiveBreakScreen extends StatelessWidget {
  const ActiveBreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isItalian   = context.watch<SettingsProvider>().isItalian;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 100,
        title: Text(
          isItalian ? 'Scegli la tua pausa' : 'Pick your break',
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
                  title: isItalian ? 'Corpo intero' : 'Full body',
                  icon: Icons.accessibility_new_rounded,
                  cardColor: colorScheme.primary,
                  contentColor: colorScheme.onPrimary,
                  onTap: () {
                    final totalBodyVideos = videoArchive
                        .where((v) => v.category == 'FULL BODY')
                        .toList();

                    if (totalBodyVideos.isNotEmpty) {
                      final randomVideo = totalBodyVideos[
                          Random().nextInt(totalBodyVideos.length)];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VideoPlayerScreen(video: randomVideo),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isItalian
                                ? 'Nessun video disponibile'
                                : 'No Full Body videos available',
                          ),
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 24),

                // --- TARGET RELIEF ---
                _buildOptionCard(
                  context: context,
                  title: isItalian ? 'Sollievo mirato' : 'Targeted relief',
                  icon: Icons.ads_click_rounded,
                  cardColor: colorScheme.tertiary,
                  contentColor: colorScheme.onTertiary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PainSelectionScreen()),
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
            ],
          ),
        ),
      ),
    );
  }
}
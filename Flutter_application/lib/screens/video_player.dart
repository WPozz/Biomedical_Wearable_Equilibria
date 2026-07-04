import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as mobile;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/providers/settings_provider.dart';
import '../data/video_archive.dart';

class VideoPlayerScreen extends StatefulWidget {
  final ExerciseVideo video;
  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _webController;
  mobile.YoutubePlayerController? _mobileController;

  bool _videoEnded = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _webController = YoutubePlayerController.fromVideoId(
        videoId: widget.video.youtubeId,
        autoPlay: true,
        params: const YoutubePlayerParams(mute: false),
      );
      
      _webController!.listen((value) {
        if (!_videoEnded && value.playerState == PlayerState.ended) {
          if (mounted) setState(() => _videoEnded = true);
        }
      });
    } else {
      _mobileController = mobile.YoutubePlayerController(
        initialVideoId: widget.video.youtubeId,
        flags: const mobile.YoutubePlayerFlags(autoPlay: true),
      );
      _mobileController!.addListener(_onMobilePlayerStateChanged);
    }
  }

  void _onMobilePlayerStateChanged() {
    if (_videoEnded) return;
    if (_mobileController!.value.playerState == mobile.PlayerState.ended) {
      if (mounted) setState(() => _videoEnded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isItalian = context.watch<SettingsProvider>().isItalian; 

    // ── WEB ──
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(title: Text(widget.video.getTitle(isItalian)), centerTitle: true), 
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  "https://img.youtube.com/vi/${widget.video.youtubeId}/hqdefault.jpg",
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                widget.video.getTitle(isItalian), // <-- Sostituito con getTitle
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              _buildCompletionBanner(context, isItalian),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  launchUrl(
                    Uri.parse("https://www.youtube.com/watch?v=${widget.video.youtubeId}"),
                    mode: LaunchMode.externalApplication,
                  );
                },
                icon: const Icon(Icons.play_circle_fill, size: 28),
                label: Text(isItalian ? "Guarda su YouTube" : "Watch on YouTube", style: const TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 65),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 16),
              _buildEndButton(context, isItalian),
            ],
          ),
        ),
      );
    }

    // ── MOBILE ──
    return mobile.YoutubePlayerBuilder(
      player: mobile.YoutubePlayer(
        controller: _mobileController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: colorScheme.primary,
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(title: Text(widget.video.getTitle(isItalian)), centerTitle: true), 
          body: Column(
            children: [
              player,
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          _videoEnded
                              ? (isItalian ? "Esercizio completato!" : "Exercise completed!")
                              : (isItalian ? "Continua così!" : "Keep it up!"),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _videoEnded
                              ? (isItalian
                                  ? "Ottimo lavoro, la tua pausa attiva è finita"
                                  : "Great job, your active break is over")
                              : (isItalian
                                  ? "Respira e segui i movimenti con calma"
                                  : "Breathe and follow the movements calmly"),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // COMPLETION CHECK
                        ValueListenableBuilder<mobile.YoutubePlayerValue>(
                          valueListenable: _mobileController!,
                          builder: (context, value, child) {
                            if (_videoEnded) {
                              return Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primaryContainer,
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 64,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              );
                            }

                            final duration = value.metaData.duration.inSeconds;
                            final position = value.position.inSeconds;
                            final progress = (duration > 0) ? (position / duration) : 0.0;
                            final remaining = duration - position;

                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 130,
                                  height: 130,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 10,
                                    backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                                    color: colorScheme.primary,
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      "${(remaining ~/ 60)}:${(remaining % 60).toString().padLeft(2, '0')}",
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                    ),
                                    Text(isItalian ? "rimanenti" : "remaining", style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 40),
                        _buildEndButton(context, isItalian),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletionBanner(BuildContext context, bool isItalian) {
    if (!_videoEnded) return const SizedBox(height: 32);
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            isItalian ? "Esercizio completato!" : "Exercise completed!",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndButton(BuildContext context, bool isItalian) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_videoEnded) {
      return FilledButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.check_rounded),
        label: Text(
          isItalian ? "Fatto" : "Done",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      );
    }

    return OutlinedButton(
      onPressed: () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(isItalian ? "Termina Pausa" : "End Break"),
    );
  }

  @override
  void dispose() {
    _mobileController?.removeListener(_onMobilePlayerStateChanged);
    _webController?.close();
    _mobileController?.dispose();
    super.dispose();
  }
}
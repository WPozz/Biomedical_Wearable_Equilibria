import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as mobile;
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
  late final mobile.YoutubePlayerController _mobileController;

  bool _videoEnded = false;

  @override
  void initState() {
    super.initState();
    _mobileController = mobile.YoutubePlayerController(
      initialVideoId: widget.video.youtubeId,
      flags: const mobile.YoutubePlayerFlags(autoPlay: true),
    );
    _mobileController.addListener(_onMobilePlayerStateChanged);
  }

  void _onMobilePlayerStateChanged() {
    if (_videoEnded) return;
    if (_mobileController.value.playerState == mobile.PlayerState.ended) {
      if (mounted) setState(() => _videoEnded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isItalian = context.watch<SettingsProvider>().isItalian;

    return mobile.YoutubePlayerBuilder(
      player: mobile.YoutubePlayer(
        controller: _mobileController,
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
                          valueListenable: _mobileController,
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
    _mobileController.removeListener(_onMobilePlayerStateChanged);
    _mobileController.dispose();
    super.dispose();
  }
}
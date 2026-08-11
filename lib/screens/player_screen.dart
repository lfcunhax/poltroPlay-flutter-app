import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poltro_play/models/watch_progress.dart';
import 'package:poltro_play/providers/watch_progress_provider.dart';
import 'package:poltro_play/core/services/storage_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:poltro_play/widgets/cast_button.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String videoUrl;
  final String title;
  final String contentId;
  final String contentType;
  final String? posterPath;
  final bool isTrailer;

  const PlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.contentId,
    required this.contentType,
    this.posterPath,
    this.isTrailer = false,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  bool _isInitialized = false;
  int _lastSavedSecond = -1;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (widget.isTrailer) {
      _youtubeController = YoutubePlayerController(
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
        ),
      );
      _youtubeController!.loadVideoById(videoId: widget.videoUrl);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      return;
    }

    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await _videoPlayerController.initialize();

    // Restore saved progress
    final storage = StorageService();
    final savedProgress = storage.getWatchProgress(widget.contentId);
    if (savedProgress != null && savedProgress.positionMs > 0) {
      await _videoPlayerController
          .seekTo(Duration(milliseconds: savedProgress.positionMs));
    }

    _videoPlayerController.addListener(_onVideoProgress);

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFF00D4FF),
        handleColor: const Color(0xFF00D4FF),
        backgroundColor: Colors.white24,
        bufferedColor: Colors.white54,
      ),
      placeholder: Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF7B2FF7)),
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _onVideoProgress() {
    if (!_videoPlayerController.value.isInitialized) return;

    final position = _videoPlayerController.value.position.inSeconds;

    // Save progress every 10 seconds
    if (position > 0 && position != _lastSavedSecond && position % 10 == 0) {
      _lastSavedSecond = position;
      _saveProgress();
    }

    // Also save on pause
    if (!_videoPlayerController.value.isPlaying &&
        _videoPlayerController.value.position.inMilliseconds > 0) {
      _saveProgress();
    }
  }

  Future<void> _saveProgress() async {
    if (!_videoPlayerController.value.isInitialized) return;

    final progress = WatchProgress(
      contentId: widget.contentId,
      contentType: widget.contentType,
      title: widget.title,
      posterPath: widget.posterPath,
      videoUrl: widget.videoUrl,
      positionMs: _videoPlayerController.value.position.inMilliseconds,
      durationMs: _videoPlayerController.value.duration.inMilliseconds,
      lastWatched: DateTime.now(),
    );

    ref.read(watchProgressListProvider.notifier).saveProgress(progress);
  }

  Future<bool> _onWillPop() async {
    await _saveProgress();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return true;
  }

  @override
  void dispose() {
    if (!widget.isTrailer) {
      _saveProgress();
      _videoPlayerController.removeListener(_onVideoProgress);
      _videoPlayerController.dispose();
      _chewieController?.dispose();
    } else {
      _youtubeController?.close();
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _handleBack() async {
    final bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Sair do vídeo?',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Você tem certeza que deseja sair agora?',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Continuar Assistindo',
                style: GoogleFonts.inter(color: const Color(0xFF00D4FF), fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Sair',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (shouldPop == true) {
      if (mounted) {
        if (!widget.isTrailer) {
          _saveProgress();
        }
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        
        setState(() {
          _canPop = true;
        });

        Future.microtask(() {
          if (mounted) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: _isInitialized
                  ? (widget.isTrailer && _youtubeController != null)
                      ? YoutubePlayer(
                          controller: _youtubeController!,
                        )
                      : (_chewieController != null
                          ? Chewie(controller: _chewieController!)
                          : const Center(child: CircularProgressIndicator()))
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF7B2FF7)),
                          SizedBox(height: 16),
                          Text(
                            'Carregando vídeo...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _handleBack,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: CastButton(
                    videoUrl: widget.videoUrl,
                    title: widget.title,
                    posterUrl: widget.posterPath,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

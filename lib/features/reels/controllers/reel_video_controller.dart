import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

class ReelVideoController {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  VoidCallback? _listener;

  // للتحكم في تلاشي الصوت
  AnimationController? _fadeController;
  Animation<double>? _volumeAnimation;

  final String videoUrl;
  final TickerProvider vsync;

  // حالة الفيديو
  bool isInitialized = false;
  bool isBuffering = false;
  bool isPlaying = false;

  // callbacks لتحديث الواجهة
  final Function(bool isPlaying, bool isBuffering) onStateChanged;

  ReelVideoController({
    required this.videoUrl,
    required this.vsync,
    required this.onStateChanged,
  });

  Future<void> initialize() async {
    if (isInitialized) return;

    try {
      final fileInfo = await DefaultCacheManager().getFileFromCache(videoUrl);

      if (fileInfo != null && await fileInfo.file.exists()) {
        _videoPlayerController = VideoPlayerController.file(fileInfo.file);
      } else {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        DefaultCacheManager().downloadFile(videoUrl);
      }

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        looping: true,
        autoPlay: false,
        showControls: false,
        allowFullScreen: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        placeholder: Container(color: Colors.black),
      );

      _fadeController = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 800),
      );
      _volumeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController!, curve: Curves.easeIn),
      );

      _fadeController!.addListener(() {
        if (_videoPlayerController != null) {
          _videoPlayerController!.setVolume(_volumeAnimation!.value);
        }
      });

      _listener = () {
        if (_videoPlayerController == null) return;
        final value = _videoPlayerController!.value;

        final bool newIsBuffering = value.isBuffering;
        final bool newIsPlaying = value.isPlaying;

        if (newIsBuffering != isBuffering || newIsPlaying != isPlaying) {
          isBuffering = newIsBuffering;
          isPlaying = newIsPlaying;
          onStateChanged(isPlaying, isBuffering);
        }

        if (newIsBuffering) {
          _fadeController?.reverse();
        } else if (newIsPlaying &&
            _fadeController?.status != AnimationStatus.completed) {
          _fadeController?.forward();
        }
      };

      _videoPlayerController!.addListener(_listener!);
      isInitialized = true;
      onStateChanged(false, false);
    } catch (e) {
      debugPrint("Error initializing video: $e");
    }
  }

  void play() {
    if (isInitialized && _videoPlayerController != null) {
      _videoPlayerController!.play();
    }
  }

  void pause() {
    if (isInitialized && _videoPlayerController != null) {
      _fadeController?.reverse();
      _videoPlayerController!.pause();
    }
  }

  ChewieController? get chewieController => _chewieController;
  VideoPlayerController? get videoPlayerController => _videoPlayerController;

  // ✅ التصحيح 1: إزالة Listener بشكل صريح لمنع Memory Leak
  void dispose() {
    if (_listener != null && _videoPlayerController != null) {
      _videoPlayerController!.removeListener(_listener!);
    }
    _fadeController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    isInitialized = false;
  }
}

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:ui_web';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stavax',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AudioPlayerScreen(),
    );
  }
}

class PositionData {
  const PositionData(
    this.position,
    this.bufferedPosition,
    this.duration,
  );

  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _audioPlayer;

  final _playlist = ConcatenatingAudioSource(
    children: [
      AudioSource.uri(
        Uri.parse('assets/song/Flaming_Hot_Cheetos.mp3'),
        tag: MediaItem(
          id: '0',
          title: 'Flaming Hot Cheetos',
          artist: 'Clairo',
          artUri: Uri.parse(
            'assets/pict/Flaming_Hot_Cheetos.png',
          ),
        ),
      ),
      AudioSource.uri(
        Uri.parse('assets/song/Duvet.mp3'),
        tag: MediaItem(
          id: '1',
          title: 'Duvet',
          artist: 'Boa',
          artUri: Uri.parse(
            'assets/pict/Duvet.png',
          ),
        ),
      ),
      AudioSource.uri(
        Uri.parse('assets/song/Moonlight.mp3'),
        tag: MediaItem(
          id: '2',
          title: 'Moonlight',
          artist: 'Kali Uchis',
          artUri: Uri.parse(
            'assets/pict/Moonlight.png',
          ),
        ),
      ),
      AudioSource.uri(
        Uri.parse('assets/song/Shut_Up_My_Moms_Calling.mp3'),
        tag: MediaItem(
          id: '3',
          title: 'Shut Up My Moms Calling',
          artist: 'Hotel Ugly',
          artUri: Uri.parse(
            'assets/pict/Shut_Up_My_Moms_Calling.png',
          ),
        ),
      ),
    ],
  );

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.bufferedPositionStream,
        _audioPlayer.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position,
          bufferedPosition,
          duration ?? Duration.zero,
        ),
      );

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    await _audioPlayer.setLoopMode(LoopMode.all);
    await _audioPlayer.setAudioSource(_playlist);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_horiz),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff1c2127), Color(0xFF071A2C)],
        )),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<SequenceState?>(
                stream: _audioPlayer.sequenceStateStream,
                builder: (context, snapshot) {
                  final state = snapshot.data;
                  if (state?.sequence.isEmpty ?? true) {
                    return const SizedBox();
                  }
                  final metadata = state!.currentSource!.tag as MediaItem;
                  return MediaMetadata(
                      imageUrl: metadata.artUri.toString(),
                      title: metadata.title,
                      artist: metadata.artist ?? '');
                }),
            const SizedBox(
              height: 20,
            ),
            StreamBuilder<PositionData>(
              stream: _positionDataStream,
              builder: (context, snapshot) {
                final positionData = snapshot.data;
                return ProgressBar(
                  barHeight: 8,
                  baseBarColor: Colors.grey[600],
                  bufferedBarColor: Colors.grey,
                  thumbColor: Color(0xff0b385f),
                  progressBarColor: Color(0xff3373b0),
                  timeLabelTextStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                  progress: positionData?.position ?? Duration.zero,
                  buffered: positionData?.bufferedPosition ?? Duration.zero,
                  total: positionData?.duration ?? Duration.zero,
                  onSeek: _audioPlayer.seek,
                );
              },
            ),
            Controls(audioPlayer: _audioPlayer),
          ],
        ),
      ),
    );
  }
}

class MediaMetadata extends StatelessWidget {
  const MediaMetadata({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.artist,
  });

  final String imageUrl;
  final String title;
  final String artist;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      DecoratedBox(
        decoration: BoxDecoration(
          // boxShadow: const [
          //   BoxShadow(
          //     color: Colors.black,
          //     offset: Offset(2, 4),
          //     blurRadius: 4,
          //   ),
          // ],
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            imageUrl,
            height: 300,
            width: 300,
          ),
        ),
      ),
      const SizedBox(
        height: 8,
      ),
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
        ),
        textAlign: TextAlign.center,
      ),
      Text(
        artist,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
        ),
        textAlign: TextAlign.center,
      )
    ]);
  }
}

class Controls extends StatelessWidget {
  const Controls({
    super.key,
    required this.audioPlayer,
  });

  final AudioPlayer audioPlayer;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: audioPlayer.seekToPrevious,
          icon: Icon(
            Icons.skip_previous_rounded,
            size: 60,
            color: Colors.white,
          ),
        ),
        StreamBuilder(
          stream: audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (!(playing ?? false)) {
              return IconButton(
                onPressed: audioPlayer.play,
                iconSize: 80,
                color: Colors.white,
                icon: const Icon(Icons.play_arrow_rounded),
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                onPressed: audioPlayer.pause,
                iconSize: 80,
                color: Colors.white,
                icon: const Icon(Icons.pause_rounded),
              );
            }
            return const Icon(
              Icons.play_arrow_rounded,
              size: 80,
              color: Colors.white,
            );
          },
        ),
        IconButton(
          onPressed: audioPlayer.seekToNext,
          icon: Icon(
            Icons.skip_next_rounded,
            size: 60,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

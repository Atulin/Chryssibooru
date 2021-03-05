import 'package:chryssibooru/API/v2/API.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayer extends StatefulWidget {
  CustomVideoPlayer({@required this.derpi});

  final Derpi derpi;

  @override
  State<StatefulWidget> createState() => _CustomVideoPlayer();
}

class _CustomVideoPlayer extends State<CustomVideoPlayer> {
  Derpi _derpi;

  VideoPlayerController _videoController;
  double _volume = 0.0;
  bool _autoplay = false;
  double _videoProgressPercent = 0.0;

  @override
  void initState() {
    _derpi = widget.derpi;

    super.initState();
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  didChangeDependencies() {
    _videoController?.dispose();
    _videoController =
        VideoPlayerController.network(_derpi.representations.medium)
          ..addListener(() {
            setState(() {
              if (_videoController.value.duration != null) {
                _videoProgressPercent = (_videoController.value.position.inMilliseconds / _videoController.value.duration.inMilliseconds).clamp(0.0, 1.0);
              }
            });
          })
          ..initialize().then((_) {
            _videoController.setVolume(_volume);
            _videoController.setLooping(true);
            if (_autoplay) _videoController.play();
            setState(() {});
          });

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            child: _videoController.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: VideoPlayer(_videoController),
                  )
                : CircularProgressIndicator(),
            onTap: () {
              setState(() {
                _videoController.value.isPlaying
                    ? _videoController.pause()
                    : _videoController.play();
                _autoplay = _autoplay ? false : true;
              });
            },
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: IconButton(
              icon: Icon(_videoController.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow),
              onPressed: () => setState(() {
                    _videoController.value.isPlaying
                        ? _videoController.pause()
                        : _videoController.play();
                    _autoplay = _autoplay ? false : true;
                  })),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: IconButton(
              icon: Icon(_videoController.value.volume > 0
                  ? Icons.volume_up
                  : Icons.volume_off),
              onPressed: () => setState(() {
                    _videoController.value.volume > 0
                        ? _volume = 0.0
                        : _volume = 50.0;
                    _videoController.setVolume(_volume);
                  })),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
              height: 3,
              child: new LinearPercentIndicator(
                padding: EdgeInsets.all(0.0),
                linearStrokeCap: LinearStrokeCap.butt,
                lineHeight: 3.0,
                progressColor: Colors.teal,
                percent: _videoProgressPercent,
              )),
        )
      ],
    );
  }
}

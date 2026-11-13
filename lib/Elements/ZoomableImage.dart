import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

/// A single zoomable image of the slideshow, with loading and error
/// states. Extracted from [ImageViewer] to keep the viewer's build
/// method shallow.
///
/// Pinching zooms the image, a double tap switches between the regular
/// and the maximum zoom level, and a zoomed image can be panned. The
/// viewer disables page swiping while the image is zoomed (via
/// [onZoomChanged]), so panning takes precedence; while not zoomed in,
/// one-finger drags belong to the page swipe.
class ZoomableImage extends StatefulWidget {
  const ZoomableImage({
    super.key,
    required this.url,
    required this.isActive,
    required this.onZoomChanged,
  });

  final String url;

  /// Whether this image is the visible page. Zoom resets when the page
  /// becomes inactive.
  final bool isActive;

  /// Called when the image starts or stops being zoomed in.
  final ValueChanged<bool> onZoomChanged;

  @override
  ZoomableImageState createState() => ZoomableImageState();
}

class ZoomableImageState extends State<ZoomableImage>
    with SingleTickerProviderStateMixin {
  /// Scale reached by a double tap and the upper limit for pinching.
  static const double _maxScale = 4.0;

  /// Scales above this value count as zoomed in.
  static const double _zoomedThreshold = 1.01;

  final TransformationController _transformationController =
      TransformationController();

  late final AnimationController _zoomController;
  Animation<Matrix4>? _zoomAnimation;
  Offset? _doubleTapPosition;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _zoomController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 180),
        )..addListener(() {
          final animation = _zoomAnimation;
          if (animation != null) {
            _transformationController.value = animation.value;
          }
        });
    _transformationController.addListener(_handleTransformChanged);
  }

  @override
  void didUpdateWidget(ZoomableImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _resetZoom(notify: false);
    } else if (oldWidget.isActive && !widget.isActive) {
      _resetZoom(notify: false);
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_handleTransformChanged);
    _transformationController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  double get _scale => _transformationController.value.getMaxScaleOnAxis();

  void _handleTransformChanged() {
    final zoomed = _scale > _zoomedThreshold;
    if (zoomed == _zoomed) return;
    setState(() => _zoomed = zoomed);
    widget.onZoomChanged(zoomed);
  }

  void _resetZoom({bool notify = true}) {
    _zoomController.stop();
    _zoomAnimation = null;
    final wasZoomed = _zoomed;
    _zoomed = false;
    _transformationController.value = Matrix4.identity();
    if (notify && wasZoomed) widget.onZoomChanged(false);
  }

  /// Matrix that scales around [focalPoint], keeping it in place.
  static Matrix4 _zoomMatrix(Offset focalPoint, double scale) {
    return Matrix4.identity()
      ..translateByDouble(
        focalPoint.dx * (1 - scale),
        focalPoint.dy * (1 - scale),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _animateTo(Matrix4 target) {
    _zoomAnimation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: target,
        ).animate(
          CurvedAnimation(parent: _zoomController, curve: Curves.easeOutCubic),
        );
    _zoomController.forward(from: 0);
  }

  void _toggleZoom() {
    if (_scale > _zoomedThreshold) {
      _animateTo(Matrix4.identity());
      return;
    }

    final size = context.size;
    final focalPoint =
        _doubleTapPosition ??
        (size == null ? Offset.zero : size.center(Offset.zero));
    _animateTo(_zoomMatrix(focalPoint, _maxScale));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTapDown: (details) {
        _doubleTapPosition = details.localPosition;
      },
      onDoubleTap: _toggleZoom,
      child: ClipRect(
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1.0,
          maxScale: _maxScale,
          // While not zoomed in, one-finger drags belong to the page swipe.
          // Pinching stays available because it is a separate gesture.
          panEnabled: _zoomed,
          onInteractionStart: (_) {
            _zoomController.stop();
            _zoomAnimation = null;
          },
          child: ColoredBox(
            color: Colors.black,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.url,
                // No fade transitions: when swiping, media should appear
                // instantly once it is available.
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (context, url) =>
                    Image(image: AssetImage('assets/logo-medium.png')),
                errorWidget: (context, url, error) =>
                    Image(image: AssetImage('assets/logo-medium.png')),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

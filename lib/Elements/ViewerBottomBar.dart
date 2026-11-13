import 'package:material_ui/material_ui.dart';

/// The counter / details / score bar shown at the bottom of the
/// slideshow. Extracted from [ImageViewer] so the viewer's build method
/// stays shallow.
///
/// Built from a plain [Material] instead of a [BottomAppBar]: the app
/// bar widget re-applies system insets inside itself, which pushed the
/// row below the screen edge on some devices.
class ViewerBottomBar extends StatelessWidget {
  const ViewerBottomBar({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    required this.score,
    required this.onDetailsRequested,
  });

  /// Zero-based index of the currently shown entry.
  final int currentIndex;
  final int totalCount;
  final int score;

  /// Opens the details sheet for the current entry.
  final VoidCallback onDetailsRequested;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        final bool landscape = orientation == Orientation.landscape;
        // The SafeArea adds whatever bottom inset the device reports;
        // the explicit 10 dp bottom padding additionally keeps the row
        // clear of the gesture bar on devices that report none. Height
        // and side padding are tuned down from the Material 3 defaults
        // while keeping enough clearance for rounded screen corners.
        return SafeArea(
          top: false,
          child: Material(
            color: landscape
                ? Colors.transparent
                : Theme.of(context).colorScheme.surface,
            elevation: landscape ? 0.0 : 8.0,
            child: Container(
              height: 44.0,
              padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 10.0),
              child: SizedBox(
                height: 30,
                child: Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${currentIndex + 1}/$totalCount'),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: onDetailsRequested,
                        child: const Icon(Icons.keyboard_arrow_up),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        score.toString(),
                        style: TextStyle(
                          color: score >= 0
                              ? const Color.fromARGB(255, 0, 255, 0)
                              : const Color.fromARGB(255, 255, 0, 0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

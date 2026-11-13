import 'package:chryssibooru/API/v2/API.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:chryssibooru/Elements/IcoText.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../Helpers.dart';

class DetailsSheet extends StatefulWidget {
  const DetailsSheet({super.key, required this.derpi});

  final Derpi derpi;

  @override
  DetailsSheetState createState() => DetailsSheetState();
}

class DetailsSheetState extends State<DetailsSheet> {
  late Derpi _derpi;
  late List<Tag> _tags;

  DerpisRepo? _repo;
  DerpisRepo get repo {
    _repo ??= context.read<DerpisRepo>();
    return _repo!;
  }

  @override
  void initState() {
    _derpi = widget.derpi;
    _tags = widget.derpi.tags;
    super.initState();
  }

  void _tagAction(String tag, void Function(String) action) {
    repo.derpis = [];
    action(tag);
    repo.restartSearch();
    Navigator.of(context).pop(); // Close the tag action sheet.
  }

  Future<void> _download(String url) async {
    final message = await downloadImage(url);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _iconButton(IconData icon, String tooltip, VoidCallback? onTap) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }

  Widget _linkActionSheet(
    String postLink,
    String? imageLink,
    void Function(String) action,
  ) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: imageLink == null ? 50.0 : 100.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                action(postLink);
              },
              child: Text("Derpibooru post"),
            ),
            if (imageLink != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  action(imageLink);
                },
                child: Text("Direct image"),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postUrl = "https://derpibooru.org/${_derpi.id}";
    final directUrl = _derpi.representations.full;
    final imageUrl = directUrl == null || directUrl.isEmpty
        ? null
        : "https:$directUrl";
    return Padding(
      // Room above the drag handle and below the system gesture bar.
      padding: EdgeInsets.only(
        top: 12.0,
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 4.0, 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(_derpi.id.toString()),
                OverflowBar(
                  spacing: 4.0,
                  children: <Widget>[
                    _iconButton(Icons.share, "Share", () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return _linkActionSheet(
                            postUrl,
                            imageUrl,
                            (link) => SharePlus.instance.share(
                              ShareParams(text: link),
                            ),
                          );
                        },
                      );
                    }),
                    _iconButton(Icons.link, "Open in browser", () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return _linkActionSheet(postUrl, imageUrl, (
                            link,
                          ) async {
                            final messenger = ScaffoldMessenger.maybeOf(
                              context,
                            );
                            final ok = await openInBrowser(link);
                            if (ok) return;
                            messenger?.showSnackBar(
                              const SnackBar(
                                content: Text('Could not open the link'),
                              ),
                            );
                          });
                        },
                      );
                    }),
                    _iconButton(Icons.content_copy, "Copy link", () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return _linkActionSheet(
                            postUrl,
                            imageUrl,
                            (link) =>
                                Clipboard.setData(ClipboardData(text: link)),
                          );
                        },
                      );
                    }),
                    _iconButton(
                      Icons.file_download,
                      "Download",
                      imageUrl == null
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  content: Text("Downloading image..."),
                                ),
                              );
                              _download(imageUrl);
                            },
                    ),
                  ],
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 100.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  const Spacer(flex: 10),
                  IcoText(
                    text: _derpi.commentCount.toString(),
                    icon: Icons.chat_bubble_outline,
                    color: const Color.fromARGB(255, 176, 153, 221),
                  ),
                  const Spacer(),
                  IcoText(
                    text: _derpi.faves.toString(),
                    icon: Icons.star_border,
                    color: Colors.amber,
                  ),
                  const Spacer(),
                  IcoText(
                    text: (_derpi.score - _derpi.downvotes).toString(),
                    icon: Icons.arrow_upward,
                    color: Colors.green,
                    reverse: true,
                  ),
                  Text(_derpi.score.toString()),
                  IcoText(
                    text: _derpi.downvotes.toString(),
                    icon: Icons.arrow_downward,
                    color: Colors.red,
                  ),
                  const Spacer(flex: 10),
                ],
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 100.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(_derpi.description ?? ''),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  alignment: WrapAlignment.center,
                  children: [for (final tag in _tags) _buildTagChip(tag)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tag chip with an explicitly readable label colour — the Material 3
  /// default dimmed the text into the background on the grey pills.
  Widget _buildTagChip(Tag tag) {
    final background =
        {
          TagType.ARTIST: Colors.blue,
          TagType.OC: Colors.green,
          TagType.SPOILER: Colors.red,
        }[tag.type] ??
        Colors.grey;
    final labelColor = tag.type == null ? Colors.black87 : Colors.white;
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext c) {
            return SafeArea(
              top: false,
              child: SizedBox(
                height: 150.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => _tagAction(tag.label, repo.addTag),
                      child: Text("Add to search"),
                    ),
                    TextButton(
                      onPressed: () => _tagAction(tag.label, repo.removeTag),
                      child: Text("Remove from search"),
                    ),
                    TextButton(
                      onPressed: () {
                        repo.derpis = [];
                        repo.query = tag.label;
                        repo.restartSearch();
                        Navigator.of(context).pop();
                      },
                      child: Text("New search"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Chip(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        label: Text(tag.label),
        backgroundColor: background,
        labelStyle: TextStyle(color: labelColor),
      ),
    );
  }
}

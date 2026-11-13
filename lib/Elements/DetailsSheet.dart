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

  Widget _iconButton(
    IconData icon,
    String longPressLabel,
    VoidCallback? onTap,
  ) {
    return SizedBox(
      height: 30,
      width: 30,
      child: InkWell(
        borderRadius: BorderRadius.all(Radius.circular(50.0)),
        onTap: onTap,
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(longPressLabel),
              );
            },
          );
        },
        child: Icon(icon),
      ),
    );
  }

  Widget _linkActionSheet(
    String title,
    String postLink,
    String? imageLink,
    void Function(String) action,
  ) {
    return SizedBox(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final postUrl = "https://derpibooru.org/${_derpi.id}";
    final directUrl = _derpi.representations.full;
    final imageUrl = directUrl == null || directUrl.isEmpty
        ? null
        : "https:$directUrl";
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(_derpi.id.toString()),
              OverflowBar(
                children: <Widget>[
                  _iconButton(Icons.share, "Share", () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return _linkActionSheet(
                          "Share",
                          postUrl,
                          imageUrl,
                          (link) =>
                              SharePlus.instance.share(ShareParams(text: link)),
                        );
                      },
                    );
                  }),
                  _iconButton(Icons.link, "Open in browser", () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return _linkActionSheet(
                          "Open in browser",
                          postUrl,
                          imageUrl,
                          (link) async {
                            final messenger = ScaffoldMessenger.maybeOf(
                              context,
                            );
                            final ok = await openInBrowser(link);
                            if (ok) return;
                            messenger?.showSnackBar(
                              SnackBar(
                                content: Text('Could not open the link'),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }),
                  _iconButton(Icons.content_copy, "Copy direct link", () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return _linkActionSheet(
                          "Copy direct link",
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
          constraints: BoxConstraints(maxHeight: 100.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Spacer(flex: 10),
                IcoText(
                  text: _derpi.commentCount.toString(),
                  icon: Icons.chat_bubble_outline,
                  color: Color.fromARGB(255, 176, 153, 221),
                ),
                Spacer(),
                IcoText(
                  text: _derpi.faves.toString(),
                  icon: Icons.star_border,
                  color: Colors.amber,
                ),
                Spacer(),
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
                Spacer(flex: 10),
              ],
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 100.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Text(_derpi.description ?? ''),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Wrap(
                spacing: 5,
                runSpacing: -5,
                alignment: WrapAlignment.center,
                children: [
                  for (final tag in _tags)
                    GestureDetector(
                      child: Chip(
                        padding: EdgeInsets.all(0),
                        label: Text(tag.label),
                        backgroundColor:
                            {
                              TagType.ARTIST: Colors.blue,
                              TagType.OC: Colors.green,
                              TagType.SPOILER: Colors.red,
                            }[tag.type] ??
                            Colors.grey,
                      ),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext c) {
                            return SizedBox(
                              height: 150.0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        _tagAction(tag.label, repo.addTag),
                                    child: Text("Add to search"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        _tagAction(tag.label, repo.removeTag),
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
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

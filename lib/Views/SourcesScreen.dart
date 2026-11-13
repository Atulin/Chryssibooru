import 'package:chryssibooru/BooruSource.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen for managing the Philomena-based booru sources the app can
/// search: adding, renaming, rekeying, and removing them (the built-in
/// Derpibooru source cannot be removed).
///
/// Pops with `true` when anything changed, so the caller can re-apply the
/// active source and refresh an ongoing search.
class SourcesScreen extends StatefulWidget {
  const SourcesScreen({super.key, required this.onSourcesChanged});

  final ValueChanged<bool> onSourcesChanged;

  @override
  SourcesScreenState createState() => SourcesScreenState();
}

class SourcesScreenState extends State<SourcesScreen> {
  List<BooruSource> _sources = [BooruSource.defaultSource()];
  String _activeSourceId = BooruSource.defaultSourceId;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final sources = await SourcesStore.load(prefs);
    final activeId = await SourcesStore.loadActiveId(prefs);
    if (!mounted) return;
    setState(() {
      _sources = sources;
      _activeSourceId = activeId;
      _loaded = true;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await SourcesStore.save(prefs, _sources);
    await SourcesStore.saveActiveId(prefs, _activeSourceId);
    widget.onSourcesChanged(true);
  }

  /// Normalizes a user-entered domain: lowercase, no scheme, no trailing
  /// slash, no whitespace.
  String _normalizeDomain(String raw) {
    var host = raw.trim().toLowerCase();
    host = host.replaceAll(RegExp(r'^https?://'), '');
    host = host.replaceAll(RegExp(r'/.*$'), '');
    host = host.trim();
    return host;
  }

  Future<void> _addSource() => _showEditDialog(null);

  Future<void> _editSource(BooruSource source) => _showEditDialog(source);

  Future<void> _showEditDialog(BooruSource? existing) async {
    final nameControl = TextEditingController(text: existing?.name ?? '');
    final hostControl = TextEditingController(text: existing?.host ?? '');
    final keyControl = TextEditingController(text: existing?.apiKey ?? '');
    var style = existing?.apiStyle ?? PhilomenaApiStyle.v1;

    final saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add source' : 'Edit source'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameControl,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g. Derpibooru',
                      ),
                    ),
                    TextField(
                      controller: hostControl,
                      decoration: const InputDecoration(
                        labelText: 'Domain',
                        hintText: 'e.g. derpibooru.org',
                      ),
                    ),
                    TextField(
                      controller: keyControl,
                      decoration: const InputDecoration(
                        labelText: 'API key (optional)',
                        hintText: 'Account settings on the booru',
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('API style'),
                      trailing: DropdownButton<PhilomenaApiStyle>(
                        value: style,
                        items: const [
                          DropdownMenuItem(
                            value: PhilomenaApiStyle.v1,
                            child: Text('Philomena V1'),
                          ),
                          DropdownMenuItem(
                            value: PhilomenaApiStyle.v3,
                            child: Text('Philomena V3'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => style = value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameControl.text.trim();
                    final host = _normalizeDomain(hostControl.text);
                    if (name.isEmpty || host.isEmpty) return;
                    Navigator.of(dialogContext).pop(true);
                    setState(() {
                      if (existing == null) {
                        _sources.add(
                          BooruSource(
                            id: 'source-${DateTime.now().microsecondsSinceEpoch}',
                            name: name,
                            host: host,
                            apiKey: keyControl.text.trim(),
                            apiStyle: style,
                          ),
                        );
                      } else {
                        existing
                          ..name = name
                          ..host = host
                          ..apiKey = keyControl.text.trim()
                          ..apiStyle = style;
                      }
                    });
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      await _persist();
    }
  }

  Future<void> _removeSource(BooruSource source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Remove ${source.name}?'),
          content: Text(
            'The source will be removed from this device. '
            'The built-in Derpibooru source cannot be removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('Remove'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    setState(() {
      _sources.removeWhere((s) => s.id == source.id);
      if (_activeSourceId == source.id) {
        _activeSourceId = BooruSource.defaultSourceId;
      }
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sources')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: [
                for (final source in _sources) _buildSourceTile(source),
                const SizedBox(height: 72.0),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSource,
        icon: const Icon(Icons.add),
        label: const Text('Add source'),
      ),
    );
  }

  Widget _buildSourceTile(BooruSource source) {
    final isActive = source.id == _activeSourceId;
    final isBuiltIn = source.id == BooruSource.defaultSourceId;
    return ListTile(
      leading: Icon(
        isActive ? Icons.check_circle : Icons.dns,
        color: isActive ? Colors.teal : null,
      ),
      title: Text(
        source.name,
        style: TextStyle(fontWeight: isActive ? FontWeight.bold : null),
      ),
      subtitle: Text(
        '${source.host} · ${source.apiKey.isEmpty ? 'no API key' : 'API key set'}'
        '${isBuiltIn ? ' · built-in' : ''}',
        style: const TextStyle(fontSize: 12.0),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => _editSource(source),
          ),
          if (!isBuiltIn)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Remove',
              onPressed: () => _removeSource(source),
            ),
        ],
      ),
      onTap: () => _editSource(source),
    );
  }
}

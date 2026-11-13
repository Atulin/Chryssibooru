import 'package:chryssibooru/API/v2/ImageList.dart';
import 'package:chryssibooru/BooruSource.dart';
import 'package:chryssibooru/Enums/ESortMethod.dart';
import 'package:flutter_test/flutter_test.dart';

BooruSource source([String key = '']) =>
    BooruSource(id: 'test', name: 'Test', host: 'derpibooru.org', apiKey: key);

Uri queryUri(
  String query, {
  bool s = true,
  bool q = false,
  bool e = false,
  String key = '',
  int page = 1,
  ESortMethod sortMethod = ESortMethod.ID_DESC,
}) => Uri.parse(
  buildQuery(
    source(key),
    query,
    s: s,
    q: q,
    e: e,
    page: page,
    sortMethod: sortMethod,
  ),
);

void main() {
  test('buildQuery produces a valid HTTPS search URL', () {
    final uri = queryUri('chrysalis');

    expect(uri.scheme, 'https');
    expect(uri.host, 'derpibooru.org');
    expect(uri.path, '/api/v1/json/search/images');
    expect(uri.queryParameters['q'], 'chrysalis, safe');
    expect(uri.queryParameters['page'], '1');
    expect(uri.queryParameters['per_page'], '30');
    expect(uri.queryParameters.containsKey('key'), isFalse);
  });

  test('no rating clause is added when all ratings are selected', () {
    expect(
      queryUri('chrysalis', s: true, q: true, e: true).queryParameters['q'],
      'chrysalis',
    );
  });

  test('no rating clause is added when no rating is selected', () {
    expect(
      queryUri('chrysalis', s: false, q: false, e: false).queryParameters['q'],
      'chrysalis',
    );
  });

  test('rating clauses use the shortest equivalent form', () {
    String? q(bool s, bool que, bool e) =>
        queryUri('', s: s, q: que, e: e).queryParameters['q'];

    // A single selected rating is requested directly.
    expect(q(true, false, false), ', safe');
    expect(q(false, true, false), ', questionable');
    expect(q(false, false, true), ', explicit');

    // Two selected ratings exclude the missing one.
    expect(q(false, true, true), ', -safe');
    expect(q(true, false, true), ', -questionable');
    expect(q(true, true, false), ', -explicit');
  });

  test('API key replaces per_page; the rating clause still applies', () {
    final params = queryUri(
      'chrysalis',
      key: 'sekret',
      page: 2,
    ).queryParameters;
    expect(params['key'], 'sekret');
    expect(params.containsKey('per_page'), isFalse);
    expect(params['page'], '2');
    expect(params['q'], 'chrysalis, safe');
  });

  test('sorting fields are mapped to sf/sd', () {
    final urlAsc = queryUri('', sortMethod: ESortMethod.SCORE_ASC);
    expect(urlAsc.queryParameters['sf'], 'score');
    expect(urlAsc.queryParameters['sd'], 'asc');
    final url = queryUri('', sortMethod: ESortMethod.UPVOTES_DESC);
    final params = url.queryParameters;
    expect(params['sf'], 'upvotes');
    expect(params['sd'], 'desc');
  });

  test('random sort uses a random seed as sf', () {
    final params = queryUri('', sortMethod: ESortMethod.RANDOM).queryParameters;
    expect(params['sf'], matches(RegExp(r'^random:\d+$')));
    expect(params['sd'], 'desc');
  });

  test('query characters are properly encoded', () {
    final q = queryUri('safe, artist:foo bar').queryParameters['q']!;
    expect(q, 'safe, artist:foo bar, safe');
  });

  test('the search path follows the source API style', () {
    final v3 = BooruSource(
      id: 'twi',
      name: 'Twibooru',
      host: 'twibooru.org',
      apiStyle: PhilomenaApiStyle.v3,
    );
    final uri = Uri.parse(
      buildQuery(v3, 'safe', page: 1, sortMethod: ESortMethod.ID_DESC),
    );
    expect(uri.host, 'twibooru.org');
    expect(uri.path, '/api/v3/search/posts');
  });
}

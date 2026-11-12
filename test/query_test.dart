import 'package:chryssibooru/API/v2/ImageList.dart';
import 'package:chryssibooru/Enums/ESortMethod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildQuery produces a valid HTTPS search URL', () {
    final url = buildQuery('chrysalis', true, false, false, '', page: 1);
    final uri = Uri.parse(url);

    expect(uri.scheme, 'https');
    expect(uri.host, 'derpibooru.org');
    expect(uri.path, '/api/v1/json/search/images');
    expect(uri.queryParameters['q'], 'chrysalis, (safe)');
    expect(uri.queryParameters['page'], '1');
    expect(uri.queryParameters['per_page'], '30');
    expect(uri.queryParameters.containsKey('key'), isFalse);
  });

  test('no rating clause is added when all ratings are selected', () {
    final url = buildQuery('chrysalis', true, true, true, '', page: 1);
    expect(Uri.parse(url).queryParameters['q'], 'chrysalis');
  });

  test('no rating clause is added when no rating is selected', () {
    final url = buildQuery('chrysalis', false, false, false, '', page: 1);
    expect(Uri.parse(url).queryParameters['q'], 'chrysalis');
  });

  test('rating clause joins selected ratings with OR', () {
    final url = buildQuery('', false, true, true, '', page: 1);
    expect(Uri.parse(url).queryParameters['q'], ', (questionable OR explicit)');
  });

  test('API key replaces per_page', () {
    final url = buildQuery('chrysalis', true, false, false, 'sekret', page: 2);
    final params = Uri.parse(url).queryParameters;
    expect(params['key'], 'sekret');
    expect(params.containsKey('per_page'), isFalse);
    expect(params['page'], '2');
  });

  test('sorting fields are mapped to sf/sd', () {
    final urlAsc = buildQuery(
      '',
      true,
      false,
      false,
      '',
      sortMethod: ESortMethod.SCORE_ASC,
    );
    expect(Uri.parse(urlAsc).queryParameters['sf'], 'score');
    expect(Uri.parse(urlAsc).queryParameters['sd'], 'asc');
    final url = buildQuery(
      '',
      true,
      false,
      false,
      '',
      sortMethod: ESortMethod.UPVOTES_DESC,
    );
    final params = Uri.parse(url).queryParameters;
    expect(params['sf'], 'upvotes');
    expect(params['sd'], 'desc');
  });

  test('random sort uses a random seed as sf', () {
    final url = buildQuery(
      '',
      true,
      false,
      false,
      '',
      sortMethod: ESortMethod.RANDOM,
    );
    final params = Uri.parse(url).queryParameters;
    expect(params['sf'], matches(RegExp(r'^random:\d+$')));
    expect(params['sd'], 'desc');
  });

  test('query characters are properly encoded', () {
    final url = buildQuery('safe, artist:foo bar', true, false, false, '');
    final q = Uri.parse(url).queryParameters['q']!;
    expect(q, 'safe, artist:foo bar, (safe)');
  });
}

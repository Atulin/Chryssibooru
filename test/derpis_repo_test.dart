import 'package:chryssibooru/Connect.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:chryssibooru/Enums/EQuality.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_client.dart';

/// Registers [fake] as the HTTP client used by the app for the duration of
/// [body], restoring the real client afterwards.
Future<void> withFakeClient(
  FakeClient fake,
  Future<void> Function() body,
) async {
  final original = apiHttpClient;
  apiHttpClient = fake;
  try {
    await body();
  } finally {
    apiHttpClient = original;
  }
}

void main() {
  test(
    'loadNextPage fetches and stores results, then advances the page',
    () async {
      final fake = FakeClient();
      fake.enqueue(searchResponseBody([fixtureImage(id: 1)]));
      final repo = DerpisRepo();
      repo.query = 'chrysalis';

      await withFakeClient(fake, () async {
        final result = await repo.loadNextPage();
        expect(result, LoadResult.added);
        expect(repo.derpis.map((d) => d.id), [1]);
        expect(repo.page, 2);
        expect(repo.loaded, isTrue);
      });

      expect(fake.requestedUrls.single.queryParameters['page'], '1');
      expect(
        fake.requestedUrls.single.queryParameters['q'],
        'chrysalis, (safe)',
      );
    },
  );

  test('duplicate results are suppressed by image id', () async {
    final fake = FakeClient();
    fake.enqueue(
      searchResponseBody([fixtureImage(id: 1), fixtureImage(id: 2)]),
    );
    fake.enqueue(
      searchResponseBody([fixtureImage(id: 2), fixtureImage(id: 3)]),
    );
    final repo = DerpisRepo();

    await withFakeClient(fake, () async {
      await repo.loadNextPage();
      await repo.loadNextPage();
    });

    expect(repo.derpis.map((d) => d.id).toList(), [1, 2, 3]);
  });

  test(
    'concurrent pagination requests are ignored while one is running',
    () async {
      final fake = FakeClient();
      fake.enqueue(searchResponseBody([fixtureImage(id: 1)]), manual: true);
      final repo = DerpisRepo();

      await withFakeClient(fake, () async {
        final first = repo.loadNextPage();
        final second = await repo.loadNextPage();
        expect(second, LoadResult.busy, reason: 'fetch already in flight');

        fake.completeNext();
        expect(await first, LoadResult.added);
        expect(repo.derpis.map((d) => d.id), [1]);
        // Only one request was actually made.
        expect(fake.requestedUrls, hasLength(1));
      });
    },
  );

  test('stale responses are discarded after a new search', () async {
    final fake = FakeClient();
    // First search request.
    fake.enqueue(searchResponseBody([fixtureImage(id: 100)]), manual: true);
    // Second (fresh) search request.
    fake.enqueue(searchResponseBody([fixtureImage(id: 200)]), manual: true);
    final repo = DerpisRepo();
    repo.query = 'old query';

    await withFakeClient(fake, () async {
      final stale = repo.loadNextPage();
      // The user issues a new search while the old request is still
      // in flight.
      repo.query = 'new query';
      final fresh = repo.newSearch();

      fake.completeNext(); // Releases the stale request's response.
      await stale;
      expect(repo.derpis, isEmpty, reason: 'stale results must be discarded');

      fake.completeNext(); // Releases the fresh request's response.
      final added = await fresh;
      expect(added, isTrue);
      expect(repo.derpis.map((d) => d.id), [200]);
      expect(repo.page, 2);
    });

    expect(fake.requestedUrls[0].queryParameters['q'], 'old query, (safe)');
    expect(fake.requestedUrls[1].queryParameters['q'], 'new query, (safe)');
  });

  test(
    'failed or empty pages set endOfResults and stop further fetches',
    () async {
      final fake = FakeClient();
      fake.enqueue(searchResponseBody([fixtureImage(id: 1)]));
      // Page 2 returns no images.
      fake.enqueue('{"total": 1, "images": [], "interactions": []}');
      final repo = DerpisRepo();

      await withFakeClient(fake, () async {
        expect(await repo.loadNextPage(), LoadResult.added);
        expect(await repo.loadNextPage(), LoadResult.ended);
        expect(repo.endOfResults, isTrue);

        // Further calls do not hit the network again.
        final requests = fake.requestedUrls.length;
        expect(await repo.loadNextPage(), LoadResult.ended);
        expect(fake.requestedUrls.length, requests);
      });
    },
  );

  test(
    'a failed search clears the old results and reports nothing loaded',
    () async {
      final fake = FakeClient();
      fake.enqueue(searchResponseBody([fixtureImage(id: 1)]));
      // New search fails with a 500.
      fake.enqueue('{"error": "boom"}', status: 500);
      final repo = DerpisRepo();

      await withFakeClient(fake, () async {
        await repo.loadNextPage();
        expect(repo.derpis, isNotEmpty);

        final added = await repo.newSearch();
        expect(added, isFalse);
        expect(repo.derpis, isEmpty);
      });
    },
  );

  test('notifyListeners fires when results arrive', () async {
    final fake = FakeClient();
    fake.enqueue(searchResponseBody([fixtureImage(id: 1)]));
    final repo = DerpisRepo();
    var notifications = 0;
    repo.addListener(() => notifications++);

    await withFakeClient(fake, () async {
      await repo.loadNextPage();
    });

    expect(notifications, greaterThanOrEqualTo(1));
  });

  test('getImageOfQuality maps quality to representations', () async {
    final fake = FakeClient();
    fake.enqueue(searchResponseBody([fixtureImage(id: 1)]));
    final repo = DerpisRepo();

    await withFakeClient(fake, () async {
      await repo.loadNextPage();
    });

    expect(repo.getImageOfQuality(Quality.Low, 0), endsWith('small.png'));
    expect(repo.getImageOfQuality(Quality.Medium, 0), endsWith('medium.png'));
    expect(repo.getImageOfQuality(Quality.High, 0), endsWith('large.png'));
    expect(repo.getImageOfQuality(Quality.Source, 0), endsWith('full.png'));
  });

  test('loading state is surfaced while a page is in flight', () async {
    final fake = FakeClient();
    fake.enqueue(searchResponseBody([fixtureImage(id: 1)]), manual: true);
    final repo = DerpisRepo();
    var sawLoading = false;
    repo.addListener(() {
      if (!repo.loaded) sawLoading = true;
    });

    await withFakeClient(fake, () async {
      final fetch = repo.loadNextPage();
      expect(repo.loaded, isFalse);
      fake.completeNext();
      expect(await fetch, LoadResult.added);
      expect(repo.loaded, isTrue);
    });

    expect(sawLoading, isTrue);
  });

  test('addTag and removeTag manipulate the query string', () {
    final repo = DerpisRepo()..query = 'chrysalis';
    repo.addTag('solo');
    expect(repo.query, 'chrysalis, solo');
    repo.removeTag('solo');
    expect(repo.query, 'chrysalis, -solo');
  });
}

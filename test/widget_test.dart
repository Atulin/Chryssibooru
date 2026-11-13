import 'dart:io';

import 'package:chryssibooru/Connect.dart';
import 'package:chryssibooru/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_client.dart';

/// Returns deterministic paths so the image cache manager works in tests.
class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => '/tmp/opencode/testcache';

  @override
  Future<String?> getApplicationSupportPath() async =>
      '/tmp/opencode/testcache';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeClient fake;
  late http.Client originalClient;

  setUpAll(() {
    // A real directory for the image cache so flutter_cache_manager can
    // write during tests without hitting platform plugins.
    final cacheDir = Directory('/tmp/opencode/testcache');
    if (!cacheDir.existsSync()) cacheDir.createSync(recursive: true);
  });

  setUp(() async {
    fake = FakeClient();
    originalClient = apiHttpClient;
    apiHttpClient = fake;

    SharedPreferences.setMockInitialValues({});

    PathProviderPlatform.instance = FakePathProviderPlatform();

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (call) async {
        if (call.method == 'getAll') {
          return <String, String>{
            'appName': 'chryssibooru',
            'packageName': 'com.angius.chryssibooru',
            'version': '1.6.3',
            'buildNumber': '1',
          };
        }
        return null;
      },
    );
  });

  tearDown(() {
    apiHttpClient = originalClient;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/package_info'),
          null,
        );
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('empty state shows the logo, search bar, and drawer', (
    tester,
  ) async {
    final original = apiHttpClient;
    apiHttpClient = FakeClient(); // No requests expected.
    try {
      await pumpApp(tester);

      expect(find.byType(TextField), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('Enter API key'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Favourites'), findsOneWidget);
      expect(find.text('Buy me a coffee'), findsOneWidget);
      expect(find.text('Cache size: 0.00 B'), findsOneWidget);
    } finally {
      apiHttpClient = original;
    }
  });

  testWidgets('submitting a search fetches results and shows the grid', (
    tester,
  ) async {
    fake.enqueue(
      searchResponseBody([fixtureImage(id: 1), fixtureImage(id: 2)]),
    );

    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'chrysalis');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(fake.requestedUrls, hasLength(1));
    final url = fake.requestedUrls.single;
    expect(url.host, 'derpibooru.org');
    expect(url.queryParameters['q'], 'chrysalis, (safe)');

    // The grid now shows two entries.
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(ClipRRect), findsNWidgets(2));
  });

  testWidgets('history entries update the query and trigger a new search', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'history': ['pony', 'chrysalis'],
    });

    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('pony'),
      ),
      findsOneWidget,
    );

    // Selecting the history entry updates the search field and issues a
    // fresh search.
    fake.enqueue(searchResponseBody([fixtureImage(id: 1)]));
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('pony'),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(fake.requestedUrls, hasLength(1));
    expect(fake.requestedUrls.single.queryParameters['q'], 'pony, (safe)');
  });

  testWidgets('drawer shows the saved API key state', (tester) async {
    SharedPreferences.setMockInitialValues({'key': 'sekret'});
    final original = apiHttpClient;
    apiHttpClient = FakeClient();
    try {
      await pumpApp(tester);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('All set!'), findsOneWidget);
    } finally {
      apiHttpClient = original;
    }
  });

  testWidgets('scrolling to the end of the grid loads the next page', (
    tester,
  ) async {
    // Page 1: a full page of images, enough to make the grid scrollable.
    fake.enqueue(
      searchResponseBody(
        List.generate(30, (i) => fixtureImage(id: i + 1), growable: false),
      ),
    );
    // Page 2.
    fake.enqueue(searchResponseBody([fixtureImage(id: 100)]));

    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'chrysalis');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(seconds: 1));

    expect(fake.requestedUrls, hasLength(1));
    expect(fake.requestedUrls.single.queryParameters['page'], '1');

    // Scroll to the very end of the grid.
    await tester.fling(find.byType(GridView), const Offset(0, -5000), 20000);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));

    // Page 2 must have been requested by scrolling alone (the harness
    // may fire additional attempts once the queue runs dry; the repo
    // treats those as retryable network errors).
    expect(
      fake.requestedUrls.any((u) => u.queryParameters['page'] == '2'),
      isTrue,
    );

    // The grid now knows about the images from the second page too.
    final gridView = tester.widget<GridView>(find.byType(GridView));
    final delegate = gridView.childrenDelegate as SliverChildBuilderDelegate;
    expect(delegate.childCount, 31);
  });

  testWidgets('the search bar stays above the keyboard when typing', (
    tester,
  ) async {
    final original = apiHttpClient;
    apiHttpClient = FakeClient();
    try {
      await pumpApp(tester);

      // Simulate the keyboard being open (bottom inset of 300px).
      tester.view.viewInsets = FakeViewPadding(bottom: 300);
      await tester.pump();

      // The BottomAppBar must be lifted so its bottom edge sits exactly
      // on top of the keyboard. The fake inset is in physical pixels
      // (default test DPR is 3.0 → 100 logical pixels).
      final barRect = tester.getRect(find.byType(BottomAppBar));
      final keyboardTop = 600 - 300 / 3.0;
      expect(barRect.bottom, closeTo(keyboardTop, 1));
    } finally {
      apiHttpClient = original;
      tester.view.viewInsets = FakeViewPadding.zero;
    }
  });

  testWidgets('a loading indicator shows while the search is in flight', (
    tester,
  ) async {
    fake.enqueue(searchResponseBody([fixtureImage(id: 1)]), manual: true);

    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'chrysalis');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // While the fetch is in flight and nothing has loaded yet, the logo
    // is accompanied by a progress indicator.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(GridView), findsNothing);

    fake.completeNext();
    await tester.pump(const Duration(seconds: 1));

    // Once results arrive the indicator disappears and the grid shows.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('changing rating filters refreshes the search when the sheet '
      'closes', (tester) async {
    fake.enqueue(searchResponseBody([fixtureImage(id: 1)]));
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'chrysalis');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(seconds: 1));
    expect(fake.requestedUrls, hasLength(1));

    // The safe rating starts enabled; turning it off and closing the
    // sheet triggers a fresh search.
    fake.enqueue(searchResponseBody([fixtureImage(id: 2)]));
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Safe'));
    await tester.pump();
    await tester.tapAt(const Offset(10, 10)); // Close the sheet.
    await tester.pump(const Duration(seconds: 1));

    expect(fake.requestedUrls, hasLength(2));
    final second = fake.requestedUrls.last;
    expect(second.queryParameters['q'], 'chrysalis');
    expect(second.queryParameters.containsKey('per_page'), isTrue);
    // Disabling the only rating leaves the query unfiltered but with no
    // rating clause, matching the original behaviour.
    expect(second.queryParameters['q'], isNot(contains('safe')));
  });
}

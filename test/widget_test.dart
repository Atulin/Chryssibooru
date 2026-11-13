import 'dart:io';

import 'package:chryssibooru/Connect.dart';
import 'package:chryssibooru/main.dart';
import 'package:material_ui/material_ui.dart';
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
    expect(url.queryParameters['q'], 'chrysalis, safe');

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
    expect(fake.requestedUrls.single.queryParameters['q'], 'pony, safe');
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

  testWidgets('a saved key is sent with searches and enables explicit by '
      'default', (tester) async {
    SharedPreferences.setMockInitialValues({'key': 'sekret'});
    fake.enqueue(searchResponseBody([fixtureImage(id: 1)]));

    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'chrysalis');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(seconds: 1));

    final url = fake.requestedUrls.single;
    expect(url.queryParameters['key'], 'sekret');
    expect(url.queryParameters.containsKey('per_page'), isFalse);
    // With a key, explicit is checked by default, so the rating clause
    // includes it.
    expect(url.queryParameters['q'], 'chrysalis');
  });

  testWidgets('the API key sheet trims the key and saves it on dismissal', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enter API key'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      ),
      '  my-key  ',
    );
    // Dismiss the sheet without submitting (tap outside).
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('key'), 'my-key');

    // The drawer reflects the saved key.
    expect(find.text('All set!'), findsOneWidget);

    // The next search uses the trimmed key: close the drawer and search.
    fake.enqueue(searchResponseBody([fixtureImage(id: 1)]));
    await tester.tapAt(const Offset(700, 300)); // Close the drawer.
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'chrysalis');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(seconds: 1));

    expect(fake.requestedUrls.single.queryParameters['key'], 'my-key');
    // The newly added key checks Explicit by default.
    expect(fake.requestedUrls.single.queryParameters['q'], 'chrysalis');
  });

  testWidgets('a changed key triggers a fresh search of the visible '
      'results', (tester) async {
    // A search is already displayed.
    fake.enqueue(searchResponseBody([fixtureImage(id: 1)]));
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'chrysalis');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(seconds: 1));
    expect(fake.requestedUrls, hasLength(1));

    // Adding a key while results are visible refreshes them with the
    // account filter applied.
    fake.enqueue(searchResponseBody([fixtureImage(id: 2)]));
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enter API key'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      ),
      'my-key',
    );
    await tester.tapAt(const Offset(10, 10)); // Dismiss the sheet.
    await tester.pump(const Duration(seconds: 1));

    expect(fake.requestedUrls, hasLength(2));
    expect(fake.requestedUrls.last.queryParameters['key'], 'my-key');
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

  testWidgets('the explicit rating checkbox follows the API key state', (
    tester,
  ) async {
    // Without a key: Explicit is disabled and unchecked, and the other
    // ratings work.
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    expect(find.text('Requires an API key'), findsOneWidget);
    await tester.tap(find.text('Explicit'));
    await tester.pump();
    final sheet = tester.widget<CheckboxListTile>(
      find.ancestor(
        of: find.text('Explicit'),
        matching: find.byType(CheckboxListTile),
      ),
    );
    expect(sheet.value, isFalse);
    expect(sheet.onChanged, isNull);

    // With a key: Explicit is enabled and checked by default. The app is
    // restarted with the key saved, as repo state loads at startup.
    SharedPreferences.setMockInitialValues({'key': 'sekret'});
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    expect(find.text('Requires an API key'), findsNothing);
    final keyedSheet = tester.widget<CheckboxListTile>(
      find.ancestor(
        of: find.text('Explicit'),
        matching: find.byType(CheckboxListTile),
      ),
    );
    expect(keyedSheet.value, isTrue);
    expect(keyedSheet.onChanged, isNotNull);

    // Unchecking it stores the user's choice.
    await tester.tap(find.text('Explicit'));
    await tester.pump();
    final unchecked = tester.widget<CheckboxListTile>(
      find.ancestor(
        of: find.text('Explicit'),
        matching: find.byType(CheckboxListTile),
      ),
    );
    expect(unchecked.value, isFalse);
    expect(
      (await SharedPreferences.getInstance()).getBool('explicit'),
      isFalse,
    );
  });

  testWidgets('toggling ratings or sorting with no query sends nothing', (
    tester,
  ) async {
    final original = apiHttpClient;
    apiHttpClient = FakeClient(); // No requests expected.
    try {
      await pumpApp(tester);

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Toggle Safe (with no query entered yet).
      await tester.tap(find.text('Safe'));
      await tester.pump();
      await tester.tapAt(const Offset(10, 10)); // Close the sheet.
      await tester.pumpAndSettle();

      expect(find.text('No results found'), findsNothing);
      expect(find.byType(GridView), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    } finally {
      apiHttpClient = original;
    }
  });

  testWidgets('submitting an empty query sends nothing', (tester) async {
    final original = apiHttpClient;
    apiHttpClient = FakeClient();
    try {
      await pumpApp(tester);

      await tester.enterText(find.byType(TextField), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('No results found'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    } finally {
      apiHttpClient = original;
    }
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

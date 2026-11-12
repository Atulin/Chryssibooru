# AGENTS.md

## Mission

Modernize Chryssibooru from its legacy Flutter/Dart implementation into a
maintainable application built with a current, supported Flutter and Dart
toolchain.

Target repository:
https://github.com/Atulin/Chryssibooru

Reference implementation:
https://github.com/Atulin/Kemoshow-XP

These applications solve related problems: searching remote media, browsing
images and videos, displaying metadata, and persisting user preferences and
favourites. Use Kemoshow-XP as a reference for modern implementation patterns,
dependency choices, media lifecycle management, testing, and platform setup.

This is a modernization of Chryssibooru, not a conversion into Kemoshow.

## Non-negotiable: preserve Chryssibooru's visual identity

The general visual design and look of Chryssibooru must remain recognizably
the same.

Preserve its branding, assets, colour identity, screen composition, navigation
model, image grid, full-screen viewer, drawer, search/filter controls, and
metadata presentation. Establish their actual appearance from the repository's
screenshots, assets, theme definitions, and existing widgets before changing
them.

Modernize the implementation underneath that design. Improve spacing,
readability, accessibility, safe-area handling, responsiveness, and interaction
polish where necessary, without imposing a different aesthetic.

In particular:

- Do not copy Kemoshow-XP's screens, colours, branding, or navigation.
- Do not replace the grid-first experience with a slideshow-first application.
- Do not replace the existing navigation with a new navigation bar or dashboard
  simply because it is fashionable.
- Do not accept Flutter's default theme changes as an intentional redesign.
  Explicitly configure components where defaults would materially alter the
  original appearance.
- Do not introduce large cards, excessive rounding, oversized typography,
  decorative gradients, or additional animation without an existing design
  precedent or a concrete usability need.
- Keep existing logos, illustrations, and distinctive header treatments.
- Accessibility improvements must preserve the design's intent, not preserve
  inaccessible defects.

When several implementations are equally suitable, prefer the one that most
closely preserves the original appearance and behaviour.

If a significant visual departure appears necessary, document the reason and
ask for approval before implementing it.

## Working rules

- Inspect the project before proposing or implementing a migration.
- Implement the modernization; do not stop at an audit or a plan.
- Work incrementally in coherent, verifiable steps.
- Do not commit, push, tag, publish releases, or modify remote repositories.
  Leave committing and publishing to the user.
- Do not overwrite unrelated user changes.
- Preserve licensing and attribution. Check licensing before reusing code
  from the reference project.
- Do not invent API behaviour, package APIs, SDK versions, or test results.
- Distinguish verified behaviour from assumptions and untested work.
- Ask questions only for genuine product decisions, destructive changes, or
  blockers that cannot reasonably be resolved by inspecting the projects.

## 1. Establish the baseline

Before editing:

1. Read this repository's README, pubspec, platform configuration, tests,
   screenshots, documentation, and existing agent instructions.
2. Inspect the application's entry point, state management, API client,
   models, storage, gallery, full-screen viewer, and media controls.
3. Inspect the corresponding implementations in Kemoshow-XP, including its
   pubspec, development commands, tests, platform configuration, and relevant
   services/controllers.
4. Record the existing feature set and identify which behaviours are
   implemented, broken, or merely mentioned in documentation.
5. Attempt to run the old application when practical. If its old toolchain
   prevents this, use screenshots and source inspection as the baseline;
   do not claim to have observed a running application.
6. Capture baseline screenshots when possible. Keep comparison captures
   free of API keys, personal data, and sensitive media.
7. Prepare a short migration plan and continue with implementation.

Treat source code as the primary evidence for existing behaviour. Resolve
contradictions between old documentation and implementation explicitly.

In particular, distinguish local favourites or saved searches from remote
account favourites. Do not interpret an old statement about unsupported
authenticated favourites as permission to remove existing local features.

## 2. Toolchain and dependency migration

Use a current, supported stable Flutter release and its bundled Dart SDK.
Verify actual availability and compatibility rather than blindly copying
version numbers from Kemoshow-XP's documentation.

Record the selected versions and make local development and CI consistent.

- Migrate all application code to sound null safety and modern Dart.
- Replace removed Flutter APIs and obsolete plugin integrations.
- Upgrade dependencies to compatible, maintained releases.
- Replace abandoned packages and obsolete Git-based dependency workarounds.
- Remove unused dependencies and dead migration scaffolding.
- Add suitable linting and resolve analyzer findings.
- Commit application dependency lockfiles as part of the resulting changes,
  but leave the actual Git commit to the user.
- Do not use broad analyzer exclusions, blanket ignores, pervasive `dynamic`,
  or indiscriminate null assertions to disguise migration problems.
- Do not run a project-regeneration command over the repository without first
  protecting custom platform configuration and reviewing the resulting diff.

Evaluate Kemoshow-XP's choices where relevant:

- `media_kit` and its supporting packages for image-adjacent video playback.
- `dart_mappable` and `build_runner` for typed JSON models.
- Maintained HTTP, preferences, URL-launching, file-saving, and gallery plugins.
- Small injectable storage and service interfaces.
- Controllers/view models that can be tested without rendering the whole app.

These are reference choices, not a requirement to adopt every dependency.
Choose the smallest coherent stack that satisfies Chryssibooru's needs.
Do not change state-management libraries merely to imitate another project.

If using generated code, document regeneration commands and follow a
consistent policy for generated files. Never hand-edit generated output.

## 3. Preserve features and behaviour

Inventory and preserve every existing working feature, including applicable
parts of the following:

- Search syntax and tag-based queries.
- Rating/content filters and API-key configuration.
- Sorting and image-quality selection.
- Paginated or infinite image-grid browsing.
- Full-screen image navigation and zoom.
- Animated images and video playback.
- Image details, descriptions, tags, sources, and available statistics.
- Tag actions: add to a query, remove from a query, and search a tag alone.
- Search history and local favourites, including removal.
- Saved preferences and cache-management controls.
- Download/save, share, copy, and open-in-browser actions.
- About information and branding.
- Existing drawer/header behaviour.

Preserve query updates and refresh behaviour when opening history/favourites
or changing filters and sorting. Preserve navigation position where practical
rather than resetting the gallery unnecessarily.

Do not silently remove a feature because its old package no longer works.
Replace the implementation or report a concrete blocker.

Do not add remote account login, likes, comments, or account-synchronized
favourites unless explicitly requested. Any such expansion requires verified
API support and separate scope approval.

## 4. Architecture and API integration

Separate responsibilities enough to make the application understandable and
testable:

- API transport and response parsing.
- Typed remote-data models.
- Repository/pagination behaviour.
- Preferences, history, and favourites storage.
- Download/share/platform services.
- Screen state and presentation.

Kemoshow-XP's separation of data, domain, services, and feature UI is useful
guidance, but do not introduce layers that only forward calls or add complexity
without benefit.

Retain Derpibooru-specific semantics. Do not copy Kemoshow-XP's server list,
creator search, endpoint assumptions, attachment flattening, or offset
pagination into this application.

Verify current Derpibooru API behaviour against authoritative documentation and
representative responses before changing endpoints, filters, authentication,
pagination, or media URL selection.

Requirements:

- Parse missing, nullable, and malformed fields safely.
- Preserve search syntax when encoding query parameters.
- Prevent duplicate concurrent pagination requests and duplicate results.
- Handle exhausted result sets, empty responses, network errors, and retries.
- Ignore or cancel stale responses after a new search/filter/sort selection.
- Preserve content-filter behaviour, including when no API key is present.
- Never silently broaden content visibility during migration.
- Use HTTPS and redact credentials from logs, exceptions, and diagnostics.
- Treat remote descriptions and links as untrusted content.

Use deterministic fixtures for automated tests. Tests must not require a
personal API key or unrestricted access to live media.

## 5. Media handling and performance

Modernize media handling without regressing the gallery experience.

- Use thumbnails appropriately in the grid.
- Avoid decoding full-resolution images unnecessarily.
- Keep caching and preloading bounded.
- Provide useful loading, empty, and failure states.
- Ensure zoom/pan gestures do not accidentally navigate between images.
- Preserve supported image and animation formats.
- Verify video format support on each tested platform.
- Ensure only the intended video plays.
- Pause or stop playback when navigating away or backgrounding the app.
- Dispose players, controllers, subscriptions, and other resources correctly.
- Preserve existing playback preferences and control semantics where present.
- Prevent transient loading states from flashing as false playback errors.
- Handle failed downloads and permission denials visibly and recoverably.

Use Kemoshow-XP's media lifecycle and gesture handling as implementation
references, not as a mandate to copy its player UI.

## 6. Persistence and upgrade compatibility

An update should not unnecessarily erase existing user state.

Inspect existing preference keys, serialization formats, defaults, and stored
values before replacing persistence code.

Preserve or explicitly migrate:

- API configuration.
- Content/rating filters.
- Sort and image-quality preferences.
- Search history.
- Local favourites.
- Other existing user settings.

Migrations must tolerate malformed or partially populated data and be safe to
run repeatedly. Do not clear all preferences as a shortcut.

Keep API credentials out of source control, test fixtures, screenshots, and
logs. Evaluate appropriate credential storage separately from ordinary
preferences. If moving credentials, migrate existing values safely.

Preserve application identifiers and platform identity so existing
installations can be upgraded where signing continuity permits. Do not
regenerate or replace signing keys.

## 7. Platform modernization

Prioritize restoring Android functionality while preserving existing iOS and
Windows project support where feasible.

- Update Android Gradle, Kotlin/Java, plugin, manifest, and SDK configuration
  as required by the selected toolchain.
- Review file-saving and media permissions; avoid unnecessary broad storage
  access.
- Preserve package identifiers, app names, icons, deep links, and intentional
  platform customizations.
- Update iOS deployment settings and plugin integration as necessary.
- Update Windows runner/plugin integration where required.
- Do not delete a platform because the current environment cannot build it.
- Do not add new platforms unless requested or clearly justified.
- Never commit signing credentials, keystores, or local machine paths.
- Do not claim release-signing compatibility without verifying the existing
  configuration.

Use platform-appropriate interactions and keyboard support where helpful,
without redesigning the mobile application around desktop conventions.

## 8. Testing and visual verification

Add meaningful regression coverage, not only a default counter-widget test.

Cover:

- API response parsing and nullable fields.
- Search encoding, filtering, sorting, and pagination.
- Stale-response handling and pagination deduplication.
- History/favourites persistence and legacy-data migration.
- Loading, empty, error, and retry states.
- Important search, grid, viewer, and details interactions.
- Media-controller lifecycle through testable boundaries where practical.

Add screenshot or golden coverage for representative screens where feasible.
Compare the modernized UI against the original screenshots or runtime captures.

Manually verify, where the environment permits:

- Search → grid → viewer → details → back.
- Opening history and favourites.
- Filter, sorting, and quality changes.
- Image zoom versus page-swipe behaviour.
- Video navigation, pause/resume, and backgrounding.
- Downloads, sharing, copying, and external links.
- Relaunch persistence.
- Small screens, safe areas, text scaling, and keyboard focus.
- Visual continuity with the original application.

Run the applicable commands:

    flutter --version
    flutter doctor -v
    flutter pub get
    dart format --output=none --set-exit-if-changed .
    flutter analyze
    flutter test
    flutter build apk --debug

Run code generation before validation if adopted. Build other supported
platforms when the host environment permits.

Fix failures caused by the changes. Report unavailable SDKs, devices, host
platforms, credentials, and network access as limitations—not successful tests.

## 9. Documentation and completion criteria

Update the README and relevant development documentation with:

- Required Flutter/Dart versions.
- Setup, run, test, build, and code-generation commands.
- Supported and actually verified platforms.
- Persistence migration details.
- Any unavoidable behaviour changes or remaining limitations.

The modernization is complete only when:

- The app builds and runs on the primary verified platform.
- Legacy APIs and incompatible dependencies have been addressed.
- Existing functionality is preserved or exceptions are explicitly approved.
- Existing persisted data is preserved or migrated.
- The UI remains recognizably Chryssibooru.
- Tests and analysis pass, subject to clearly documented environmental limits.
- No credentials, unrelated changes, or unexplained generated churn are added.

In the final report, summarize:

1. What changed.
2. Which Kemoshow-XP patterns were adopted and why.
3. How Chryssibooru's appearance and behaviour were preserved.
4. Toolchain and major dependency changes.
5. Persistence and platform migration considerations.
6. Exact checks run and their results.
7. Remaining blockers or unverified areas.

Leave all changes uncommitted for the user to review.

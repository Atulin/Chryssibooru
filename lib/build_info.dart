/// Build metadata injected at build time.
///
/// The release workflow passes `--dart-define=BUILD_DATE=<date>`; local
/// builds leave it empty and the about dialog hides the line.
const String buildDate = String.fromEnvironment('BUILD_DATE');

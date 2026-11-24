# Contributing to langswitch

Thank you for considering a contribution.

## Running the tests

```bash
# From the langswitch/ directory:
flutter test                      # all tests
flutter test --coverage           # with coverage report
dart format --set-exit-if-changed .
flutter analyze
```

CLI tests write to system temp directories and clean up after themselves. No
Android SDK or iOS toolchain is required to run them.

## Code style

- Dart: formatted with `dart format` (no custom rules beyond the defaults).
- Kotlin: standard Kotlin style conventions; `ktlint` is not enforced but welcome.
- Swift: standard Swift style.
- Doc comments (`///`) on every public symbol. No `//` block comments in `lib/`;
  one-line inline comments only where the *why* is non-obvious.
- No `print()` in library code outside `lib/src/cli/` (use the `avoid_print` lint).
- Keep `dart:io` confined to `lib/src/cli/` and `bin/`; `lib/langswitch.dart`
  must remain web/WASM compatible.

## PR checklist

Before opening a pull request:

- [ ] `dart format --set-exit-if-changed .` passes.
- [ ] `flutter analyze` reports zero issues.
- [ ] `flutter test` passes (all existing tests, plus new tests for new behavior).
- [ ] New public symbols have `///` doc comments.
- [ ] `CHANGELOG.md` has an entry under `## Unreleased` describing the change.
- [ ] No new dependencies added without discussion in an issue first.

## Reporting a bug

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.yml).
Include: Flutter version (`flutter --version`), target platform, and a minimal
reproduction. Issues without reproductions will be closed after two weeks.

## Feature requests

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.yml).
Describe the problem you are trying to solve, not just the solution you have in mind.

## License

By contributing, you agree that your contributions will be licensed under the
[MIT License](LICENSE).

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-14

### Added
- Initial release of `flutter_trigger`.
- `TriggerScope`: InheritedWidget wrapper for providing `Trigger` instances.
- `TriggerWidget`: A convenience widget for rebuilding on specific `Trigger` field changes.
- `TriggerStateMixin`: A mixin for `StatefulWidget` to listen to `Trigger` updates easily.
- `SelfTriggerWidget`: A self-contained widget for local state management.
- `SelfTriggerRegistry`: A global registry for `SelfTriggerWidgetController`.
- `TriggerContextX`: Extension on `BuildContext` to find `Trigger` instances from scope or global registry.
- Comprehensive `README.md` with usage examples.

### Changed
- Refactored `SelfTriggerWidget` to use `ValueNotifier` instead of `StreamController` for better performance and simplicity.
- Updated dependencies and finalized version `0.1.0`.
- Removed local path dependency for `trigger` package in favor of pub version.

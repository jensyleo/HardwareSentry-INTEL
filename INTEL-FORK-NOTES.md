# Intel fork notes

`HardwareSentry-INTEL` is the x86_64 / macOS 13+ port of
[`jensyleo/HardwareSentry`](https://github.com/jensyleo/HardwareSentry) (base: v2.0.0,
Apple Silicon, macOS 15, Swift 6). Kept separate from `README.md`/`CHANGELOG.md` so upstream merges stay clean.

## What differs from upstream
- Deployment target macOS 13.0, Swift language mode 5 (Xcode 15.2 builds it); `swift-tools-version` 5.9.
- `@Observable`/`@Bindable` (macOS 14) → `ObservableObject`/`@Published`/`@ObservedObject`; `withObservationTracking` in `AppDelegate` → Combine `objectWillChange` sinks.
- SignalCore is vendored in `Vendor/SignalCore` with the same backports (it needs macOS 15 upstream).
- Backports: `MainActor.assumeIsolated`, `ContentUnavailableView` (`EmptyStateView`), `Color.resolve`, `NSApplication.activate()`, `onChange(of:)` two-argument form, AVCaptureDevice notifications/types, `CWPHYMode.mode11be` (by raw value).
- Features gated on macOS 14/15 hardware APIs are skipped on older systems (e.g. background replacement effect, Continuity Camera type).

## Build
```sh
xcodebuild -project HardwareSentry.xcodeproj -scheme HardwareSentry -configuration Release -arch x86_64 build
```
Status: Debug build succeeds and the app launches on macOS 13.7 (Intel). Not yet exercised feature by feature.

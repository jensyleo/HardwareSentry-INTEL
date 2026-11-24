import Foundation

/// Backport of `MainActor.assumeIsolated`, which needs macOS 14. Callers are on the main
/// queue by construction (notification observers registered with `queue: .main`).
@inline(__always)
func assumeMainActor<T>(_ body: @MainActor () -> T) -> T {
    precondition(Thread.isMainThread, "Expected to be on the main thread")
    return withoutActuallyEscaping(body) { b in
        unsafeBitCast(b, to: (() -> T).self)()
    }
}

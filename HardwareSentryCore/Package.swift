// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HardwareSentryCore",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "MonitorRegistry", targets: ["MonitorRegistry"]),
        .library(name: "SentryContract", targets: ["SentryContract"]),
        .library(name: "SystemIcons", targets: ["SystemIcons"])
    ],
    dependencies: [
        .package(path: "../Vendor/SignalCore")
    ],
    targets: [
        // Prints the catalogue as JSON, for `Tools/parity-audit.sh`. An executable rather
        // than a test so the audit can be run on its own, without a build of the app.
        .executableTarget(
            name: "sentry-inventory",
            dependencies: ["MonitorRegistry", "SentryContract"]

        ),

        // What every monitor is allowed to know about. Deliberately small: a monitor
        // depends on this and on nothing else of the application.
        .target(
            name: "SentryContract",
            dependencies: [.product(name: "SignalCore", package: "SignalCore")]

        ),

        // One module per monitor. Being separate modules is what keeps them apart: what
        // is internal to one is invisible to the others, enforced by the compiler rather
        // than by anyone remembering to be careful.
        .target(
            name: "USBMonitor",
            dependencies: ["SentryContract"],
            resources: [.process("Resources")]

        ),
        .target(
            name: "ThermalMonitor",
            dependencies: ["SentryContract"],
            resources: [.process("Resources")]

        ),
        .target(
            name: "GamepadMonitor",
            dependencies: ["SentryContract"],
            resources: [.process("Resources")]

        ),
        .target(
            name: "ThunderboltMonitor",
            dependencies: ["SentryContract"],
            resources: [.process("Resources")]

        ),
        .target(
            name: "ScannerMonitor",
            dependencies: ["SentryContract"],
            resources: [.process("Resources")]

        ),
        .target(
            name: "CameraMonitor",
            dependencies: ["SentryContract"],
            resources: [.process("Resources")]

        ),
        .target(
            name: "DisplayMonitor",
            dependencies: ["SentryContract"],
            resources: [.process("Resources")]

        ),

        // Genuine C bridge (not a constant-casting fix like the others) — CUPS is a real C
        // library with no Swift overlay, so PrinterMonitor needs a system-library target
        // that imports its headers and links libcups. See CCUPS/shim.h.
        .systemLibrary(name: "CCUPS"),
        .target(
            name: "PrinterMonitor",
            dependencies: ["SentryContract", "CCUPS"],
            resources: [.process("Resources")]

        ),
        .target(
            name: "BluetoothMonitor",
            dependencies: ["SentryContract"],
            resources: [.process("Resources")]

        ),
        .target(
            name: "AudioMonitor",
            dependencies: ["SentryContract"],
            resources: [.process("Resources")]

        ),
        // A C shim, for the same reason CCUPS is one: the header ships in the SDK but is
        // not in IOKit's module map, so Swift cannot see it — and the interface behind it
        // is an IOCFPlugIn function-pointer table, which is the shape Swift handles worst.
        .target(name: "CNVMeSMART"),
        .target(
            name: "VolumeMonitor",
            dependencies: ["SentryContract", "CNVMeSMART"],
            resources: [.process("Resources")]

        ),
        .target(
            name: "PowerMonitor",
            dependencies: ["SentryContract"],
            resources: [.process("Resources")]

        ),
        .target(
            name: "NetworkMonitor",
            dependencies: ["SentryContract"],
            resources: [.process("Resources")]

        ),

        // The operating system's own pictures of devices, read at run time. No artwork of
        // Apple's is part of this package; only the paths to where macOS keeps it.
        .target(
            name: "SystemIcons",
            dependencies: [.product(name: "SignalCore", package: "SignalCore")]

        ),

        // The only place that knows the whole list.
        .target(
            name: "MonitorRegistry",
            dependencies: ["SentryContract", "USBMonitor", "ThermalMonitor", "GamepadMonitor", "ThunderboltMonitor", "ScannerMonitor", "CameraMonitor", "DisplayMonitor", "PrinterMonitor", "BluetoothMonitor", "AudioMonitor", "VolumeMonitor", "PowerMonitor", "NetworkMonitor"]

        ),

        // Test-only helpers shared across the monitor test targets — a wait-on-the-clock
        // pair, so that fix does not stay ten identical copies. Not a testTarget: SPM
        // does not let two test targets depend on each other, so an ordinary target is
        // the only way to share code between them.
        .target(name: "SentryTestSupport"),

        .testTarget(
            name: "SentryContractTests",
            dependencies: ["SentryContract"]

        ),
        .testTarget(
            name: "USBMonitorTests",
            dependencies: ["USBMonitor", "SentryTestSupport"]

        ),
        .testTarget(
            name: "ThermalMonitorTests",
            dependencies: ["ThermalMonitor", "SentryTestSupport"]

        ),
        .testTarget(
            name: "GamepadMonitorTests",
            dependencies: ["GamepadMonitor", "SentryTestSupport"]

        ),
        .testTarget(
            name: "ThunderboltMonitorTests",
            dependencies: ["ThunderboltMonitor", "SentryTestSupport"]

        ),
        .testTarget(
            name: "ScannerMonitorTests",
            dependencies: ["ScannerMonitor", "SentryTestSupport"]

        ),
        .testTarget(
            name: "CameraMonitorTests",
            dependencies: ["CameraMonitor", "SentryTestSupport"]

        ),
        .testTarget(
            name: "DisplayMonitorTests",
            dependencies: ["DisplayMonitor", "SentryTestSupport"]

        ),
        .testTarget(
            // CCUPS as well, so the capability test can name the real bits rather than
            // hardcoding numbers that would not follow the header if it ever changed.
            name: "PrinterMonitorTests",
            dependencies: ["PrinterMonitor", "CCUPS", "SentryTestSupport"]

        ),
        .testTarget(
            name: "BluetoothMonitorTests",
            dependencies: ["BluetoothMonitor", "SentryTestSupport"]

        ),
        .testTarget(
            name: "AudioMonitorTests",
            dependencies: ["AudioMonitor", "SentryTestSupport"]

        ),
        .testTarget(
            name: "VolumeMonitorTests",
            dependencies: ["VolumeMonitor", "SentryTestSupport"]

        ),
        .testTarget(
            name: "PowerMonitorTests",
            dependencies: ["PowerMonitor", "SentryTestSupport"]

        ),
        .testTarget(
            name: "SystemIconsTests",
            dependencies: ["SystemIcons", .product(name: "SignalCore", package: "SignalCore")]

        ),
        .testTarget(
            name: "MonitorRegistryTests",
            dependencies: ["MonitorRegistry", "SentryContract", "SystemIcons"]

        ),
        .testTarget(
            name: "NetworkMonitorTests",
            dependencies: ["NetworkMonitor", "SentryTestSupport"]

        )
    ]
)

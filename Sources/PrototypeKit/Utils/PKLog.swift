//
//  PKLog.swift
//
//
//  Centralized logging for PrototypeKit.
//

import os

/// A thin wrapper around `os.Logger` for one subsystem category.
///
/// Callers pass an ordinary `String`, so they don't need to import `os` or reason about
/// `OSLogMessage` privacy interpolation — messages are logged with `.public` privacy here, in
/// one place. PrototypeKit only ever logs developer-facing diagnostics (never user data), so
/// public privacy is appropriate and keeps the messages readable in Console.app.
struct PKLogger {

    private let logger: Logger

    init(category: String) {
        self.logger = Logger(subsystem: PKLog.subsystem, category: category)
    }

    func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }

    func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }
}

/// Namespaced loggers used throughout PrototypeKit.
///
/// PrototypeKit is a library, so it must never write to a consuming app's console with bare
/// `print(_:)` calls. Instead, diagnostics go through the unified logging system (`os.Logger`),
/// which is off by default in Release, respects the developer's log configuration, and can be
/// filtered by subsystem and category in Console.app or `log stream`.
///
/// Filter PrototypeKit output with, for example:
///
/// ```sh
/// log stream --predicate 'subsystem == "com.prototypekit.PrototypeKit"'
/// ```
enum PKLog {

    /// The subsystem all PrototypeKit loggers share.
    static let subsystem = "com.prototypekit.PrototypeKit"

    /// Logs relating to loading Core ML / Create ML models.
    static let model = PKLogger(category: "model")

    /// Logs relating to the camera capture pipeline and permissions.
    static let camera = PKLogger(category: "camera")

    /// Logs relating to Vision requests (classification, detection, recognition).
    static let vision = PKLogger(category: "vision")

    /// Logs relating to audio / sound classification.
    static let audio = PKLogger(category: "audio")

    /// Logs relating to CoreMotion-based activity classification.
    static let motion = PKLogger(category: "motion")
}

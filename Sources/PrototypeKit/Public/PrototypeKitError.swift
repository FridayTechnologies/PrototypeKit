//
//  PrototypeKitError.swift
//
//
//  A public error type that PrototypeKit surfaces to consuming apps.
//

import Foundation

/// An error PrototypeKit reports to your app through an `onError` handler.
///
/// PrototypeKit degrades gracefully — a failure never crashes the host app — but sometimes an app
/// wants to *react* to a failure (show a message, offer a retry) rather than silently show a camera
/// feed with no predictions. The camera and sound views/modifiers that load a model or start an audio
/// session accept an optional `onError` closure that receives one of these values.
///
/// Errors are always also written to the unified log (subsystem `com.prototypekit.PrototypeKit`).
public enum PrototypeKitError: Error {

    /// A Core ML / Create ML model could not be loaded from the given URL.
    ///
    /// The affected view still shows the camera feed but produces no predictions.
    case modelLoadFailed(url: URL, underlying: Error)

    /// Live sound classification could not start or was interrupted (for example, microphone
    /// access was denied or the audio session was interrupted).
    case soundClassificationFailed(underlying: Error)
}

extension PrototypeKitError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .modelLoadFailed(let url, let underlying):
            return "PrototypeKit couldn't load the model \"\(url.lastPathComponent)\": \(underlying.localizedDescription)"
        case .soundClassificationFailed(let underlying):
            return "PrototypeKit sound classification failed: \(underlying.localizedDescription)"
        }
    }
}

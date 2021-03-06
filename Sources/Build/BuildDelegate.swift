/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2018 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Basic
import Utility
import SPMLLBuild

/// Diagnostic error when a llbuild command encounters an error.
struct LLBuildCommandErrorDiagnostic: DiagnosticData {
    static let id = DiagnosticID(
        type: LLBuildCommandErrorDiagnostic.self,
        name: "org.swift.diags.llbuild-command-error",
        defaultBehavior: .error,
        description: { $0 <<< { $0.message } }
    )

    let message: String
}

/// Diagnostic warning when a llbuild command encounters a warning.
struct LLBuildCommandWarningDiagnostic: DiagnosticData {
    static let id = DiagnosticID(
        type: LLBuildCommandWarningDiagnostic.self,
        name: "org.swift.diags.llbuild-command-warning",
        defaultBehavior: .warning,
        description: { $0 <<< { $0.message } }
    )

    let message: String
}

/// Diagnostic note when a llbuild command encounters a warning.
struct LLBuildCommandNoteDiagnostic: DiagnosticData {
    static let id = DiagnosticID(
        type: LLBuildCommandNoteDiagnostic.self,
        name: "org.swift.diags.llbuild-command-note",
        defaultBehavior: .note,
        description: { $0 <<< { $0.message } }
    )

    let message: String
}

/// Diagnostic error when llbuild detects a cycle.
struct LLBuildCycleErrorDiagnostic: DiagnosticData {
    static let id = DiagnosticID(
        type: LLBuildCycleErrorDiagnostic.self,
        name: "org.swift.diags.llbuild-cycle",
        defaultBehavior: .error,
        description: {
            $0 <<< "build cycle detected: "
            $0 <<< { $0.rules.map({ $0.key }).joined(separator: ", ") }
        }
    )

    let rules: [BuildKey]
}

/// Diagnostic error from llbuild
struct LLBuildErrorDiagnostic: DiagnosticData {
    static let id = DiagnosticID(
        type: LLBuildErrorDiagnostic.self,
        name: "org.swift.diags.llbuild-error",
        defaultBehavior: .error,
        description: {
            $0 <<< { $0.message }
        }
    )

    let message: String
}

/// Diagnostic warning from llbuild
struct LLBuildWarningDiagnostic: DiagnosticData {
    static let id = DiagnosticID(
        type: LLBuildWarningDiagnostic.self,
        name: "org.swift.diags.llbuild-warning",
        defaultBehavior: .warning,
        description: {
            $0 <<< { $0.message }
        }
    )

    let message: String
}

/// Diagnostic note from llbuild
struct LLBuildNoteDiagnostic: DiagnosticData {
    static let id = DiagnosticID(
        type: LLBuildNoteDiagnostic.self,
        name: "org.swift.diags.llbuild-note",
        defaultBehavior: .note,
        description: {
            $0 <<< { $0.message }
        }
    )

    let message: String
}

/// Missing inptus from LLBuild
struct LLBuildMissingInputs: DiagnosticData {
    static let id = DiagnosticID(
        type: LLBuildMissingInputs.self,
        name: "org.swift.diags.llbuild-missing-inputs",
        defaultBehavior: .error,
        description: {
            $0 <<< "couldn't build "
            $0 <<< { $0.output.key }
            $0 <<< " because of missing inputs: "
            $0 <<< { $0.inputs.map({ $0.key }).joined(separator: ", ") }
        }
    )

    let output: BuildKey
    let inputs: [BuildKey]
}

/// Multiple producers from LLBuild
struct LLBuildMultipleProducers: DiagnosticData {
    static let id = DiagnosticID(
        type: LLBuildMultipleProducers.self,
        name: "org.swift.diags.llbuild-multiple-producers",
        defaultBehavior: .error,
        description: {
            $0 <<< "couldn't build "
            $0 <<< { $0.output.key }
            $0 <<< " because of multiple producers: "
            $0 <<< { $0.commands.map({ $0.description }).joined(separator: ", ") }
        }
    )

    let output: BuildKey
    let commands: [SPMLLBuild.Command]
}

/// Command error from LLBuild
struct LLBuildCommandError: DiagnosticData {
    static let id = DiagnosticID(
        type: LLBuildCommandError.self,
        name: "org.swift.diags.llbuild-command-error",
        defaultBehavior: .error,
        description: {
            $0 <<< "command "
            $0 <<< { $0.command.description }
            $0 <<< " failed: "
            $0 <<< { $0.message }
        }
    )

    let command: SPMLLBuild.Command
    let message: String
}

extension SPMLLBuild.Diagnostic: DiagnosticDataConvertible {
    public var diagnosticData: DiagnosticData {
        switch kind {
        case .error: return LLBuildErrorDiagnostic(message: message)
        case .warning: return LLBuildWarningDiagnostic(message: message)
        case .note: return LLBuildNoteDiagnostic(message: message)
        }
    }
}

private let newLineByte: UInt8 = 10
public final class BuildDelegate: BuildSystemDelegate {
    private let diagnostics: DiagnosticsEngine
    public var outputStream: OutputByteStream
    public var isVerbose: Bool = false
    public var onCommmandFailure: (() -> Void)?

    public init(diagnostics: DiagnosticsEngine, outputStream: OutputByteStream = stdoutStream) {
        self.diagnostics = diagnostics
        self.outputStream = outputStream
    }

    public var fs: SPMLLBuild.FileSystem? {
        return nil
    }

    public func lookupTool(_ name: String) -> Tool? {
        return nil
    }

    public func hadCommandFailure() {
        onCommmandFailure?()
    }

    public func handleDiagnostic(_ diagnostic: SPMLLBuild.Diagnostic) {
        diagnostics.emit(diagnostic)
    }

    public func commandStatusChanged(_ command: SPMLLBuild.Command, kind: CommandStatusKind) {
    }

    public func commandPreparing(_ command: SPMLLBuild.Command) {
    }

    public func commandStarted(_ command: SPMLLBuild.Command) {
        guard command.shouldShowStatus else { return }
        outputStream <<< ((isVerbose ? command.verboseDescription : command.description) + "\n")
        outputStream.flush()
    }

    public func shouldCommandStart(_ command: SPMLLBuild.Command) -> Bool {
        return true
    }

    public func commandFinished(_ command: SPMLLBuild.Command, result: CommandResult) {
    }

    public func commandHadError(_ command: SPMLLBuild.Command, message: String) {
        diagnostics.emit(data: LLBuildCommandErrorDiagnostic(message: message))
    }

    public func commandHadNote(_ command: SPMLLBuild.Command, message: String) {
        diagnostics.emit(data: LLBuildCommandNoteDiagnostic(message: message))
    }

    public func commandHadWarning(_ command: SPMLLBuild.Command, message: String) {
        diagnostics.emit(data: LLBuildCommandWarningDiagnostic(message: message))
    }

    public func commandCannotBuildOutputDueToMissingInputs(
        _ command: SPMLLBuild.Command,
        output: BuildKey,
        inputs: [BuildKey]
    ) {
        diagnostics.emit(data: LLBuildMissingInputs(output: output, inputs: inputs))
    }

    public func cannotBuildNodeDueToMultipleProducers(output: BuildKey, commands: [SPMLLBuild.Command]) {
        diagnostics.emit(data: LLBuildMultipleProducers(output: output, commands: commands))
    }

    public func commandProcessStarted(_ command: SPMLLBuild.Command, process: ProcessHandle) {
    }

    public func commandProcessHadError(_ command: SPMLLBuild.Command, process: ProcessHandle, message: String) {
        diagnostics.emit(data: LLBuildCommandError(command: command, message: message))
    }

    public func commandProcessHadOutput(_ command: SPMLLBuild.Command, process: ProcessHandle, data: [UInt8]) {
        outputStream <<< (data + [newLineByte])
        outputStream.flush()
    }

    public func commandProcessFinished(
        _ command: SPMLLBuild.Command,
        process: ProcessHandle,
        result: CommandExtendedResult
    ) {
    }

    public func cycleDetected(rules: [BuildKey]) {
        diagnostics.emit(data: LLBuildCycleErrorDiagnostic(rules: rules))
    }

    public func shouldResolveCycle(rules: [BuildKey], candidate: BuildKey, action: CycleAction) -> Bool {
        return false
    }
}

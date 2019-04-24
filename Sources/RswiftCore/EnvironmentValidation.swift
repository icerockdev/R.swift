//
//  EnvironmentValidation.swift
//  Commander
//
//  Created by Tom Lokhorst on 2018-12-12.
//

import Foundation

public func validateRswiftEnvironment(
  outputURL: URL,
  sourceRootPath: String,
  scriptInputFiles: [String],
  scriptOutputFiles: [String],
  lastRunURL: URL,
  podsRoot: String?,
  podsTargetSrcroot: String?,
  commandLineArguments: [String]) -> [String]
{
  var errors: [String] = []
  var outputFileForError = outputURL.path

  if outputURL.pathExtension != "swift" {

    var error = "Output path must specify a file, it should not be a directory."
    if FileManager.default.directoryExists(atPath: outputURL.path) {
      let rswiftGeneratedFile = outputURL.appendingPathComponent("R.generated.swift").path

      let commandParts = commandLineArguments
        .map { $0.replacingOccurrences(of: outputURL.path, with: rswiftGeneratedFile) }
        .map { $0.replacingOccurrences(of: podsTargetSrcroot ?? "", with: "$PODS_TARGET_SRCROOT") }
        .map { $0.replacingOccurrences(of: podsRoot ?? "", with: "$PODS_ROOT") }
        .map { $0.replacingOccurrences(of: sourceRootPath, with: "$SRCROOT") }
        .map { $0.contains(" ") ? "\"\($0)\"" : $0 }

      error += "\nExample: " + commandParts.joined(separator: " ")

      outputFileForError = rswiftGeneratedFile
    }

    errors.append(error)
  }

  let scriptInputPaths = scriptInputFiles.map { URL(fileURLWithPath: $0).standardized.path }
  if !scriptInputPaths.contains(lastRunURL.standardized.path) {
    errors.append("Build phase Intput Files does not contain '$TEMP_DIR/\(lastRunURL.lastPathComponent)'.")
  }

  let scriptOutputPaths = scriptOutputFiles.map { URL(fileURLWithPath: $0).standardized.path }
  if !scriptOutputPaths.contains(outputURL.standardized.path) && !scriptOutputPaths.contains(outputFileForError) {
    let path = outputFileForError
      .replacingOccurrences(of: podsTargetSrcroot ?? "", with: "$PODS_TARGET_SRCROOT")
      .replacingOccurrences(of: sourceRootPath, with: "$SRCROOT")
    errors.append("Build phase Output Files do not contain '\(path)'.")
  }

  return errors
}

extension FileManager {
  func directoryExists(atPath path: String) -> Bool {
    var isDir: ObjCBool = false
    let exists = fileExists(atPath: path, isDirectory: &isDir)

    return exists && isDir.boolValue
  }
}

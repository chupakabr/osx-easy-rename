//
//  RenamingService.swift
//  EasyRename
//
//  Created by Valeriy Chevtaev on 03/12/2018.
//  Copyright © 2018 7bit. All rights reserved.
//

import AppKit

enum RenamingErrorType {
    case partially
    case filesystem
}

protocol RenamingServiceProtocol {
    typealias Completion = (_ error: RenamingErrorType?) -> Void

    func rename(type: RenameType,
                in directoryPath: String,
                occurrences: String,
                replacement: String,
                completion: Completion)
}

final class RenamingService: RenamingServiceProtocol {
    private let fileManager: FileManager

    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }

    // MARK: - RenamingServiceProtocol

    func rename(type: RenameType,
                in directoryPath: String,
                occurrences: String,
                replacement: String,
                completion: Completion) {

        var processedFiles = 0

        let directoryPathUrl = URL(fileURLWithPath: directoryPath)
        var potentialFiles: [String]?
        do {
            potentialFiles = try self.fileManager.contentsOfDirectory(atPath: directoryPath)
        } catch {
            potentialFiles = nil
        }

        var hasErrors = false
        if let files = potentialFiles, !files.isEmpty {
            var isDir: ObjCBool = false
            var needRename = false
            let filePattern = NSPredicate(format: "self CONTAINS[c] %@", occurrences)

            for file in files {
                if filePattern.evaluate(with: file) {
                    let fromFile = directoryPathUrl.appendingPathComponent(file)
                    _ = self.fileManager.fileExists(atPath: fromFile.absoluteString, isDirectory: &isDir)

                    switch type {
                    case .files:
                        needRename = isDir.boolValue == false
                    case .folders:
                        needRename = isDir.boolValue == true
                    case .all:
                        needRename = true
                    }

                    if needRename {
                        let newFileName = file.replacingOccurrences(of: occurrences, with: replacement)
                        let toFile = directoryPathUrl.appendingPathComponent(newFileName)

                        do {
                            try self.fileManager.moveItem(at: fromFile, to: toFile)
                            processedFiles += 1
                        } catch {
                            hasErrors = true
                            NSLog("ERROR Failed to rename: \(file)")
                        }
                    }
                }
            }
        } else {
            hasErrors = true
        }

        let error: RenamingErrorType? = {
            guard hasErrors else { return nil }
            return processedFiles > 0 ? .partially : .filesystem
        }()
        completion(error)
    }
}

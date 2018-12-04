//
//  MainViewModel.swift
//  EasyRename
//
//  Created by Valeriy Chevtaev on 03/12/2018.
//  Copyright © 2018 7bit. All rights reserved.
//

import Foundation

enum ErrorType {
    case partially
    case filesystem
    case missingDirectory
    case missingPattern
    case unknown
}

protocol MainViewModelProtocol {
    typealias Completion = (_ error: ErrorType?) -> Void

    var renamingMessage: String { get }
    var renamedSuccessfullyMessage: String { get }

    func message(forError errorType: ErrorType) -> String
    func rename(type: RenameType,
                in directoryPath: String,
                occurrences: String,
                replacement: String,
                completion: @escaping MainViewModelProtocol.Completion)
}

final class MainViewModel: MainViewModelProtocol {
    private let renamingService: RenamingServiceProtocol

    init(renamingService: RenamingServiceProtocol) {
        self.renamingService = renamingService
    }

    // MARK: - MainViewModelProtocol

    var renamingMessage: String {
        return "Renaming...".localized
    }

    var renamedSuccessfullyMessage: String {
        return "Files were renamed successfully".localized
    }

    func message(forError errorType: ErrorType) -> String {
        switch errorType {
        case .partially:
            return "Not all files have been renamed".localized
        case .missingDirectory:
            return "Directory must be specified".localized
        case .missingPattern:
            return "Filename text must be set".localized
        case .filesystem,
             .unknown:
            return "Cannot rename files".localized
        }
    }

    func rename(type: RenameType,
                in directoryPath: String,
                occurrences: String,
                replacement: String,
                completion: @escaping MainViewModelProtocol.Completion) {

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                completion(.unknown)
                return
            }
            self.renamingService.rename(type: type, in: directoryPath, occurrences: occurrences, replacement: replacement) { error in
                DispatchQueue.main.async {
                    completion(error?.errorType)
                }
            }
        }
    }
}

// MARK: - RenamingErrorType
private extension RenamingErrorType {
    var errorType: ErrorType {
        switch self {
        case .partially:
            return .partially
        case .filesystem:
            return .filesystem
        }
    }
}

//
//  MainViewModel.swift
//  EasyRename
//
//  Created by Valeriy Chevtaev on 03/12/2018.
//  Copyright © 2018 7bit. All rights reserved.
//

import Foundation

protocol MainViewModelProtocol {
    func rename(type: RenameType,
                in directoryPath: String,
                occurrences: String,
                replacement: String,
                completion: RenamingService.Completion)
}

final class MainViewModel: MainViewModelProtocol {
    private let renamingService: RenamingServiceProtocol

    init(renamingService: RenamingServiceProtocol) {
        self.renamingService = renamingService
    }

    // MARK: - MainViewModelProtocol

    func rename(type: RenameType,
                in directoryPath: String,
                occurrences: String,
                replacement: String,
                completion: RenamingService.Completion) {

        self.renamingService.rename(type: type,
                                    in: directoryPath,
                                    occurrences: occurrences,
                                    replacement: replacement,
                                    completion: completion)
    }
}

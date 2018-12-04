//
//  MainViewController.swift
//  EasyRename
//
//  Created by Valeriy Chevtaev on 02/12/2018.
//  Copyright © 2018 7bit. All rights reserved.
//

import AppKit

@objc
final class MainViewController: NSObject {
    private enum State {
        case idle
        case error(type: ErrorType)
        case processing
    }

    private let viewModel: MainViewModelProtocol

    private var state: State = .idle {
        didSet {
            switch state {
            case .idle:
                self.moveToIdleState()
            case .error(let errorType):
                self.moveToErrorState(type: errorType)
            case .processing:
                self.moveToProcessingState()
            }
        }
    }

    // MARK: - IB Outlets

    @IBOutlet var renameThisTextField: NSTextField!
    @IBOutlet var replaceWithTextField: NSTextField!
    @IBOutlet var statusTextField: NSTextField!
    @IBOutlet var browseTextField: NSTextField!
    @IBOutlet var progressIndicator: NSProgressIndicator!
    @IBOutlet var browseButton: NSButton!
    @IBOutlet var renameButton: NSButton!
    @IBOutlet var replaceWithNoneCheckbox: NSButton!
    @IBOutlet var fileType: NSMatrix!

    override init() {
        let renamingService = RenamingService(fileManager: FileManager.default)
        self.viewModel = MainViewModel(renamingService: renamingService)
        super.init()
    }

    // MARK: - Actions

    @IBAction
    func browse(_ sender: Any) {
        let dlg = NSOpenPanel()
        dlg.canChooseFiles = false
        dlg.canChooseDirectories = true
        dlg.allowsMultipleSelection = false

        if dlg.runModal() == .OK {
            if let firstUrl = dlg.urls.first {
                self.browseTextField.stringValue = firstUrl.path
            }
        }
    }

    @IBAction
    func rename(_ sender: Any) {
        self.state = .processing

        let directoryPath = self.browseTextField.stringValue
        guard !directoryPath.isEmpty else {
            self.state = .error(type: .missingDirectory)
            return
        }

        let occurrences = self.renameThisTextField.stringValue
        guard !occurrences.isEmpty else {
            self.state = .error(type: .missingPattern)
            return
        }

        guard let renameType = RenameType(rawValue: self.fileType.selectedColumn) else {
            self.state = .error(type: .unknown)
            return
        }

        let replacement = self.replaceWithTextField.stringValue

        self.viewModel.rename(type: renameType, in: directoryPath, occurrences: occurrences, replacement: replacement) { [weak self] error in
            if let error = error {
                self?.state = .error(type: error)
            } else {
                self?.state = .idle
            }
        }
    }

    @IBAction
    func replaceWithNoneChanged(_ sender: NSButton) {
        if sender.intValue != 0 {
            self.replaceWithTextField.stringValue = ""
            self.replaceWithTextField.isEnabled = false
        } else {
            self.replaceWithTextField.isEnabled = true
        }
    }

    // MARK: - View states

    private func moveToIdleState() {
        self.enableUserInteraction(true)
        self.enableProgressIndicators(true)

        self.statusTextField.textColor = .controlTextColor
        self.statusTextField.stringValue = self.viewModel.renamedSuccessfullyMessage
    }

    private func moveToErrorState(type errorType: ErrorType) {
        self.enableUserInteraction(true)
        self.enableProgressIndicators(true)

        self.statusTextField.textColor = .red
        self.statusTextField.stringValue = self.viewModel.message(forError: errorType)
    }

    private func moveToProcessingState() {
        self.enableUserInteraction(false)
        self.enableProgressIndicators(false)
    }

    // MARK: - View updates

    private func enableProgressIndicators(_ isEnabled: Bool) {
        self.progressIndicator.isHidden = isEnabled

        if isEnabled {
            self.progressIndicator.stopAnimation(self)
        } else {
            self.progressIndicator.startAnimation(self)
            self.statusTextField.textColor = .controlTextColor
            self.statusTextField.stringValue = self.viewModel.renamingMessage
        }
    }

    private func enableUserInteraction(_ isEnabled: Bool) {
        self.renameThisTextField.isEditable = isEnabled
        self.replaceWithTextField.isEditable = isEnabled
        self.browseButton.isEnabled = isEnabled
        self.renameButton.isEnabled = isEnabled
        self.replaceWithNoneCheckbox.isEnabled = isEnabled

        if isEnabled {
            self.replaceWithNoneChanged(self.replaceWithNoneCheckbox)
        }
    }
}

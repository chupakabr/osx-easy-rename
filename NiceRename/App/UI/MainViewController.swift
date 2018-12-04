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

    private let notificationCenter = NotificationCenter.default
    private let viewModel: MainViewModelProtocol

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
        if self.browseTextField.stringValue.isEmpty {
            self.statusTextField.stringValue = "Directory must be specified".localized
            return
        }

        if self.renameThisTextField.stringValue.isEmpty {
            self.statusTextField.textColor = .red
            self.statusTextField.stringValue = "Filename text must be set".localized
            return
        }

        self.statusTextField.textColor = .controlTextColor
        self.statusTextField.stringValue = "Renaming...".localized

        self.progressIndicator.isHidden = false
        self.progressIndicator.startAnimation(self)

        // Disable UI controls
        self.renameThisTextField.isEditable = false
        self.replaceWithTextField.isEditable = false
        self.browseButton.isEnabled = false
        self.renameButton.isEnabled = false
        self.replaceWithNoneCheckbox.isEnabled = false

        // Bind notification listener
        self.notificationCenter.addObserver(self,
                                            selector: #selector(onRenameSuccess(notification:)),
                                            name: .renameSuccess,
                                            object: nil)
        self.notificationCenter.addObserver(self,
                                            selector: #selector(onRenameError(notification:)),
                                            name: .renameError,
                                            object: nil)

        let params: [String: Any] = [
            "filePath": self.browseTextField.stringValue,
            "renameText": self.renameThisTextField.stringValue,
            "replaceText": self.replaceWithTextField.stringValue,
            "fileType": NSNumber(value: self.fileType.selectedColumn)
        ]
        Thread.detachNewThreadSelector(#selector(doRename(params:)), toTarget: self, with: params)
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

    // MARK: - Notification handling

    @objc
    private func onRenameSuccess(notification: NSNotification) {
        DispatchQueue.main.async {
            self.onRenameFinish()
            self.statusTextField.stringValue = "Files were renamed successfully".localized
        }
    }

    @objc
    private func onRenameError(notification: NSNotification) {
        DispatchQueue.main.async {
            self.onRenameFinish()
            self.statusTextField.textColor = .red

            if let errorCode = notification.object as? NSNumber, errorCode.intValue == ErrorType.partially.rawValue {
                self.statusTextField.stringValue = "Not all files have been renamed".localized
            } else {
                self.statusTextField.stringValue = "Cannot rename files".localized
            }
        }
    }

    private func onRenameFinish() {
        // Stop notification listeners
        self.notificationCenter.removeObserver(self, name: .renameSuccess, object: nil)
        self.notificationCenter.removeObserver(self, name: .renameError, object: nil)

        // Update UI
        self.progressIndicator.stopAnimation(self)
        self.progressIndicator.isHidden = true
        self.statusTextField.stringValue = "Files were renamed successfully".localized

        // Enable UI controler
        self.renameThisTextField.isEditable = true
        self.replaceWithTextField.isEditable = true
        self.browseButton.isEnabled = true
        self.renameButton.isEnabled = true
        self.replaceWithNoneCheckbox.isEnabled = true
        self.replaceWithNoneChanged(self.replaceWithNoneCheckbox)
    }

    // MARK: - Business

    @objc
    private func doRename(params: [String: Any]) {
        guard let fileTypeNumber = params["fileType"] as? NSNumber,
            let fileType = RenameType(rawValue: fileTypeNumber.intValue),
            let filePath = params["filePath"] as? String,
            let renameText = params["renameText"] as? String,
            let replaceText = params["replaceText"] as? String else {
            let notification = Notification(name: .renameError,
                                            object: NSNumber(value: ErrorType.unknown.rawValue),
                                            userInfo: nil)
            self.notificationCenter.post(notification)
            return
        }

        self.viewModel.rename(type: fileType, in: filePath, occurrences: renameText, replacement: replaceText) { error in
            if let error = error {
                let notification = Notification(name: .renameError, object: NSNumber(value: error.rawValue))
                self.notificationCenter.post(notification)
            } else {
                self.notificationCenter.post(name: .renameSuccess, object: nil)
            }
        }
    }
}

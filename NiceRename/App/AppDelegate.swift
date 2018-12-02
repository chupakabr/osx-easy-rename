//
//  AppDelegate.swift
//  EasyRename
//
//  Created by Valeriy Chevtaev on 02/12/2018.
//  Copyright © 2018 7bit. All rights reserved.
//

import AppKit

@objc
final class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

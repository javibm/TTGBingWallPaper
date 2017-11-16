//
//  AppDelegate.swift
//  TTGBingWallPaper
//
//  Created by tutuge on 16/8/28.
//  Copyright © 2016年 tutuge. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    var autoUpdateMenuItem: NSMenuItem?
    var launchAtStartupMenuItem: NSMenuItem?
    
    @IBOutlet weak var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Setup
        WallPaperSevice.sharedInstance.setup()
        
        // Update
        WallPaperSevice.sharedInstance.updateAndSetNewestBingWallPaper { (success) in}
        
        // Set Wake from sleep notification
        NSWorkspace.shared.notificationCenter.addObserver(self, selector:
            #selector(didWakeFromSleep), name: NSWorkspace.didWakeNotification, object: nil)
        
        // Check if need update
        WallPaperSevice.sharedInstance.checkIfNeedUpdateWallPaper()
        
        // Setup UI
        configStatusButton()
        configMenuItems()
    }
    
    // MARK: Config
    
    func configStatusButton() {
        if let button = statusItem.button {
            button.image = NSImage(named: NSImage.Name(rawValue: "menu_icon"))
        }
    }
    
    func configMenuItems() {
        let menu = NSMenu()
        
        // Refresh newest wall paper
        menu.addItem(withTitle: "Newest", action: #selector(menuItemNewestWallPaperClick), keyEquivalent: "n")
        
        // Refresh random wall paper
        menu.addItem(withTitle: "Random", action: #selector(menuItemRandomWallPaperClick), keyEquivalent: "r")
        
        // Sub menu
        let subMenu = NSMenu()
        
        // Auto update
        autoUpdateMenuItem = NSMenuItem(title: "Auto Update", action: #selector(menuItemAutoUpdateClick), keyEquivalent: "")
        autoUpdateMenuItem?.toolTip = "Auto update newest Microsoft Bing Daily wallpaper."
        autoUpdateMenuItem?.onStateImage = NSImage(named: NSImage.Name(rawValue: "checked"))
        autoUpdateMenuItem?.offStateImage = nil
        updateAutoUpdateMenuItemState()
        subMenu.addItem(autoUpdateMenuItem!)
        
        // Launch at startup
        launchAtStartupMenuItem = NSMenuItem(title: "Launch at login", action: #selector(menuItemLaunchAtStartupClick), keyEquivalent: "")
        launchAtStartupMenuItem?.toolTip = "Config BingWallPaper launch at startup."
        launchAtStartupMenuItem?.onStateImage = NSImage(named: NSImage.Name(rawValue: "checked"))
        launchAtStartupMenuItem?.offStateImage = nil
        updateLaunchAtStartupMenuItemState()
        subMenu.addItem(launchAtStartupMenuItem!)
        
        // Open WallPaper folder
        subMenu.addItem(withTitle: "History Wallpapers", action: #selector(menuItemOpenWallPapersFolderClick), keyEquivalent: "")
        
        // Copyright
        subMenu.addItem(withTitle: "Copyright", action: #selector(menuItemCopyrightClick), keyEquivalent: "")
        
        // Github
        subMenu.addItem(withTitle: "Github", action: #selector(menuItemGithubClick), keyEquivalent: "");
        
        // Info
        subMenu.addItem(withTitle: "Info", action: #selector(menuItemInfoClick), keyEquivalent: "");
        
        // About
        subMenu.addItem(withTitle: "About", action: #selector(menuItemAboutClick), keyEquivalent: "")
        
        // More
        let subMenuItem = NSMenuItem()
        subMenuItem.title = "More..."
        subMenuItem.submenu = subMenu
        menu.addItem(subMenuItem)
        
        // Quit
        menu.addItem(withTitle: "Quit", action: #selector(menuItemQuitClick), keyEquivalent: "")
        
        statusItem.menu = menu
    }
    
    // MARK: Actions
    
    @objc func menuItemLaunchAtStartupClick() {
        StartupHelper.toggleLaunchAtStartup()
        updateLaunchAtStartupMenuItemState()
        
        UserNotificationHelper.show("Config changed !", subTitle: "Launch at startup: \(StartupHelper.applicationIsInStartUpItems() ? "ON" : "OFF")", content: "")
    }
    
    @objc func menuItemAutoUpdateClick() {
        let state = WallPaperSevice.sharedInstance.currentAutoUpadteSwitchState
        
        UserNotificationHelper.show("Config changed !", subTitle:  "Auto update: \(!state ? "ON" : "OFF")", content: "")
        
        WallPaperSevice.sharedInstance.currentAutoUpadteSwitchState = !state
        WallPaperSevice.sharedInstance.checkIfNeedUpdateWallPaper()
        
        updateAutoUpdateMenuItemState()
    }
    
    @objc func menuItemNewestWallPaperClick() {
        WallPaperSevice.sharedInstance.updateAndSetNewestBingWallPaper { (success) in
            UserNotificationHelper.showWallPaperUpdateInfoWithModel()
        }
    }

    @objc func menuItemRandomWallPaperClick() {
        WallPaperSevice.sharedInstance.updateAndSetRandomBingWallPaper { (success) in
            UserNotificationHelper.showWallPaperUpdateInfoWithModel()
        }
    }
    
    @objc func menuItemOpenWallPapersFolderClick() {
        if let folderPath = WallPaperSevice.sharedInstance.imagesFolderLocation {
            NSWorkspace.shared.open(folderPath as URL)
        }
    }
    
    @objc func menuItemCopyrightClick() {
        if let copyrightUrl = URL(string: WallPaperSevice.sharedInstance.currentModel?.copyRightUrl ?? WallPaperAPIManager.BingHost) {
            NSWorkspace.shared.open(copyrightUrl)
        }
    }
    
    @objc func menuItemGithubClick() {
        if let githubUrl = URL(string: "https://github.com/zekunyan/TTGBingWallPaper") {
            NSWorkspace.shared.open(githubUrl)
        }
    }
    
    @objc func menuItemInfoClick() {
        UserNotificationHelper.showWallPaperUpdateInfoWithModel()
    }
    
    @objc func menuItemAboutClick() {
        let contentTextView = NSTextView()
        
        contentTextView.frame = CGRect(x: 0, y: 0, width: 300, height: 60)
        contentTextView.string = "By tutuge.\nEmail: zekunyan@163.com\nGithub: https://github.com/zekunyan"
        contentTextView.sizeToFit()
        
        contentTextView.drawsBackground = false
        contentTextView.font = NSFont.systemFont(ofSize: 14)
        
        contentTextView.isEditable = true
        contentTextView.enabledTextCheckingTypes = NSTextCheckingAllTypes
        contentTextView.checkTextInDocument(nil)
        contentTextView.isEditable = false
        
        let alert = NSAlert()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String

        alert.icon = NSImage(named: NSImage.Name(rawValue: "AppIcon"))
        alert.messageText = "BingWallPaper \(version)"
        alert.accessoryView = contentTextView
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    @objc func menuItemQuitClick() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: NSWorkspaceDidWakeNotification
    
    @objc fileprivate func didWakeFromSleep() {
        WallPaperSevice.sharedInstance.checkIfNeedUpdateWallPaper()
    }
    
    // MARK: Private methods
    
    fileprivate func updateAutoUpdateMenuItemState() {
        autoUpdateMenuItem?.state = NSControl.StateValue(rawValue: WallPaperSevice.sharedInstance.currentAutoUpadteSwitchState ? 1 : 0)
    }
    
    fileprivate func updateLaunchAtStartupMenuItemState() {
        launchAtStartupMenuItem?.state = NSControl.StateValue(rawValue: StartupHelper.applicationIsInStartUpItems() ? 1 : 0)
    }
}


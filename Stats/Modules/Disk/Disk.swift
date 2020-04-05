//
//  Disk.swift
//  Stats
//
//  Created by Serhiy Mytrovtsiy on 14/01/2020.
//  Copyright © 2020 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa

class Disk: Module {
    public var name: String = "SSD"
    public var updateInterval: Double = 5
    
    public var enabled: Bool = true
    public var available: Bool = true
    
    public var readers: [Reader] = []
    public var task: Repeater?
    
    public var widget: ModuleWidget = ModuleWidget()
    public var popup: ModulePopup = ModulePopup(false)
    public var menu: NSMenuItem = NSMenuItem()
    
    internal let defaults = UserDefaults.standard
    internal var submenu: NSMenu = NSMenu()
    internal var selectedDisk: String = ""
    internal var disks: disksList = disksList()
    
    init() {
        if !self.available { return }
        
        self.enabled = defaults.object(forKey: name) != nil ? defaults.bool(forKey: name) : true
        self.updateInterval = defaults.object(forKey: "\(name)_interval") != nil ? defaults.double(forKey: "\(name)_interval") : self.updateInterval
        self.widget.type = defaults.object(forKey: "\(name)_widget") != nil ? defaults.float(forKey: "\(name)_widget") : Widgets.Mini
        self.selectedDisk = defaults.object(forKey: "\(name)_disk") != nil ? defaults.string(forKey: "\(name)_disk")! : self.selectedDisk
        
        self.initWidget()
        self.initMenu()
        
        readers.append(DiskCapacityReader(self.usageUpdater))
        
        self.task = Repeater.init(interval: .seconds(self.updateInterval), observer: { _ in
            self.readers.forEach { reader in
                reader.read()
            }
        })
    }
    
    public func start() {
        if self.task != nil && self.task!.state.isRunning == false {
            self.task!.start()
        }
    }
    
    public func stop() {
        if self.task!.state.isRunning {
            self.task?.pause()
        }
    }
    
    public func restart() {
        self.stop()
        self.start()
    }
    
    private func usageUpdater(disks: disksList) {
        if self.disks.list.count != disks.list.count && disks.list.count != 0 {
            self.disks = disks
            self.initMenu()
        }
        
        if self.widget.view is Widget {
            var d: diskInfo? = disks.getDiskByBSDName(self.selectedDisk)
            if d == nil {
                d = disks.getRootDisk()
            }
            
            if d != nil {
                let total = d!.totalSize
                let free = d!.freeSize
                let usedSpace = total - free
                let percentage = Double(usedSpace) / Double(total)
                
                (self.widget.view as! Widget).setValue(data: [percentage])
            }
        }
    }
}

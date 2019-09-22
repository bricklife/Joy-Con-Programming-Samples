//
//  main.swift
//  set-player-lights
//
//  Created by Shinichiro Oba on 2019/09/22.
//

import Foundation
import IOKit.hid

var connectedDevices: [IOHIDDevice] = []
var globalPacketNumber: UInt8 = 0

func sendSetPlayerLightsCommand() {
    // https://github.com/dekuNukem/Nintendo_Switch_Reverse_Engineering/blob/master/bluetooth_hid_notes.md#output-0x01
    var data = [UInt8](repeating: 0, count: 40)
    data[0] = 0x01
    data[1] = globalPacketNumber
    
    // https://github.com/dekuNukem/Nintendo_Switch_Reverse_Engineering/blob/master/bluetooth_hid_subcommands_notes.md#subcommand-0x30-set-player-lights
    let playerLights = globalPacketNumber & 0x0f
    data[10] = 0x30
    data[11] = playerLights
    
    for device in connectedDevices {
        IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, CFIndex(data[0]), data, data.count)
    }
    
    globalPacketNumber = (globalPacketNumber + 1) & 0x0f
}

Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (timer) in
    sendSetPlayerLightsCommand()
}

let manager = IOHIDManagerCreate(kCFAllocatorDefault, 0 /* kIOHIDManagerOptionNone */)

IOHIDManagerSetDeviceMatchingMultiple(manager, [
    [kIOHIDVendorIDKey: 0x057E, kIOHIDProductIDKey: 0x2006 /* Joy-Con (L) */],
    [kIOHIDVendorIDKey: 0x057E, kIOHIDProductIDKey: 0x2007 /* Joy-Con (R) */],
    ] as CFArray)

IOHIDManagerRegisterDeviceMatchingCallback(manager, { (context, result, sender, device) in
    print("Matched", device)
    
    IOHIDDeviceOpen(device, 1 /* kIOHIDOptionsTypeSeizeDevice */)
    
    connectedDevices.append(device)
}, nil)

IOHIDManagerRegisterDeviceRemovalCallback(manager, { (context, result, sender, device) in
    print("Removed", device)
    
    if let index = connectedDevices.firstIndex(of: device) {
        connectedDevices.remove(at: index)
    }
}, nil)

IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

IOHIDManagerOpen(manager, 1 /* kIOHIDOptionsTypeSeizeDevice */)

CFRunLoopRun()

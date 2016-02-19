/*
* The MIT License
*
* Copyright (c) 2016 halo
* Based on the hard work by Eric Betts, see https://github.com/bettse/KuandoSwift
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import Foundation
import IOKit.hid

class G710plus : NSObject {
  
  let vendorId  = 0x046d  // Logitech
  let productId = 0xc24d  // G710+ Keyboard

  let reportSize = 16
  static let singleton = G710plus()
  var device : IOHIDDevice? = nil
  var currentM : UInt8 = 0
  
  var currentMBitmask: UInt8 {
    switch (self.currentM) {
    case 1: return 0x10
    case 2: return 0x20
    case 3: return 0x40
    default: return 0
    }
  }
  
  var G1AliasKey: KeyCode {
    switch (self.currentM) {
    case 1 : return KeyCode.Keypad1
    case 2 : return KeyCode.Keypad7
    default: return KeyCode.nullEvent
    }
  }

  var G2AliasKey: KeyCode {
    switch (self.currentM) {
    case 1 : return KeyCode.Keypad2
    case 2 : return KeyCode.Keypad8
    default: return KeyCode.nullEvent
    }
  }

  var G3AliasKey: KeyCode {
    switch (self.currentM) {
    case 1 : return KeyCode.Keypad3
    case 2 : return KeyCode.Keypad9
    default: return KeyCode.nullEvent
    }
  }

  var G4AliasKey: KeyCode {
    switch (self.currentM) {
    case 1 : return KeyCode.Keypad4
    case 2 : return KeyCode.KeypadMultiply
    default: return KeyCode.nullEvent
    }
  }

  var G5AliasKey: KeyCode {
    switch (self.currentM) {
    case 1 : return KeyCode.Keypad5
    case 2 : return KeyCode.KeypadPlus
    default: return KeyCode.nullEvent
    }
  }

  var G6AliasKey: KeyCode {
    switch (self.currentM) {
    case 1 : return KeyCode.Keypad6
    case 2 : return KeyCode.KeypadDivide
    default: return KeyCode.nullEvent
    }
  }

  func setM(number: UInt8) {
    self.currentM = number
    self.setMLight()
  }
  
  func run() {
    let deviceMatch = [kIOHIDProductIDKey: productId, kIOHIDVendorIDKey: vendorId ]
    let managerRef = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone)).takeUnretainedValue()
    
    IOHIDManagerSetDeviceMatching(managerRef, deviceMatch)
    IOHIDManagerScheduleWithRunLoop(managerRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    IOHIDManagerOpen(managerRef, 0);
    
    let matchingCallback : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
      let this : G710plus = unsafeBitCast(inContext, G710plus.self)
      this.connected(inResult, inSender: inSender, inIOHIDDeviceRef: inIOHIDDeviceRef)
    }
    
    let removalCallback : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
      let this : G710plus = unsafeBitCast(inContext, G710plus.self)
      this.removed(inResult, inSender: inSender, inIOHIDDeviceRef: inIOHIDDeviceRef)
    }
    
    IOHIDManagerRegisterDeviceMatchingCallback(managerRef, matchingCallback, unsafeBitCast(self, UnsafeMutablePointer<Void>.self))
    IOHIDManagerRegisterDeviceRemovalCallback(managerRef, removalCallback, unsafeBitCast(self, UnsafeMutablePointer<Void>.self))
    
    NSRunLoop.currentRunLoop().run();
  }

  func connected(inResult: IOReturn, inSender: UnsafeMutablePointer<Void>, inIOHIDDeviceRef: IOHIDDevice!) {
    log("G710+ connected")
    // It would be better to look up the report size and create a chunk of memory of that size
    let report = UnsafeMutablePointer<UInt8>.alloc(reportSize)
    device = inIOHIDDeviceRef
    
    let inputCallback : IOHIDReportCallback = { inContext, inResult, inSender, type, reportId, report, reportLength in
      let this : G710plus = unsafeBitCast(inContext, G710plus.self)
      this.input(inResult, inSender: inSender, type: type, reportId: reportId, report: report, reportLength: reportLength)
    }
    
    //Hook up inputcallback
    IOHIDDeviceRegisterInputReportCallback(device, report, reportSize, inputCallback, unsafeBitCast(self, UnsafeMutablePointer<Void>.self));

    self.deactivateGhosting()
    self.setM(1);
  }
  
  func removed(inResult: IOReturn, inSender: UnsafeMutablePointer<Void>, inIOHIDDeviceRef: IOHIDDevice!) {
    log("G710+ removed")
    //NSNotificationCenter.defaultCenter().postNotificationName("deviceDisconnected", object: nil, userInfo: ["class": NSStringFromClass(self.dynamicType)])
  }
  
  func controlTransfer(address: CFIndex, bytes: [UInt8]) {
    let G710plus = device
    if G710plus == nil { return }
    let data = NSData(bytes:bytes, length:bytes.count)
    
    log("Writing to control \(address) with bytes \(bytes)")
    IOHIDDeviceSetReport(G710plus, kIOHIDReportTypeFeature, address, UnsafePointer<UInt8>(data.bytes), data.length)
  }

  func setMLight() {
    log("Turning on Light for M\(self.currentM)...")
    self.controlTransfer(0x0306, bytes: [0x06, self.currentMBitmask])
  }

  func deactivateGhosting() {
    log("Deactivating G-keys mirroring 1-6")
    self.controlTransfer(0x0309, bytes: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
  }

  func input(inResult: IOReturn, inSender: UnsafeMutablePointer<Void>, type: IOHIDReportType, reportId: UInt32, report: UnsafeMutablePointer<UInt8>, reportLength: CFIndex) {

    // So the keyboard tells us that a key event happened.
    // Converting the data pointer to an Integer so we can interpret it.
    let message = NSData(bytes: report, length: reportLength)
    var keyCode: UInt32 = 0
    message.getBytes(&keyCode, length: sizeof(UInt32))
    
    // For some reason the G710+ constantly sends empty key events.
    // We'll just ignore those.
    if (keyCode == 0) { return }
    
    switch (keyCode) {
      
    // See if one of the M-keys was pressed
    case 0x100003:
      log("You pressed M1")
      self.setM(1)
    case 0x200003:
      log("You pressed M2")
      self.setM(2)
    case 0x400003:
      log("You pressed M3")
      self.setM(3)
    
    // See if one of the G-keys was pressed
    case 0x103:
      print("You pressed G1")
      self.pressKey(G1AliasKey);
    case 0x203:
      print("You pressed G1")
      self.pressKey(G2AliasKey);
    case 0x403:
      print("You pressed G3")
      self.pressKey(G3AliasKey);
    case 0x803:
      print("You pressed G4")
      self.pressKey(G4AliasKey);
    case 0x1003:
      print("You pressed G5")
      self.pressKey(G5AliasKey);
    case 0x2003:
      print("You pressed G6")
      self.pressKey(G6AliasKey);

    default: log ("Ignoring key event \(keyCode).")
    }
}
  
  func pressKey(keyCode: KeyCode) {
    if (keyCode == KeyCode.nullEvent) { return }
    
    let source = CGEventSourceCreate(CGEventSourceStateID.HIDSystemState)
    let event = CGEventCreateKeyboardEvent(source, keyCode.rawValue, true)
    let location = CGEventTapLocation.CGHIDEventTap

    log("Simulating key press \(keyCode)")
    CGEventPost(location, event)
  }
  
  func log(message: String) {
    if Process.arguments.contains("--verbose") {
      print(message)
    }
  }
  
}

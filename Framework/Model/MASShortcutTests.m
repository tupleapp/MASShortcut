@interface MASShortcutTests : XCTestCase
@end

@implementation MASShortcutTests

- (void) testEquality
{
    MASShortcut *keyA = [MASShortcut shortcutWithKeyCode:1 modifierFlags:NSEventModifierFlagControl];
    MASShortcut *keyB = [MASShortcut shortcutWithKeyCode:2 modifierFlags:NSEventModifierFlagControl];
    MASShortcut *keyC = [MASShortcut shortcutWithKeyCode:1 modifierFlags:NSEventModifierFlagOption];
    MASShortcut *keyD = [MASShortcut shortcutWithKeyCode:1 modifierFlags:NSEventModifierFlagControl];
    XCTAssertTrue([keyA isEqual:keyA], @"Shortcut is equal to itself.");
    XCTAssertTrue([keyA isEqual:[keyA copy]], @"Shortcut is equal to its copy.");
    XCTAssertFalse([keyA isEqual:keyB], @"Shortcuts not equal when key codes differ.");
    XCTAssertFalse([keyA isEqual:keyC], @"Shortcuts not equal when modifier flags differ.");
    XCTAssertTrue([keyA isEqual:keyD], @"Shortcuts are equal when key codes and modifiers are.");
    XCTAssertFalse([keyA isEqual:@"foo"], @"Shortcut not equal to an object of a different class.");
}

- (void) testHIDShortcutEquality
{
    MASHIDButtonIdentifier *idA = [MASHIDButtonIdentifier identifierWithVendorID:1 productID:2 usagePage:9 usage:1 deviceName:@"Gamepad" serialNumber:@"ABC123"];
    MASHIDButtonIdentifier *idB = [MASHIDButtonIdentifier identifierWithVendorID:1 productID:2 usagePage:9 usage:1 deviceName:@"Gamepad" serialNumber:@"ABC123"];
    MASHIDButtonIdentifier *idDiffUsage = [MASHIDButtonIdentifier identifierWithVendorID:1 productID:2 usagePage:9 usage:2 deviceName:@"Gamepad" serialNumber:@"ABC123"];
    MASHIDButtonIdentifier *idDiffSerial = [MASHIDButtonIdentifier identifierWithVendorID:1 productID:2 usagePage:9 usage:1 deviceName:@"Gamepad" serialNumber:@"XYZ789"];
    MASHIDButtonIdentifier *idNoSerial = [MASHIDButtonIdentifier identifierWithVendorID:1 productID:2 usagePage:9 usage:1 deviceName:@"Gamepad"];
    MASHIDButtonIdentifier *idDiffName = [MASHIDButtonIdentifier identifierWithVendorID:1 productID:2 usagePage:9 usage:1 deviceName:@"Controller" serialNumber:@"ABC123"];

    XCTAssertEqualObjects(idA, idB, @"Identifiers with same fields are equal.");
    XCTAssertEqual(idA.hash, idB.hash, @"Equal identifiers have equal hashes.");
    XCTAssertNotEqualObjects(idA, idDiffUsage, @"Different usage means not equal.");
    XCTAssertNotEqualObjects(idA, idDiffSerial, @"Different serial number means not equal.");
    XCTAssertNotEqualObjects(idA, idNoSerial, @"Non-nil serial != nil serial.");
    XCTAssertEqualObjects(idA, idDiffName, @"Device name is cosmetic and excluded from equality.");
}

- (void) testHIDIdentifierWithoutSerialNumber
{
    MASHIDButtonIdentifier *withSerial = [MASHIDButtonIdentifier identifierWithVendorID:1 productID:2 usagePage:9 usage:1 deviceName:@"Gamepad" serialNumber:@"ABC123"];
    MASHIDButtonIdentifier *withoutSerial = [withSerial identifierWithoutSerialNumber];
    XCTAssertNil(withoutSerial.serialNumber, @"identifierWithoutSerialNumber clears serial.");
    XCTAssertEqual(withoutSerial.usage, withSerial.usage, @"Other fields preserved.");
    XCTAssertNotEqualObjects(withSerial, withoutSerial, @"With and without serial are not equal.");

    MASHIDButtonIdentifier *alreadyNil = [MASHIDButtonIdentifier identifierWithVendorID:1 productID:2 usagePage:9 usage:1 deviceName:@"Gamepad"];
    XCTAssertEqual(alreadyNil, [alreadyNil identifierWithoutSerialNumber], @"Returns self when serial is already nil.");
}

- (void) testHIDShortcutIsNotEqualToKeyboardShortcut
{
    MASShortcut *keyboard = [MASShortcut shortcutWithKeyCode:1 modifierFlags:NSEventModifierFlagCommand];
    MASHIDButtonIdentifier *hid = [MASHIDButtonIdentifier identifierWithVendorID:1 productID:2 usagePage:9 usage:1 deviceName:@"Gamepad"];
    MASShortcut *hidShortcut = [MASShortcut shortcutWithHIDButton:hid];
    XCTAssertFalse([keyboard isEqual:hidShortcut], @"Keyboard shortcut is not equal to HID shortcut.");
    XCTAssertTrue(hidShortcut.isHIDShortcut, @"HID shortcut reports isHIDShortcut YES.");
    XCTAssertFalse(keyboard.isHIDShortcut, @"Keyboard shortcut reports isHIDShortcut NO.");
}

- (void) testShortcutRecorderCompatibility
{
    MASShortcut *key = [MASShortcut shortcutWithKeyCode:87 modifierFlags:1048576];
    XCTAssertEqualObjects([key description], @"⌘5", @"Basic compatibility with the keycode & modifier combination used by Shortcut Recorder.");
}

@end

@interface MASDictionaryTransformerTests : XCTestCase
@end

@implementation MASDictionaryTransformerTests

- (void) testErrorHandling
{
    MASDictionaryTransformer *transformer = [MASDictionaryTransformer new];
    XCTAssertNil([transformer transformedValue:nil],
        @"Decoding a shortcut from a nil dictionary returns nil.");
    XCTAssertNil([transformer transformedValue:(id)@"foo"],
        @"Decoding a shortcut from a invalid-type dictionary returns nil.");
    XCTAssertNil([transformer transformedValue:@{}],
        @"Decoding a shortcut from an empty dictionary returns nil.");
    XCTAssertNil([transformer transformedValue:@{@"keyCode":@"foo"}],
        @"Decoding a shortcut from a wrong-typed dictionary returns nil.");
    XCTAssertNil([transformer transformedValue:@{@"keyCode":@1}],
        @"Decoding a shortcut from an incomplete dictionary returns nil.");
    XCTAssertNil([transformer transformedValue:@{@"modifierFlags":@1}],
        @"Decoding a shortcut from an incomplete dictionary returns nil.");
}

- (void) testNilRepresentation
{
    MASDictionaryTransformer *transformer = [MASDictionaryTransformer new];
    XCTAssertEqualObjects([transformer reverseTransformedValue:nil], [NSDictionary dictionary],
        @"Store nil values as an empty dictionary.");
    XCTAssertNil([transformer transformedValue:[NSDictionary dictionary]],
        @"Load empty dictionary as nil.");
}

- (void) testHIDRoundTrip
{
    MASDictionaryTransformer *transformer = [MASDictionaryTransformer new];
    MASHIDButtonIdentifier *identifier = [MASHIDButtonIdentifier identifierWithVendorID:0x045E productID:0x02FD usagePage:9 usage:3 deviceName:@"Xbox Controller" serialNumber:@"SN12345"];
    MASShortcut *original = [MASShortcut shortcutWithHIDButton:identifier];

    NSDictionary *dict = [transformer reverseTransformedValue:original];
    MASShortcut *decoded = [transformer transformedValue:dict];

    XCTAssertTrue(decoded.isHIDShortcut, @"Decoded shortcut is HID.");
    XCTAssertEqualObjects(original, decoded, @"HID shortcut round-trips through dictionary transformer.");
    XCTAssertEqualObjects(decoded.hidButtonIdentifier.serialNumber, @"SN12345", @"Serial number preserved.");
    XCTAssertEqualObjects(decoded.hidButtonIdentifier.deviceName, @"Xbox Controller", @"Device name preserved.");
}

- (void) testHIDRoundTripWithoutSerial
{
    MASDictionaryTransformer *transformer = [MASDictionaryTransformer new];
    MASHIDButtonIdentifier *identifier = [MASHIDButtonIdentifier identifierWithVendorID:0x045E productID:0x02FD usagePage:9 usage:1 deviceName:@"Xbox Controller"];
    MASShortcut *original = [MASShortcut shortcutWithHIDButton:identifier];

    NSDictionary *dict = [transformer reverseTransformedValue:original];
    MASShortcut *decoded = [transformer transformedValue:dict];

    XCTAssertTrue(decoded.isHIDShortcut, @"Decoded shortcut is HID.");
    XCTAssertEqualObjects(original, decoded, @"HID shortcut without serial round-trips.");
    XCTAssertNil(decoded.hidButtonIdentifier.serialNumber, @"Serial number remains nil.");
}

- (void) testHIDMalformedDictionary
{
    MASDictionaryTransformer *transformer = [MASDictionaryTransformer new];
    XCTAssertNil([transformer transformedValue:@{@"hidButton": @"not a dict"}],
        @"Non-dictionary hidButton value returns nil.");
    XCTAssertNil([transformer transformedValue:@{@"hidButton": @{@"vendorID": @1}}],
        @"Incomplete HID dictionary returns nil.");
}

@end

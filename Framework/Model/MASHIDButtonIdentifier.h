#import <Foundation/Foundation.h>

/**
 Identifies a specific button on a specific HID device (gamepad, joystick, etc.).

 Equality is based on vendorID, productID, usagePage, usage, and serialNumber.
 The deviceName is cosmetic and excluded from equality/hash.
 Serial number participates strictly in equality: nil == nil, "X" == "X", nil != "X".
*/
@interface MASHIDButtonIdentifier : NSObject <NSSecureCoding, NSCopying>

@property (nonatomic, readonly) NSInteger vendorID;
@property (nonatomic, readonly) NSInteger productID;
@property (nonatomic, readonly) NSInteger usagePage;
@property (nonatomic, readonly) NSInteger usage;
@property (nonatomic, readonly, copy) NSString *deviceName;
@property (nonatomic, readonly, copy, nullable) NSString *serialNumber;

- (instancetype)initWithVendorID:(NSInteger)vendorID
                       productID:(NSInteger)productID
                       usagePage:(NSInteger)usagePage
                           usage:(NSInteger)usage
                      deviceName:(NSString *)deviceName
                    serialNumber:(nullable NSString *)serialNumber;

- (instancetype)initWithVendorID:(NSInteger)vendorID
                       productID:(NSInteger)productID
                       usagePage:(NSInteger)usagePage
                           usage:(NSInteger)usage
                      deviceName:(NSString *)deviceName;

+ (instancetype)identifierWithVendorID:(NSInteger)vendorID
                             productID:(NSInteger)productID
                             usagePage:(NSInteger)usagePage
                                 usage:(NSInteger)usage
                            deviceName:(NSString *)deviceName
                          serialNumber:(nullable NSString *)serialNumber;

+ (instancetype)identifierWithVendorID:(NSInteger)vendorID
                             productID:(NSInteger)productID
                             usagePage:(NSInteger)usagePage
                                 usage:(NSInteger)usage
                            deviceName:(NSString *)deviceName;

/**
 Returns a copy of this identifier with serialNumber set to nil.
 Returns self if serialNumber is already nil.
*/
- (instancetype)identifierWithoutSerialNumber;

/**
 Returns a human-readable display string, e.g. "Xbox Controller Button 1".
 Falls back to "HID Device Button <N>" if no device name is available.
 Appends a serial suffix when a serial number is present for disambiguation.
*/
- (NSString *)displayString;

@end

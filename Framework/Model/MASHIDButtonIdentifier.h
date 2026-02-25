#import <Foundation/Foundation.h>

/**
 Identifies a specific button on a specific HID device (gamepad, joystick, etc.).

 Equality is based on vendorID, productID, usagePage, and usage.
 The deviceName is cosmetic and excluded from equality/hash.
*/
@interface MASHIDButtonIdentifier : NSObject <NSSecureCoding, NSCopying>

@property (nonatomic, readonly) NSInteger vendorID;
@property (nonatomic, readonly) NSInteger productID;
@property (nonatomic, readonly) NSInteger usagePage;
@property (nonatomic, readonly) NSInteger usage;
@property (nonatomic, readonly, copy) NSString *deviceName;

- (instancetype)initWithVendorID:(NSInteger)vendorID
                       productID:(NSInteger)productID
                       usagePage:(NSInteger)usagePage
                           usage:(NSInteger)usage
                      deviceName:(NSString *)deviceName;

+ (instancetype)identifierWithVendorID:(NSInteger)vendorID
                             productID:(NSInteger)productID
                             usagePage:(NSInteger)usagePage
                                 usage:(NSInteger)usage
                            deviceName:(NSString *)deviceName;

/**
 Returns a human-readable display string, e.g. "Xbox Controller Button 1".
 Falls back to "HID Device Button <N>" if no device name is available.
*/
- (NSString *)displayString;

@end

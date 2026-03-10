#import "MASHIDButtonIdentifier.h"

static NSString *const kVendorIDKey = @"vendorID";
static NSString *const kProductIDKey = @"productID";
static NSString *const kUsagePageKey = @"usagePage";
static NSString *const kUsageKey = @"usage";
static NSString *const kDeviceNameKey = @"deviceName";
static NSString *const kSerialNumberKey = @"serialNumber";

@implementation MASHIDButtonIdentifier

#pragma mark - Initialization

- (instancetype)initWithVendorID:(NSInteger)vendorID
                       productID:(NSInteger)productID
                       usagePage:(NSInteger)usagePage
                           usage:(NSInteger)usage
                      deviceName:(NSString *)deviceName
                    serialNumber:(NSString *)serialNumber
{
    self = [super init];
    if (self) {
        _vendorID = vendorID;
        _productID = productID;
        _usagePage = usagePage;
        _usage = usage;
        _deviceName = [deviceName copy];
        _serialNumber = (serialNumber.length > 0) ? [serialNumber copy] : nil;
    }
    return self;
}

- (instancetype)initWithVendorID:(NSInteger)vendorID
                       productID:(NSInteger)productID
                       usagePage:(NSInteger)usagePage
                           usage:(NSInteger)usage
                      deviceName:(NSString *)deviceName
{
    return [self initWithVendorID:vendorID
                        productID:productID
                        usagePage:usagePage
                            usage:usage
                       deviceName:deviceName
                     serialNumber:nil];
}

+ (instancetype)identifierWithVendorID:(NSInteger)vendorID
                             productID:(NSInteger)productID
                             usagePage:(NSInteger)usagePage
                                 usage:(NSInteger)usage
                            deviceName:(NSString *)deviceName
                          serialNumber:(NSString *)serialNumber
{
    return [[self alloc] initWithVendorID:vendorID
                                productID:productID
                                usagePage:usagePage
                                    usage:usage
                               deviceName:deviceName
                             serialNumber:serialNumber];
}

+ (instancetype)identifierWithVendorID:(NSInteger)vendorID
                             productID:(NSInteger)productID
                             usagePage:(NSInteger)usagePage
                                 usage:(NSInteger)usage
                            deviceName:(NSString *)deviceName
{
    return [[self alloc] initWithVendorID:vendorID
                                productID:productID
                                usagePage:usagePage
                                    usage:usage
                               deviceName:deviceName
                             serialNumber:nil];
}

#pragma mark - Display

- (NSString *)displayString
{
    NSString *name = (_deviceName.length > 0) ? _deviceName : @"HID Device";
    if (_serialNumber.length >= 4) {
        NSString *suffix = [_serialNumber substringFromIndex:_serialNumber.length - 4];
        return [NSString stringWithFormat:@"%@ (...%@) Button %ld", name, suffix, (long)_usage];
    } else if (_serialNumber.length > 0) {
        return [NSString stringWithFormat:@"%@ (...%@) Button %ld", name, _serialNumber, (long)_usage];
    }
    return [NSString stringWithFormat:@"%@ Button %ld", name, (long)_usage];
}

- (instancetype)identifierWithoutSerialNumber
{
    if (_serialNumber == nil) return self;
    return [[MASHIDButtonIdentifier alloc] initWithVendorID:_vendorID
                                                  productID:_productID
                                                  usagePage:_usagePage
                                                      usage:_usage
                                                 deviceName:_deviceName
                                               serialNumber:nil];
}

- (NSString *)description
{
    return [self displayString];
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object) return YES;
    if (![object isKindOfClass:[MASHIDButtonIdentifier class]]) return NO;

    MASHIDButtonIdentifier *other = object;
    if (self.vendorID != other.vendorID) return NO;
    if (self.productID != other.productID) return NO;
    if (self.usagePage != other.usagePage) return NO;
    if (self.usage != other.usage) return NO;

    // Strict serial number comparison: nil==nil, "X"=="X", nil!="X" → NO
    if (_serialNumber == nil && other->_serialNumber == nil) return YES;
    return [_serialNumber isEqualToString:other->_serialNumber];
}

- (NSUInteger)hash
{
    NSUInteger base = (NSUInteger)(_vendorID ^ (_productID << 8) ^ (_usagePage << 16) ^ (_usage << 24));
    if (_serialNumber) {
        base ^= [_serialNumber hash];
    }
    return base;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInteger:_vendorID forKey:kVendorIDKey];
    [coder encodeInteger:_productID forKey:kProductIDKey];
    [coder encodeInteger:_usagePage forKey:kUsagePageKey];
    [coder encodeInteger:_usage forKey:kUsageKey];
    [coder encodeObject:_deviceName forKey:kDeviceNameKey];
    if (_serialNumber) {
        [coder encodeObject:_serialNumber forKey:kSerialNumberKey];
    }
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    NSInteger vendorID = [coder decodeIntegerForKey:kVendorIDKey];
    NSInteger productID = [coder decodeIntegerForKey:kProductIDKey];
    NSInteger usagePage = [coder decodeIntegerForKey:kUsagePageKey];
    NSInteger usage = [coder decodeIntegerForKey:kUsageKey];
    NSString *deviceName = [coder decodeObjectOfClass:[NSString class] forKey:kDeviceNameKey];
    NSString *serialNumber = [coder decodeObjectOfClass:[NSString class] forKey:kSerialNumberKey];
    return [self initWithVendorID:vendorID productID:productID usagePage:usagePage usage:usage deviceName:deviceName serialNumber:serialNumber];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [[MASHIDButtonIdentifier alloc] initWithVendorID:_vendorID
                                                 productID:_productID
                                                 usagePage:_usagePage
                                                     usage:_usage
                                                deviceName:_deviceName
                                              serialNumber:_serialNumber];
}

@end

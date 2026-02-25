#import "MASHIDButtonIdentifier.h"

static NSString *const kVendorIDKey = @"vendorID";
static NSString *const kProductIDKey = @"productID";
static NSString *const kUsagePageKey = @"usagePage";
static NSString *const kUsageKey = @"usage";
static NSString *const kDeviceNameKey = @"deviceName";

@implementation MASHIDButtonIdentifier

#pragma mark - Initialization

- (instancetype)initWithVendorID:(NSInteger)vendorID
                       productID:(NSInteger)productID
                       usagePage:(NSInteger)usagePage
                           usage:(NSInteger)usage
                      deviceName:(NSString *)deviceName
{
    self = [super init];
    if (self) {
        _vendorID = vendorID;
        _productID = productID;
        _usagePage = usagePage;
        _usage = usage;
        _deviceName = [deviceName copy];
    }
    return self;
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
                               deviceName:deviceName];
}

#pragma mark - Display

- (NSString *)displayString
{
    NSString *name = (_deviceName.length > 0) ? _deviceName : @"HID Device";
    return [NSString stringWithFormat:@"%@ Button %ld", name, (long)_usage];
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
    return (self.vendorID == other.vendorID)
        && (self.productID == other.productID)
        && (self.usagePage == other.usagePage)
        && (self.usage == other.usage);
}

- (NSUInteger)hash
{
    return (NSUInteger)(_vendorID ^ (_productID << 8) ^ (_usagePage << 16) ^ (_usage << 24));
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
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    NSInteger vendorID = [coder decodeIntegerForKey:kVendorIDKey];
    NSInteger productID = [coder decodeIntegerForKey:kProductIDKey];
    NSInteger usagePage = [coder decodeIntegerForKey:kUsagePageKey];
    NSInteger usage = [coder decodeIntegerForKey:kUsageKey];
    NSString *deviceName = [coder decodeObjectOfClass:[NSString class] forKey:kDeviceNameKey];
    return [self initWithVendorID:vendorID productID:productID usagePage:usagePage usage:usage deviceName:deviceName];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [[MASHIDButtonIdentifier alloc] initWithVendorID:_vendorID
                                                 productID:_productID
                                                 usagePage:_usagePage
                                                     usage:_usage
                                                deviceName:_deviceName];
}

@end

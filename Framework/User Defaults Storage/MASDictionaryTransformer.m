#import "MASDictionaryTransformer.h"
#import "MASShortcut.h"
#import "MASHIDButtonIdentifier.h"

NSString *const MASDictionaryTransformerName = @"MASDictionaryTransformer";

static NSString *const MASKeyCodeKey = @"keyCode";
static NSString *const MASModifierFlagsKey = @"modifierFlags";
static NSString *const MASHIDButtonKey = @"hidButton";
static NSString *const MASHIDVendorIDKey = @"vendorID";
static NSString *const MASHIDProductIDKey = @"productID";
static NSString *const MASHIDUsagePageKey = @"usagePage";
static NSString *const MASHIDUsageKey = @"usage";
static NSString *const MASHIDDeviceNameKey = @"deviceName";

@implementation MASDictionaryTransformer

+ (BOOL) allowsReverseTransformation
{
    return YES;
}

// Storing nil values as an empty dictionary lets us differ between
// “not available, use default value” and “explicitly set to none”.
// See http://stackoverflow.com/questions/5540760 for details.
- (NSDictionary*) reverseTransformedValue: (MASShortcut*) shortcut
{
    if (shortcut == nil) {
        return [NSDictionary dictionary];
    } else if (shortcut.isHIDShortcut) {
        MASHIDButtonIdentifier *hid = shortcut.hidButtonIdentifier;
        NSMutableDictionary *hidDict = [NSMutableDictionary dictionary];
        hidDict[MASHIDVendorIDKey] = @(hid.vendorID);
        hidDict[MASHIDProductIDKey] = @(hid.productID);
        hidDict[MASHIDUsagePageKey] = @(hid.usagePage);
        hidDict[MASHIDUsageKey] = @(hid.usage);
        if (hid.deviceName) {
            hidDict[MASHIDDeviceNameKey] = hid.deviceName;
        }
        return @{ MASHIDButtonKey: [hidDict copy] };
    } else {
        return @{
            MASKeyCodeKey: @([shortcut keyCode]),
            MASModifierFlagsKey: @([shortcut modifierFlags])
        };
    }
}

- (MASShortcut*) transformedValue: (NSDictionary*) dictionary
{
    // We have to be defensive here as the value may come from user defaults.
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    // Check for HID button data first
    NSDictionary *hidDict = [dictionary objectForKey:MASHIDButtonKey];
    if ([hidDict isKindOfClass:[NSDictionary class]]) {
        SEL integerValue = @selector(integerValue);
        id vendorBox = hidDict[MASHIDVendorIDKey];
        id productBox = hidDict[MASHIDProductIDKey];
        id usagePageBox = hidDict[MASHIDUsagePageKey];
        id usageBox = hidDict[MASHIDUsageKey];

        if ([vendorBox respondsToSelector:integerValue] && [productBox respondsToSelector:integerValue]
            && [usagePageBox respondsToSelector:integerValue] && [usageBox respondsToSelector:integerValue]) {
            NSString *deviceName = hidDict[MASHIDDeviceNameKey];
            if (![deviceName isKindOfClass:[NSString class]]) {
                deviceName = nil;
            }
            MASHIDButtonIdentifier *identifier =
                [MASHIDButtonIdentifier identifierWithVendorID:[vendorBox integerValue]
                                                     productID:[productBox integerValue]
                                                     usagePage:[usagePageBox integerValue]
                                                         usage:[usageBox integerValue]
                                                    deviceName:deviceName];
            return [MASShortcut shortcutWithHIDButton:identifier];
        }
        return nil;
    }

    // Fall through to existing keyboard shortcut path
    id keyCodeBox = [dictionary objectForKey:MASKeyCodeKey];
    id modifierFlagsBox = [dictionary objectForKey:MASModifierFlagsKey];

    SEL integerValue = @selector(integerValue);
    if (![keyCodeBox respondsToSelector:integerValue] || ![modifierFlagsBox respondsToSelector:integerValue]) {
        return nil;
    }

    return [MASShortcut
        shortcutWithKeyCode:[keyCodeBox integerValue]
        modifierFlags:[modifierFlagsBox integerValue]];
}

@end

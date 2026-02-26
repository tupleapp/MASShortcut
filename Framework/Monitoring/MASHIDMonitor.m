#import "MASHIDMonitor.h"
#import "MASHIDButtonIdentifier.h"
#import <IOKit/hid/IOHIDManager.h>

@interface MASHIDMonitor ()
@property (nonatomic, assign) IOHIDManagerRef hidManager;
@property (nonatomic, strong) NSMutableDictionary<MASHIDButtonIdentifier *, NSDictionary *> *registeredButtons;
@property (nonatomic, copy) void (^captureCallback)(MASHIDButtonIdentifier *);
@end

static void MASHIDInputValueCallback(void *context, IOReturn result, void *sender, IOHIDValueRef value);

@implementation MASHIDMonitor

#pragma mark - Initialization

+ (instancetype)sharedMonitor
{
    static dispatch_once_t once;
    static MASHIDMonitor *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] initPrivate];
    });
    return sharedInstance;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        _registeredButtons = [NSMutableDictionary dictionary];
        [self setupHIDManager];
    }
    return self;
}

- (void)dealloc
{
    if (_hidManager) {
        IOHIDManagerUnscheduleFromRunLoop(_hidManager, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        IOHIDManagerClose(_hidManager, kIOHIDOptionsTypeNone);
        CFRelease(_hidManager);
        _hidManager = NULL;
    }
}

- (void)setupHIDManager
{
    _hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    if (!_hidManager) return;

    // Match joysticks, gamepads, multi-axis controllers, and assistive devices on the Generic Desktop usage page
    NSDictionary *joystick = @{
        @(kIOHIDDeviceUsagePageKey): @(kHIDPage_GenericDesktop),
        @(kIOHIDDeviceUsageKey): @(kHIDUsage_GD_Joystick)
    };
    NSDictionary *gamepad = @{
        @(kIOHIDDeviceUsagePageKey): @(kHIDPage_GenericDesktop),
        @(kIOHIDDeviceUsageKey): @(kHIDUsage_GD_GamePad)
    };
    NSDictionary *multiAxis = @{
        @(kIOHIDDeviceUsagePageKey): @(kHIDPage_GenericDesktop),
        @(kIOHIDDeviceUsageKey): @(kHIDUsage_GD_MultiAxisController)
    };
    NSDictionary *assistive = @{
        @(kIOHIDDeviceUsagePageKey): @(kHIDPage_GenericDesktop),
        @(kIOHIDDeviceUsageKey): @(kHIDUsage_GD_AssistiveControl)
    };
    NSArray *matchingCriteria = @[joystick, gamepad, multiAxis, assistive];

    IOHIDManagerSetDeviceMatchingMultiple(_hidManager, (__bridge CFArrayRef)matchingCriteria);
    IOHIDManagerRegisterInputValueCallback(_hidManager, MASHIDInputValueCallback, (__bridge void *)self);
    IOHIDManagerScheduleWithRunLoop(_hidManager, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    IOHIDManagerOpen(_hidManager, kIOHIDOptionsTypeNone);
}

#pragma mark - Registration

- (BOOL)registerHIDButton:(MASHIDButtonIdentifier *)identifier withAction:(dispatch_block_t)action
{
    if (!identifier || !action) return NO;
    _registeredButtons[identifier] = @{ @"keyDown": [action copy] };
    return YES;
}

- (BOOL)registerHIDButton:(MASHIDButtonIdentifier *)identifier withKeyDownAction:(dispatch_block_t)keyDown keyUpAction:(dispatch_block_t)keyUp
{
    if (!identifier || (!keyDown && !keyUp)) return NO;
    NSMutableDictionary *actions = [NSMutableDictionary dictionary];
    if (keyDown) actions[@"keyDown"] = [keyDown copy];
    if (keyUp) actions[@"keyUp"] = [keyUp copy];
    _registeredButtons[identifier] = [actions copy];
    return YES;
}

- (void)unregisterHIDButton:(MASHIDButtonIdentifier *)identifier
{
    if (identifier) {
        [_registeredButtons removeObjectForKey:identifier];
    }
}

- (void)unregisterAllHIDButtons
{
    [_registeredButtons removeAllObjects];
}

- (BOOL)isHIDButtonRegistered:(MASHIDButtonIdentifier *)identifier
{
    return !![_registeredButtons objectForKey:identifier];
}

#pragma mark - Capture

- (void)captureNextButtonPress:(void (^)(MASHIDButtonIdentifier *))callback
{
    self.captureCallback = callback;
}

#pragma mark - Input Handling

- (void)handleInputValue:(IOHIDValueRef)value
{
    IOHIDElementRef element = IOHIDValueGetElement(value);
    uint32_t usagePage = IOHIDElementGetUsagePage(element);

    // Only handle button page events
    if (usagePage != kHIDPage_Button) return;

    CFIndex intValue = IOHIDValueGetIntegerValue(value);

    uint32_t usage = IOHIDElementGetUsage(element);
    IOHIDDeviceRef device = IOHIDElementGetDevice(element);

    NSInteger vendorID = [(__bridge NSNumber *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDVendorIDKey)) integerValue];
    NSInteger productID = [(__bridge NSNumber *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductIDKey)) integerValue];
    NSString *deviceName = (__bridge NSString *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductKey));

    NSString *serialNumber = (__bridge NSString *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDSerialNumberKey));
    if (serialNumber.length == 0) serialNumber = nil;

    MASHIDButtonIdentifier *identifier =
        [MASHIDButtonIdentifier identifierWithVendorID:vendorID
                                             productID:productID
                                             usagePage:usagePage
                                                 usage:usage
                                            deviceName:deviceName
                                          serialNumber:serialNumber];

    // Capture mode takes priority — press only
    if (intValue > 0 && self.captureCallback) {
        void (^callback)(MASHIDButtonIdentifier *) = self.captureCallback;
        self.captureCallback = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(identifier);
        });
        return;
    }

    // Two-tier lookup: exact match first, then fallback without serial number
    NSDictionary *actions = _registeredButtons[identifier];
    if (!actions && serialNumber != nil) {
        actions = _registeredButtons[[identifier identifierWithoutSerialNumber]];
    }
    if (!actions) return;

    if (intValue > 0) {
        dispatch_block_t keyDown = actions[@"keyDown"];
        if (keyDown) {
            dispatch_async(dispatch_get_main_queue(), keyDown);
        }
    } else {
        dispatch_block_t keyUp = actions[@"keyUp"];
        if (keyUp) {
            dispatch_async(dispatch_get_main_queue(), keyUp);
        }
    }
}

@end

#pragma mark - IOKit Callback

static void MASHIDInputValueCallback(void *context, IOReturn result, void *sender, IOHIDValueRef value)
{
    MASHIDMonitor *monitor = (__bridge MASHIDMonitor *)context;
    [monitor handleInputValue:value];
}

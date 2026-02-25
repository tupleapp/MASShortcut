#import "MASHIDMonitor.h"
#import "MASHIDButtonIdentifier.h"
#import <IOKit/hid/IOHIDManager.h>

@interface MASHIDMonitor ()
@property (nonatomic, assign) IOHIDManagerRef hidManager;
@property (nonatomic, strong) NSMutableDictionary<MASHIDButtonIdentifier *, dispatch_block_t> *registeredButtons;
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

    // Match joysticks, gamepads, and multi-axis controllers on the Generic Desktop usage page
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
    NSArray *matchingCriteria = @[joystick, gamepad, multiAxis];

    IOHIDManagerSetDeviceMatchingMultiple(_hidManager, (__bridge CFArrayRef)matchingCriteria);
    IOHIDManagerRegisterInputValueCallback(_hidManager, MASHIDInputValueCallback, (__bridge void *)self);
    IOHIDManagerScheduleWithRunLoop(_hidManager, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    IOHIDManagerOpen(_hidManager, kIOHIDOptionsTypeNone);
}

#pragma mark - Registration

- (BOOL)registerHIDButton:(MASHIDButtonIdentifier *)identifier withAction:(dispatch_block_t)action
{
    if (!identifier || !action) return NO;
    _registeredButtons[identifier] = [action copy];
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

    // Only handle button page presses
    if (usagePage != kHIDPage_Button) return;

    // Only handle press (value > 0), not release
    CFIndex intValue = IOHIDValueGetIntegerValue(value);
    if (intValue <= 0) return;

    uint32_t usage = IOHIDElementGetUsage(element);
    IOHIDDeviceRef device = IOHIDElementGetDevice(element);

    NSInteger vendorID = [(__bridge NSNumber *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDVendorIDKey)) integerValue];
    NSInteger productID = [(__bridge NSNumber *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductIDKey)) integerValue];
    NSString *deviceName = (__bridge NSString *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductKey));

    MASHIDButtonIdentifier *identifier =
        [MASHIDButtonIdentifier identifierWithVendorID:vendorID
                                             productID:productID
                                             usagePage:usagePage
                                                 usage:usage
                                            deviceName:deviceName];

    // Capture mode takes priority
    if (self.captureCallback) {
        void (^callback)(MASHIDButtonIdentifier *) = self.captureCallback;
        self.captureCallback = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(identifier);
        });
        return;
    }

    // Look up registered action
    dispatch_block_t action = _registeredButtons[identifier];
    if (action) {
        dispatch_async(dispatch_get_main_queue(), action);
    }
}

@end

#pragma mark - IOKit Callback

static void MASHIDInputValueCallback(void *context, IOReturn result, void *sender, IOHIDValueRef value)
{
    MASHIDMonitor *monitor = (__bridge MASHIDMonitor *)context;
    [monitor handleInputValue:value];
}

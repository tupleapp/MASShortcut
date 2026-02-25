#import <Foundation/Foundation.h>

@class MASHIDButtonIdentifier;

/**
 Monitors HID device button presses (gamepads, joysticks, assistive devices).

 Uses IOKit's IOHIDManager to observe button presses from matching devices.
 All callbacks fire on the main thread.
*/
@interface MASHIDMonitor : NSObject

- (instancetype)init __unavailable;
+ (instancetype)sharedMonitor;

/**
 Register an HID button with an action to execute when pressed.
 Returns YES on success.
*/
- (BOOL)registerHIDButton:(MASHIDButtonIdentifier *)identifier withAction:(dispatch_block_t)action;

/**
 Unregister a previously registered HID button.
*/
- (void)unregisterHIDButton:(MASHIDButtonIdentifier *)identifier;

/**
 Unregister all HID buttons.
*/
- (void)unregisterAllHIDButtons;

/**
 Check if an HID button is currently registered.
*/
- (BOOL)isHIDButtonRegistered:(MASHIDButtonIdentifier *)identifier;

/**
 Capture the next HID button press. The callback fires once with the identifier
 of the pressed button, then capture mode is automatically disabled.

 Pass nil to cancel capture mode.
*/
- (void)captureNextButtonPress:(void (^)(MASHIDButtonIdentifier *identifier))callback;

@end

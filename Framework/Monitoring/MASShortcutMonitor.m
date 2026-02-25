#import "MASShortcutMonitor.h"
#import "MASHotKey.h"
#import "MASHIDMonitor.h"

@interface MASShortcutMonitor ()
@property(assign) EventHandlerRef eventHandlerRef;
@property(strong) NSMutableDictionary *hotKeys;
@end

static OSStatus MASCarbonEventCallback(EventHandlerCallRef, EventRef, void*);

@implementation MASShortcutMonitor

#pragma mark Initialization

- (instancetype) init
{
    self = [super init];
    [self setHotKeys:[NSMutableDictionary dictionary]];
    EventTypeSpec hotKeySpecs[] = {
        { .eventClass = kEventClassKeyboard, .eventKind = kEventHotKeyPressed },
        { .eventClass = kEventClassKeyboard, .eventKind = kEventHotKeyReleased },
    };
    OSStatus status = InstallEventHandler(GetEventDispatcherTarget(), MASCarbonEventCallback,
        2, hotKeySpecs, (__bridge void*)self, &_eventHandlerRef);
    if (status != noErr) {
        return nil;
    }
    return self;
}

- (void) dealloc
{
    if (_eventHandlerRef) {
        RemoveEventHandler(_eventHandlerRef);
        _eventHandlerRef = NULL;
    }
}

+ (instancetype) sharedMonitor
{
    static dispatch_once_t once;
    static MASShortcutMonitor *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark Registration

- (BOOL) registerShortcut: (MASShortcut*) shortcut withAction: (dispatch_block_t) action
{
    if (shortcut.isHIDShortcut) {
        return [[MASHIDMonitor sharedMonitor] registerHIDButton:shortcut.hidButtonIdentifier withAction:action];
    }

    MASHotKey *hotKey = [MASHotKey registeredHotKeyWithShortcut:shortcut];
    if (hotKey) {
        [hotKey setAction:action];
        [_hotKeys setObject:hotKey forKey:shortcut];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) registerShortcut: (MASShortcut*) shortcut withKeyDownAction: (dispatch_block_t) keyDown keyUpAction: (dispatch_block_t) keyUp
{
    if (shortcut.isHIDShortcut) {
        return [[MASHIDMonitor sharedMonitor] registerHIDButton:shortcut.hidButtonIdentifier withKeyDownAction:keyDown keyUpAction:keyUp];
    }

    MASHotKey *hotKey = [MASHotKey registeredHotKeyWithShortcut:shortcut];
    if (hotKey) {
        [hotKey setAction:keyDown];
        [hotKey setKeyUpAction:keyUp];
        [_hotKeys setObject:hotKey forKey:shortcut];
        return YES;
    } else {
        return NO;
    }
}

- (void) unregisterShortcut: (MASShortcut*) shortcut
{
    if (shortcut) {
        if (shortcut.isHIDShortcut) {
            [[MASHIDMonitor sharedMonitor] unregisterHIDButton:shortcut.hidButtonIdentifier];
        } else {
            [_hotKeys removeObjectForKey:shortcut];
        }
    }
}

- (void) unregisterAllShortcuts
{
    [_hotKeys removeAllObjects];
    [[MASHIDMonitor sharedMonitor] unregisterAllHIDButtons];
}

- (BOOL) isShortcutRegistered: (MASShortcut*) shortcut
{
    if (shortcut.isHIDShortcut) {
        return [[MASHIDMonitor sharedMonitor] isHIDButtonRegistered:shortcut.hidButtonIdentifier];
    }
    return !![_hotKeys objectForKey:shortcut];
}

#pragma mark Event Handling

- (void) handleEvent: (EventRef) event
{
    if (GetEventClass(event) != kEventClassKeyboard) {
        return;
    }

    EventHotKeyID hotKeyID;
    OSStatus status = GetEventParameter(event, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hotKeyID), NULL, &hotKeyID);
    if (status != noErr || hotKeyID.signature != MASHotKeySignature) {
        return;
    }

    UInt32 eventKind = GetEventKind(event);

    [_hotKeys enumerateKeysAndObjectsUsingBlock:^(MASShortcut *shortcut, MASHotKey *hotKey, BOOL *stop) {
        if (hotKeyID.id == [hotKey carbonID]) {
            if (eventKind == kEventHotKeyPressed) {
                if ([hotKey action]) {
                    dispatch_async(dispatch_get_main_queue(), [hotKey action]);
                }
            } else if (eventKind == kEventHotKeyReleased) {
                if ([hotKey keyUpAction]) {
                    dispatch_async(dispatch_get_main_queue(), [hotKey keyUpAction]);
                }
            }
            *stop = YES;
        }
    }];
}

@end

static OSStatus MASCarbonEventCallback(EventHandlerCallRef _, EventRef event, void *context)
{
    MASShortcutMonitor *dispatcher = (__bridge id)context;
    [dispatcher handleEvent:event];
    return noErr;
}

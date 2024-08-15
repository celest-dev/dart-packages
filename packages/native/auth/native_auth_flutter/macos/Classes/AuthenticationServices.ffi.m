#include <stdint.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AuthenticationServices/ASFoundation.h>
#import <AuthenticationServices/ASWebAuthenticationSession.h>
#import <AuthenticationServices/ASWebAuthenticationSessionCallback.h>
#import <Foundation/Foundation.h>
#import <CloudKit/CloudKit.h>

typedef void  (^ListenerBlock)(NSEvent* );
ListenerBlock wrapListenerBlock_ObjCBlock_ffiVoid_NSEvent(ListenerBlock block) {
  ListenerBlock wrapper = [^void(NSEvent* arg0) {
    block([arg0 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock1)(NSError* );
ListenerBlock1 wrapListenerBlock_ObjCBlock_ffiVoid_NSError(ListenerBlock1 block) {
  ListenerBlock1 wrapper = [^void(NSError* arg0) {
    block([arg0 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock2)(NSEvent* , BOOL * );
ListenerBlock2 wrapListenerBlock_ObjCBlock_ffiVoid_NSEvent_bool(ListenerBlock2 block) {
  ListenerBlock2 wrapper = [^void(NSEvent* arg0, BOOL * arg1) {
    block([arg0 retain], arg1);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock3)(NSWindow* , BOOL * );
ListenerBlock3 wrapListenerBlock_ObjCBlock_ffiVoid_NSWindow_bool(ListenerBlock3 block) {
  ListenerBlock3 wrapper = [^void(NSWindow* arg0, BOOL * arg1) {
    block([arg0 retain], arg1);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock4)(void * , NSApplication* , id );
ListenerBlock4 wrapListenerBlock_ObjCBlock_ffiVoid_ffiVoid_NSApplication_objcObjCObject(ListenerBlock4 block) {
  ListenerBlock4 wrapper = [^void(void * arg0, NSApplication* arg1, id arg2) {
    block(arg0, [arg1 retain], [arg2 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock5)(void * , NSApplication* , NSData* );
ListenerBlock5 wrapListenerBlock_ObjCBlock_ffiVoid_ffiVoid_NSApplication_NSData(ListenerBlock5 block) {
  ListenerBlock5 wrapper = [^void(void * arg0, NSApplication* arg1, NSData* arg2) {
    block(arg0, [arg1 retain], [arg2 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock6)(void * , NSApplication* , NSError* );
ListenerBlock6 wrapListenerBlock_ObjCBlock_ffiVoid_ffiVoid_NSApplication_NSError(ListenerBlock6 block) {
  ListenerBlock6 wrapper = [^void(void * arg0, NSApplication* arg1, NSError* arg2) {
    block(arg0, [arg1 retain], [arg2 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock7)(void * , NSApplication* , NSDictionary* );
ListenerBlock7 wrapListenerBlock_ObjCBlock_ffiVoid_ffiVoid_NSApplication_NSDictionary(ListenerBlock7 block) {
  ListenerBlock7 wrapper = [^void(void * arg0, NSApplication* arg1, NSDictionary* arg2) {
    block(arg0, [arg1 retain], [arg2 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock8)(void * , NSApplication* , NSCoder* );
ListenerBlock8 wrapListenerBlock_ObjCBlock_ffiVoid_ffiVoid_NSApplication_NSCoder(ListenerBlock8 block) {
  ListenerBlock8 wrapper = [^void(void * arg0, NSApplication* arg1, NSCoder* arg2) {
    block(arg0, [arg1 retain], [arg2 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock9)(NSInputStream* , NSOutputStream* , NSError* );
ListenerBlock9 wrapListenerBlock_ObjCBlock_ffiVoid_NSInputStream_NSOutputStream_NSError(ListenerBlock9 block) {
  ListenerBlock9 wrapper = [^void(NSInputStream* arg0, NSOutputStream* arg1, NSError* arg2) {
    block([arg0 retain], [arg1 retain], [arg2 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock10)(NSTimer* );
ListenerBlock10 wrapListenerBlock_ObjCBlock_ffiVoid_NSTimer(ListenerBlock10 block) {
  ListenerBlock10 wrapper = [^void(NSTimer* arg0) {
    block([arg0 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock11)(NSArray* );
ListenerBlock11 wrapListenerBlock_ObjCBlock_ffiVoid_NSArray(ListenerBlock11 block) {
  ListenerBlock11 wrapper = [^void(NSArray* arg0) {
    block([arg0 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock12)(void * , NSApplication* , NSString* , NSError* );
ListenerBlock12 wrapListenerBlock_ObjCBlock_ffiVoid_ffiVoid_NSApplication_NSString_NSError(ListenerBlock12 block) {
  ListenerBlock12 wrapper = [^void(void * arg0, NSApplication* arg1, NSString* arg2, NSError* arg3) {
    block(arg0, [arg1 retain], [arg2 retain], [arg3 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock13)(void * , NSApplication* , NSUserActivity* );
ListenerBlock13 wrapListenerBlock_ObjCBlock_ffiVoid_ffiVoid_NSApplication_NSUserActivity(ListenerBlock13 block) {
  ListenerBlock13 wrapper = [^void(void * arg0, NSApplication* arg1, NSUserActivity* arg2) {
    block(arg0, [arg1 retain], [arg2 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock14)(void * , NSApplication* , CKShareMetadata* );
ListenerBlock14 wrapListenerBlock_ObjCBlock_ffiVoid_ffiVoid_NSApplication_CKShareMetadata(ListenerBlock14 block) {
  ListenerBlock14 wrapper = [^void(void * arg0, NSApplication* arg1, CKShareMetadata* arg2) {
    block(arg0, [arg1 retain], [arg2 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock15)(void * , NSNotification* );
ListenerBlock15 wrapListenerBlock_ObjCBlock_ffiVoid_ffiVoid_NSNotification(ListenerBlock15 block) {
  ListenerBlock15 wrapper = [^void(void * arg0, NSNotification* arg1) {
    block(arg0, [arg1 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock16)(NSURL* , NSError* );
ListenerBlock16 wrapListenerBlock_ObjCBlock_ffiVoid_NSURL_NSError(ListenerBlock16 block) {
  ListenerBlock16 wrapper = [^void(NSURL* arg0, NSError* arg1) {
    block([arg0 retain], [arg1 retain]);
  } copy];
  [block release];
  return wrapper;
}

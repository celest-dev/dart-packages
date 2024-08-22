#include <stdint.h>

#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIDevice.h>
#import <AuthenticationServices/ASFoundation.h>
#import <AuthenticationServices/ASWebAuthenticationSession.h>
#import <AuthenticationServices/ASWebAuthenticationSessionCallback.h>

typedef void  (^ListenerBlock)(NSTimer* );
ListenerBlock wrapListenerBlock_ObjCBlock_ffiVoid_NSTimer(ListenerBlock block) {
  ListenerBlock wrapper = [^void(NSTimer* arg0) {
    block([arg0 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock1)(UIImage* );
ListenerBlock1 wrapListenerBlock_ObjCBlock_ffiVoid_UIImage(ListenerBlock1 block) {
  ListenerBlock1 wrapper = [^void(UIImage* arg0) {
    block([arg0 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock2)(id );
ListenerBlock2 wrapListenerBlock_ObjCBlock_ffiVoid_objcObjCObject(ListenerBlock2 block) {
  ListenerBlock2 wrapper = [^void(id arg0) {
    block([arg0 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock3)(NSError* );
ListenerBlock3 wrapListenerBlock_ObjCBlock_ffiVoid_NSError(ListenerBlock3 block) {
  ListenerBlock3 wrapper = [^void(NSError* arg0) {
    block([arg0 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock4)(UIAction* );
ListenerBlock4 wrapListenerBlock_ObjCBlock_ffiVoid_UIAction(ListenerBlock4 block) {
  ListenerBlock4 wrapper = [^void(UIAction* arg0) {
    block([arg0 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock5)(UIAction* , id , void * , UIControlEvents , BOOL * );
ListenerBlock5 wrapListenerBlock_ObjCBlock_ffiVoid_UIAction_objcObjCObject_objcObjCSelector_UIControlEvents_bool(ListenerBlock5 block) {
  ListenerBlock5 wrapper = [^void(UIAction* arg0, id arg1, void * arg2, UIControlEvents arg3, BOOL * arg4) {
    block([arg0 retain], [arg1 retain], arg2, arg3, arg4);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock6)(NSInputStream* , NSOutputStream* , NSError* );
ListenerBlock6 wrapListenerBlock_ObjCBlock_ffiVoid_NSInputStream_NSOutputStream_NSError(ListenerBlock6 block) {
  ListenerBlock6 wrapper = [^void(NSInputStream* arg0, NSOutputStream* arg1, NSError* arg2) {
    block([arg0 retain], [arg1 retain], [arg2 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock7)(NSDate* , BOOL , BOOL * );
ListenerBlock7 wrapListenerBlock_ObjCBlock_ffiVoid_NSDate_bool_bool(ListenerBlock7 block) {
  ListenerBlock7 wrapper = [^void(NSDate* arg0, BOOL arg1, BOOL * arg2) {
    block([arg0 retain], arg1, arg2);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock8)(NSError* );
ListenerBlock8 wrapListenerBlock_ObjCBlock_ffiVoid_NSError1(ListenerBlock8 block) {
  ListenerBlock8 wrapper = [^void(NSError* arg0) {
    block([arg0 retain]);
  } copy];
  [block release];
  return wrapper;
}

typedef void  (^ListenerBlock9)(NSURL* , NSError* );
ListenerBlock9 wrapListenerBlock_ObjCBlock_ffiVoid_NSURL_NSError(ListenerBlock9 block) {
  ListenerBlock9 wrapper = [^void(NSURL* arg0, NSError* arg1) {
    block([arg0 retain], [arg1 retain]);
  } copy];
  [block release];
  return wrapper;
}

#include <stdint.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIDevice.h>
#import <AuthenticationServices/ASFoundation.h>
#import <AuthenticationServices/ASWebAuthenticationSession.h>
#import <AuthenticationServices/ASWebAuthenticationSessionCallback.h>

#if !__has_feature(objc_arc)
#error "This file must be compiled with ARC enabled"
#endif

id objc_retain(id);
id objc_retainBlock(id);

typedef void  (^ListenerBlock)(NSTimer* );
ListenerBlock wrapListenerBlock_ObjCBlock_ffiVoid_NSTimer(ListenerBlock block) NS_RETURNS_RETAINED {
  return ^void(NSTimer* arg0) {
    block(objc_retain(arg0));
  };
}

typedef void  (^ListenerBlock1)(UIImage* );
ListenerBlock1 wrapListenerBlock_ObjCBlock_ffiVoid_UIImage(ListenerBlock1 block) NS_RETURNS_RETAINED {
  return ^void(UIImage* arg0) {
    block(objc_retain(arg0));
  };
}

typedef void  (^ListenerBlock2)(id );
ListenerBlock2 wrapListenerBlock_ObjCBlock_ffiVoid_objcObjCObject(ListenerBlock2 block) NS_RETURNS_RETAINED {
  return ^void(id arg0) {
    block(objc_retain(arg0));
  };
}

typedef void  (^ListenerBlock3)(NSError* );
ListenerBlock3 wrapListenerBlock_ObjCBlock_ffiVoid_NSError(ListenerBlock3 block) NS_RETURNS_RETAINED {
  return ^void(NSError* arg0) {
    block(objc_retain(arg0));
  };
}

typedef void  (^ListenerBlock4)(UIAction* );
ListenerBlock4 wrapListenerBlock_ObjCBlock_ffiVoid_UIAction(ListenerBlock4 block) NS_RETURNS_RETAINED {
  return ^void(UIAction* arg0) {
    block(objc_retain(arg0));
  };
}

typedef void  (^ListenerBlock5)(UIAction* , id , void * , UIControlEvents , BOOL * );
ListenerBlock5 wrapListenerBlock_ObjCBlock_ffiVoid_UIAction_objcObjCObject_objcObjCSelector_UIControlEvents_bool(ListenerBlock5 block) NS_RETURNS_RETAINED {
  return ^void(UIAction* arg0, id arg1, void * arg2, UIControlEvents arg3, BOOL * arg4) {
    block(objc_retain(arg0), objc_retain(arg1), arg2, arg3, arg4);
  };
}

typedef void  (^ListenerBlock6)(NSInputStream* , NSOutputStream* , NSError* );
ListenerBlock6 wrapListenerBlock_ObjCBlock_ffiVoid_NSInputStream_NSOutputStream_NSError(ListenerBlock6 block) NS_RETURNS_RETAINED {
  return ^void(NSInputStream* arg0, NSOutputStream* arg1, NSError* arg2) {
    block(objc_retain(arg0), objc_retain(arg1), objc_retain(arg2));
  };
}

typedef void  (^ListenerBlock7)(NSDate* , BOOL , BOOL * );
ListenerBlock7 wrapListenerBlock_ObjCBlock_ffiVoid_NSDate_bool_bool(ListenerBlock7 block) NS_RETURNS_RETAINED {
  return ^void(NSDate* arg0, BOOL arg1, BOOL * arg2) {
    block(objc_retain(arg0), arg1, arg2);
  };
}

typedef void  (^ListenerBlock8)(NSError* );
ListenerBlock8 wrapListenerBlock_ObjCBlock_ffiVoid_NSError1(ListenerBlock8 block) NS_RETURNS_RETAINED {
  return ^void(NSError* arg0) {
    block(objc_retain(arg0));
  };
}

typedef void  (^ListenerBlock9)(NSURL* , NSError* );
ListenerBlock9 wrapListenerBlock_ObjCBlock_ffiVoid_NSURL_NSError(ListenerBlock9 block) NS_RETURNS_RETAINED {
  return ^void(NSURL* arg0, NSError* arg1) {
    block(objc_retain(arg0), objc_retain(arg1));
  };
}

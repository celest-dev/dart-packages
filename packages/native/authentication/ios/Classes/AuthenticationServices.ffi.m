#include <stdint.h>
#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIDevice.h>
#import <UIKit/UIWindowScene.h>
#import <AuthenticationServices/ASFoundation.h>
#import <AuthenticationServices/ASWebAuthenticationSession.h>
#import <AuthenticationServices/ASWebAuthenticationSessionCallback.h>

#if !__has_feature(objc_arc)
#error "This file must be compiled with ARC enabled"
#endif

typedef struct {
  int64_t version;
  void* (*newWaiter)(void);
  void (*awaitWaiter)(void*);
  void* (*currentIsolate)(void);
  void (*enterIsolate)(void*);
  void (*exitIsolate)(void);
  int64_t (*getMainPortId)(void);
  bool (*getCurrentThreadOwnsIsolate)(int64_t);
} DOBJC_Context;

id objc_retainBlock(id);

#define BLOCKING_BLOCK_IMPL(ctx, BLOCK_SIG, INVOKE_DIRECT, INVOKE_LISTENER)    \
  assert(ctx->version >= 1);                                                   \
  void* targetIsolate = ctx->currentIsolate();                                 \
  int64_t targetPort = ctx->getMainPortId == NULL ? 0 : ctx->getMainPortId();  \
  return BLOCK_SIG {                                                           \
    void* currentIsolate = ctx->currentIsolate();                              \
    bool mayEnterIsolate =                                                     \
        currentIsolate == NULL &&                                              \
        ctx->getCurrentThreadOwnsIsolate != NULL &&                            \
        ctx->getCurrentThreadOwnsIsolate(targetPort);                          \
    if (currentIsolate == targetIsolate || mayEnterIsolate) {                  \
      if (mayEnterIsolate) {                                                   \
        ctx->enterIsolate(targetIsolate);                                      \
      }                                                                        \
      INVOKE_DIRECT;                                                           \
      if (mayEnterIsolate) {                                                   \
        ctx->exitIsolate();                                                    \
      }                                                                        \
    } else {                                                                   \
      void* waiter = ctx->newWaiter();                                         \
      INVOKE_LISTENER;                                                         \
      ctx->awaitWaiter(waiter);                                                \
    }                                                                          \
  };


Protocol* _AuthenticationServicesIos_UIResponderStandardEditActions(void) { return @protocol(UIResponderStandardEditActions); }

typedef void  (^ListenerTrampoline)(id arg0);
__attribute__((visibility("default"))) __attribute__((used))
ListenerTrampoline _AuthenticationServicesIos_wrapListenerBlock_xtuoz7(ListenerTrampoline block) NS_RETURNS_RETAINED {
  return ^void(id arg0) {
    objc_retainBlock(block);
    block((__bridge id)(__bridge_retained void*)(arg0));
  };
}

typedef void  (^BlockingTrampoline)(void * waiter, id arg0);
__attribute__((visibility("default"))) __attribute__((used))
ListenerTrampoline _AuthenticationServicesIos_wrapBlockingBlock_xtuoz7(
    BlockingTrampoline block, BlockingTrampoline listenerBlock,
    DOBJC_Context* ctx) NS_RETURNS_RETAINED {
  BLOCKING_BLOCK_IMPL(ctx, ^void(id arg0), {
    objc_retainBlock(block);
    block(nil, (__bridge id)(__bridge_retained void*)(arg0));
  }, {
    objc_retainBlock(listenerBlock);
    listenerBlock(waiter, (__bridge id)(__bridge_retained void*)(arg0));
  });
}

Protocol* _AuthenticationServicesIos_UIStateRestoring(void) { return @protocol(UIStateRestoring); }

Protocol* _AuthenticationServicesIos_UISceneDelegate(void) { return @protocol(UISceneDelegate); }

typedef void  (^ListenerTrampoline_1)(BOOL arg0);
__attribute__((visibility("default"))) __attribute__((used))
ListenerTrampoline_1 _AuthenticationServicesIos_wrapListenerBlock_1s56lr9(ListenerTrampoline_1 block) NS_RETURNS_RETAINED {
  return ^void(BOOL arg0) {
    objc_retainBlock(block);
    block(arg0);
  };
}

typedef void  (^BlockingTrampoline_1)(void * waiter, BOOL arg0);
__attribute__((visibility("default"))) __attribute__((used))
ListenerTrampoline_1 _AuthenticationServicesIos_wrapBlockingBlock_1s56lr9(
    BlockingTrampoline_1 block, BlockingTrampoline_1 listenerBlock,
    DOBJC_Context* ctx) NS_RETURNS_RETAINED {
  BLOCKING_BLOCK_IMPL(ctx, ^void(BOOL arg0), {
    objc_retainBlock(block);
    block(nil, arg0);
  }, {
    objc_retainBlock(listenerBlock);
    listenerBlock(waiter, arg0);
  });
}

Protocol* _AuthenticationServicesIos_UITraitEnvironment(void) { return @protocol(UITraitEnvironment); }

Protocol* _AuthenticationServicesIos_UITraitChangeObservable(void) { return @protocol(UITraitChangeObservable); }

Protocol* _AuthenticationServicesIos_UIAppearance(void) { return @protocol(UIAppearance); }

Protocol* _AuthenticationServicesIos_UIAppearanceContainer(void) { return @protocol(UIAppearanceContainer); }

Protocol* _AuthenticationServicesIos_UIDynamicItem(void) { return @protocol(UIDynamicItem); }

Protocol* _AuthenticationServicesIos_UICoordinateSpace(void) { return @protocol(UICoordinateSpace); }

Protocol* _AuthenticationServicesIos_UIFocusEnvironment(void) { return @protocol(UIFocusEnvironment); }

Protocol* _AuthenticationServicesIos_UIFocusItem(void) { return @protocol(UIFocusItem); }

Protocol* _AuthenticationServicesIos_UIFocusItemContainer(void) { return @protocol(UIFocusItemContainer); }

Protocol* _AuthenticationServicesIos_CALayerDelegate(void) { return @protocol(CALayerDelegate); }

typedef void  (^ListenerTrampoline_2)(id arg0, id arg1);
__attribute__((visibility("default"))) __attribute__((used))
ListenerTrampoline_2 _AuthenticationServicesIos_wrapListenerBlock_pfv6jd(ListenerTrampoline_2 block) NS_RETURNS_RETAINED {
  return ^void(id arg0, id arg1) {
    objc_retainBlock(block);
    block((__bridge id)(__bridge_retained void*)(arg0), (__bridge id)(__bridge_retained void*)(arg1));
  };
}

typedef void  (^BlockingTrampoline_2)(void * waiter, id arg0, id arg1);
__attribute__((visibility("default"))) __attribute__((used))
ListenerTrampoline_2 _AuthenticationServicesIos_wrapBlockingBlock_pfv6jd(
    BlockingTrampoline_2 block, BlockingTrampoline_2 listenerBlock,
    DOBJC_Context* ctx) NS_RETURNS_RETAINED {
  BLOCKING_BLOCK_IMPL(ctx, ^void(id arg0, id arg1), {
    objc_retainBlock(block);
    block(nil, (__bridge id)(__bridge_retained void*)(arg0), (__bridge id)(__bridge_retained void*)(arg1));
  }, {
    objc_retainBlock(listenerBlock);
    listenerBlock(waiter, (__bridge id)(__bridge_retained void*)(arg0), (__bridge id)(__bridge_retained void*)(arg1));
  });
}

typedef id  (^ProtocolTrampoline)(void * sel);
__attribute__((visibility("default"))) __attribute__((used))
id  _AuthenticationServicesIos_protocolTrampoline_1mbt9g9(id target, void * sel) {
  return ((ProtocolTrampoline)((id (*)(id, SEL, SEL))objc_msgSend)(target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(sel);
}

typedef id  (^ProtocolTrampoline_1)(void * sel, id arg1);
__attribute__((visibility("default"))) __attribute__((used))
id  _AuthenticationServicesIos_protocolTrampoline_xr62hr(id target, void * sel, id arg1) {
  return ((ProtocolTrampoline_1)((id (*)(id, SEL, SEL))objc_msgSend)(target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(sel, arg1);
}

Protocol* _AuthenticationServicesIos_ASWebAuthenticationPresentationContextProviding(void) { return @protocol(ASWebAuthenticationPresentationContextProviding); }
#undef BLOCKING_BLOCK_IMPL

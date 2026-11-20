//
// Copyright (c) 2018 Bagel (https://github.com/yagiz/Bagel)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "BagelURLSessionInjector.h"
#import "Bagel.h"
#include <objc/runtime.h>

@implementation BagelURLSessionInjector

- (instancetype)initWithDelegate:(id<BagelURLSessionInjectorDelegate>)delegate
{
    self = [super init];

    if (self) {
        self.delegate = delegate;
        [self inject];
    }

    return self;
}

/*
 dump:
 - (void)_didFinishWithError:(id)arg1;
 - (void)_didReceiveData:(id)arg1;
 - (void)_didReceiveResponse:(id)arg1 sniff:(bool)arg2; // ~> iOS 12
 - (void)_didReceiveResponse:(id)arg1 sniff:(bool)arg2 rewrite:(bool)arg3; // some iOS 13 builds
 (verified on iOS 26.5 / 27.2 simulators: only `_didReceiveResponse:sniff:` exists)
 
 https://github.com/JackRostron/iOS8-Runtime-Headers
 https://github.com/ksenks/iOS9-Runtime-Headers
 https://github.com/JaviSoto/iOS10-Runtime-Headers
 https://github.com/LeoNatan/Apple-Runtime-Headers
 */

#pragma mark NSURLSession Injection

- (void)inject
{
    static dispatch_once_t NSURLSessionInjectionOnce;

    dispatch_once(&NSURLSessionInjectionOnce, ^{

        [self _inject];

    });
}

- (void)_inject
{
    // Connection class (receives response / data / completion callbacks):
    //   iOS 8             : __NSCFURLSessionConnection
    //   iOS 9 and later   : __NSCFURLLocalSessionConnection (verified on iOS 26.5 / 27.2)
    Class sessionClass = NSClassFromString(@"__NSCFURLLocalSessionConnection");

    if (sessionClass == nil) {
        sessionClass = NSClassFromString(@"__NSCFURLSessionConnection");
    }

    if (sessionClass) {
        [self swizzleSessionDidReceiveData:sessionClass];
        [self swizzleSessionDidReceiveResponse:sessionClass];
        [self swizzleSessiondDidFinishWithError:sessionClass];
    } else {
        NSLog(@"Bagel -> Warning: URLSession connection class not found. Responses will not be captured on this iOS version.");
    }

    // Task class that implements -resume:
    //   older iOS         : __NSCFURLSessionTask
    //   recent iOS        : NSURLSessionTask, inherited by __NSCFLocal*Task (verified on iOS 26.5 / 27.2)
    Class taskClass = NSClassFromString(@"__NSCFURLSessionTask");

    if (taskClass == nil) {
        taskClass = [NSURLSessionTask class];
    }

    [self swizzleSessionTaskResume:taskClass];
}

- (void)swizzleSessionTaskResume:(Class) class
{
    SEL selector = NSSelectorFromString(@"resume");
    Method m = class_getInstanceMethod(class, selector);

    if (m && [class instancesRespondToSelector:selector]) {

        typedef void (*OriginalIMPBlockType)(id self, SEL _cmd);
        OriginalIMPBlockType originalIMPBlock = (OriginalIMPBlockType)method_getImplementation(m);

        __weak BagelURLSessionInjector* weakSelf = self;

        void (^swizzledSessionTaskResume)(id) = ^void(id self) {

            // Only report the initial resume. Resuming a running or finished task
            // must not create a new entry in the desktop client.
            if ([self isKindOfClass:[NSURLSessionTask class]] &&
                ((NSURLSessionTask*)self).state == NSURLSessionTaskStateSuspended) {
                [weakSelf.delegate urlSessionInjector:weakSelf didStart:self];
            }

            originalIMPBlock(self, selector);
        };

        method_setImplementation(m, imp_implementationWithBlock(swizzledSessionTaskResume));
    }
}

- (void)swizzleSessionDidReceiveResponse:(Class) class
{
    // Some iOS 13 builds used `_didReceiveResponse:sniff:rewrite:`, while every
    // other version checked (including iOS 26.5 / 27.2) uses `_didReceiveResponse:sniff:`.
    // Probe the selectors instead of branching on the OS version.
    SEL rewriteSelector = NSSelectorFromString(@"_didReceiveResponse:sniff:rewrite:");
    Method rewriteMethod = class_getInstanceMethod(class, rewriteSelector);

    if (rewriteMethod && [class instancesRespondToSelector:rewriteSelector]) {

        typedef void (*OriginalIMPBlockType)(id self, SEL _cmd, id arg1, BOOL sniff, BOOL rewrite);
        OriginalIMPBlockType originalIMPBlock = (OriginalIMPBlockType)method_getImplementation(rewriteMethod);

        __weak BagelURLSessionInjector* weakSelf = self;

        void (^swizzledSessionDidReceiveResponse)(id, id, BOOL, BOOL) = ^void(id self, id arg1, BOOL sniff, BOOL rewrite) {

            [weakSelf.delegate urlSessionInjector:weakSelf didReceiveResponse:[self valueForKey:@"task"] response:arg1];

            originalIMPBlock(self, rewriteSelector, arg1, sniff, rewrite);
        };

        method_setImplementation(rewriteMethod, imp_implementationWithBlock(swizzledSessionDidReceiveResponse));
        return;
    }

    SEL selector = NSSelectorFromString(@"_didReceiveResponse:sniff:");
    Method m = class_getInstanceMethod(class, selector);

    if (m && [class instancesRespondToSelector:selector]) {

        typedef void (*OriginalIMPBlockType)(id self, SEL _cmd, id arg1, BOOL sniff);
        OriginalIMPBlockType originalIMPBlock = (OriginalIMPBlockType)method_getImplementation(m);

        __weak BagelURLSessionInjector* weakSelf = self;

        void (^swizzledSessionDidReceiveResponse)(id, id, BOOL) = ^void(id self, id arg1, BOOL sniff) {

            [weakSelf.delegate urlSessionInjector:weakSelf didReceiveResponse:[self valueForKey:@"task"] response:arg1];

            originalIMPBlock(self, selector, arg1, sniff);
        };

        method_setImplementation(m, imp_implementationWithBlock(swizzledSessionDidReceiveResponse));
    }
}

- (void)swizzleSessionDidReceiveData:(Class) class
{
    SEL selector = NSSelectorFromString(@"_didReceiveData:");
    Method m = class_getInstanceMethod(class, selector);

    if (m && [class instancesRespondToSelector:selector]) {

        typedef void (*OriginalIMPBlockType)(id self, SEL _cmd, id arg1);
        OriginalIMPBlockType originalIMPBlock = (OriginalIMPBlockType)method_getImplementation(m);

        __weak BagelURLSessionInjector* weakSelf = self;

        void (^swizzledSessionDidReceiveData)(id, id) = ^void(id self, id arg1) {

            [weakSelf.delegate urlSessionInjector:weakSelf didReceiveData:[self valueForKey:@"task"] data:[arg1 copy]];

            originalIMPBlock(self, selector, arg1);
        };

        method_setImplementation(m, imp_implementationWithBlock(swizzledSessionDidReceiveData));
    }
}

- (void)swizzleSessiondDidFinishWithError:(Class) class
{
    SEL selector = NSSelectorFromString(@"_didFinishWithError:");
    Method m = class_getInstanceMethod(class, selector);

    if (m && [class instancesRespondToSelector:selector]) {

        typedef void (*OriginalIMPBlockType)(id self, SEL _cmd, id arg1);
        OriginalIMPBlockType originalIMPBlock = (OriginalIMPBlockType)method_getImplementation(m);

        __weak BagelURLSessionInjector* weakSelf = self;

        void (^swizzledSessiondDidFinishWithError)(id, id) = ^void(id self, id arg1) {

            [weakSelf.delegate urlSessionInjector:weakSelf didFinishWithError:[self valueForKey:@"task"] error:arg1];

            originalIMPBlock(self, selector, arg1);
        };

        method_setImplementation(m, imp_implementationWithBlock(swizzledSessiondDidFinishWithError));
    }
}

@end

//
// Copyright 2011 Jeff Verkoeyen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "NIOverviewerSwizzling.h"

#ifdef NIMBUS_STATIC_LIBRARY
#import "NimbusCore/NimbusCore.h"
#else
#import "NimbusCore.h"
#endif

#import "NIOverviewer.h"


#ifdef DEBUG

@interface UIApplication (NIDebugging)

- (CGRect)_statusBarFrame;

@end


///////////////////////////////////////////////////////////////////////////////////////////////////
CGFloat NIOverviewerStatusBarHeight() {
  CGRect statusBarFrame = [[UIApplication sharedApplication] _statusBarFrame];
  CGFloat statusBarHeight = MIN(statusBarFrame.size.width, statusBarFrame.size.height);
  return statusBarHeight;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
void NIOverviewerSwizzleMethods() {
  NISwapInstanceMethods([UIViewController class],
                        @selector(_statusBarHeightForCurrentInterfaceOrientation),
                        @selector(__statusBarHeightForCurrentInterfaceOrientation));
  NISwapInstanceMethods([UIApplication class],
                        @selector(statusBarFrame),
                        @selector(_statusBarFrame));
  NISwapInstanceMethods([UIApplication class],
                        @selector(setStatusBarHidden:withAnimation:),
                        @selector(_setStatusBarHidden:withAnimation:));
  NISwapInstanceMethods([UIApplication class],
                        @selector(setStatusBarStyle:animated:),
                        @selector(_setStatusBarStyle:animated:));

}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation UIViewController (NIDebugging)


///////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * Swizzled implementation of private API - (float)_statusBarHeightForCurrentInterfaceOrientation
 *
 * This method is used by view controllers to adjust the size of their views.
 */
- (float)__statusBarHeightForCurrentInterfaceOrientation {
  return NIOverviewerStatusBarHeight() + [NIOverviewer height];
}

@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation UIApplication (NIDebugging)


///////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * Swizzled implementation of - (CGRect)statusBarFrame
 *
 * The real magic that causes view controllers to adjust their sizes happens in
 * __statusBarHeightForCurrentInterfaceOrientation. This method is swizzled purely
 * for application-level code that depends on statusBarFrame for calculations.
 */
- (CGRect)_statusBarFrame {
  return CGRectMake(0, 0,
                    CGFLOAT_MAX, NIOverviewerStatusBarHeight() + [NIOverviewer height]);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * Swizzled implementation of - (void)setStatusBarHidden:withAnimation:
 *
 * This allows us to hide the overviewer when the status bar is hidden.
 */
- (void)_setStatusBarHidden:(BOOL)hidden withAnimation:(UIStatusBarAnimation)animation {
  [self _setStatusBarHidden:hidden withAnimation:animation];

  if (UIStatusBarAnimationNone == animation) {
    [NIOverviewer view].alpha = 1;
    [NIOverviewer view].hidden = hidden;

  } else if (UIStatusBarAnimationSlide == animation) {
    [NIOverviewer view].alpha = 1;

    CGRect frame = [NIOverviewer frame];

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:NIStatusBarAnimationDuration()];
    [UIView setAnimationCurve:NIStatusBarAnimationCurve()];

    [NIOverviewer view].frame = frame;

    [UIView commitAnimations];
    
  } else if (UIStatusBarAnimationFade == animation) {
    CGRect frame = [NIOverviewer frame];
    [NIOverviewer view].frame = frame;

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:NIStatusBarAnimationDuration()];
    [UIView setAnimationCurve:NIStatusBarAnimationCurve()];
    
    [NIOverviewer view].alpha = hidden ? 0 : 1;
    
    [UIView commitAnimations];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * Swizzled implementation of - (void)setStatusBarStyle:animated:
 */
- (void)_setStatusBarStyle:(UIStatusBarStyle)statusBarStyle animated:(BOOL)animated {
  [self _setStatusBarStyle:statusBarStyle animated:animated];

  if (animated) {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
  }

  // TODO (jverkoey July 23, 2011): Add a translucent property to the overviewer view.
  if (UIStatusBarStyleDefault == statusBarStyle
      || UIStatusBarStyleBlackOpaque == statusBarStyle) {
    [NIOverviewer view].backgroundColor =
    [[NIOverviewer view].backgroundColor colorWithAlphaComponent:1];

  } else if (UIStatusBarStyleBlackTranslucent == statusBarStyle) {
    [NIOverviewer view].backgroundColor =
    [UIColor colorWithWhite:0 alpha:0.5];
  }

  if (animated) {
    [UIView commitAnimations];
  }
}


@end


#endif

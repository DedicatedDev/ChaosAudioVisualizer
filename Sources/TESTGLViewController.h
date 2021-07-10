//
//  testglViewController.h
//  testgl
//
//  Created by Serge Gorbachev on 9/28/11.
//  Copyright 2011 Rosberry. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OpenGLES/EAGL.h>

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "EAGLView.h"
@interface TESTGLViewController : UIViewController
{
@private
    EAGLContext *context;
    GLuint program;
    BOOL animating;
    NSInteger animationFrameInterval;
    double freq;
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;

@property (nonatomic, strong) CADisplayLink *displayLink;

@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *gestureSwipe;
- (IBAction)swipeAction:(id)sender;

- (void)startAnimation;
- (void)stopAnimation;
-(void)setHZ:(float)hz;
@end

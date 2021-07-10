//
//  SinusViewController.h
//  Sinus
//
//  Created by Serge Gorbachev on 10/12/11.
//  Copyright 2011 Rosberry. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OpenGLES/EAGL.h>

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface SinusViewController : UIViewController {
@private
    EAGLContext *context;
    GLuint program;
    BOOL animating;
    NSInteger animationFrameInterval;
    CADisplayLink *__unsafe_unretained displayLink;
    
    GLubyte *colorVertices1;
    GLubyte *colorVertices2;
    GLubyte *colorVertices3;
    GLubyte *colorVertices4;
    double step1,step2,step3,step4;
    int curentHZ;
    int mode;
    NSMutableArray *pointArray;
}
@property int mode;
@property (nonatomic,strong) NSMutableArray *pointArray;
@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil mode:(int)md;
- (void)startAnimation;
- (void)stopAnimation;
-(void)setScale:(NSDictionary*)scl;
@end

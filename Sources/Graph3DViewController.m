//
//  Graph3DViewController.m
//  AuraApp
//
//  Created by (´・ω・`) on 09.08.13.
//  Copyright (c) 2013 Quantum Life LLC. All rights reserved.
//

#import "Graph3DViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "TESTGLViewController.h"

const CGFloat _xAngularVelocity=0.181f, _yAngularVelocity=0.092f, _zAngularVelocity=0.033f;

@interface Graph3DViewController ()
{
	GLfloat _xAngle, _yAngle, _zAngle;
}

@end

@implementation Graph3DViewController

#pragma mark - Destroy

- (void) dealloc
{
	[self stopAnimation:self];

	// Tear down the context
	if( self.view.context == [EAGLContext currentContext] )
	{
		[EAGLContext setCurrentContext:nil];
	}
}

- (void)viewDidUnload
{
	[self stopAnimation:self];
	
	[self setView:nil];
	self.displayLink = nil;
	[super viewDidUnload];
}

#pragma mark Destroy
#pragma mark - Create

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if( self )
	{
		[self commonInit];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if( self )
	{
		[self commonInit];
	}
	return self;
}


- (void) commonInit
{
	_graph3D = [[Graph3DHarmonicsDrawPreset alloc] init];
	_preset = 0;
}



#pragma mark - View Controller Lifecycle stuff

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
	if( !context )
	{
		NSLog( @"Error : context set to GL1 unsucessfully :(");
		return ;
	}
	
	// Setup context : openGL ES 1.1
	[self.view setContext:context];
	// Enable transparency
	[self.view setOpaque:NO];
	// Prepare for drawing, without conflics with other openGL surfaces
	[self.view setFramebuffer];
}


- (void)didReceiveMemoryWarning
{
	; // DO nothing.
}


-(void)viewWillAppear:(BOOL)animated
{
	self.isSurfacePrepared = NO;
	[super viewWillAppear:animated];
}


-(void)viewDidAppear:(BOOL)animated
{
	self.isSurfacePrepared = NO;
	[super viewDidAppear:animated];
}


-(void)viewWillDisappear:(BOOL)animated
{
	self.isSurfacePrepared = NO;
	[self stopAnimation:self];
	[super viewWillDisappear:animated];
}


-(void)viewDidDisappear:(BOOL)animated
{
	self.isSurfacePrepared = NO;
	[super viewDidDisappear:animated];
}


#pragma mark - Drawing routine

//! draw each Frame. Must be called by display link.
- (void) drawFrame
{
	[self.view setFramebuffer];
	
	if( !self.isSurfacePrepared )
	{
		[self prepareSurface];
	}
	
	// clear everything
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
	
	// Applies subsequent matrix operations to the modelview matrix stack.
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	glFrustumf(-1.8f, 1.8f, -1.8, 1.8f, 53.0, 57.0);
	[self probeGLError];
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glTranslatef(0.0f, 0.0f, -55.0f);
	[self rotateMatrix];

	// Disable Textures
	glDisable(GL_TEXTURE_2D);
	
	// set line width
	glLineWidth(1.1f);
	[self probeGLError];
	
	// Enable vertex array, and set it
	glEnableClientState(GL_VERTEX_ARRAY);
	// Enable color array and set it
	glEnableClientState(GL_COLOR_ARRAY);

	[self.graph3D draw];
	[self probeGLError];
	
	[self.view presentFramebuffer];
}


- (void) rotateMatrix
{
	_xAngle += _xAngularVelocity;
	_yAngle += _yAngularVelocity;
	_zAngle += _zAngularVelocity;
	
	glRotatef(_xAngle, 1, 0, 0);
	glRotatef(_yAngle, 0, 1, 0);
	glRotatef(_zAngle, 0, 0, 1);
}


// Clear display from previously drawn objects
- (void) cleanup
{
	[self.view setFramebuffer];

	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
	[self probeGLError];
	
	[self.view presentFramebuffer];
}


//! check if there was an open GL error
- (void) probeGLError
{
	GLenum errorCode = glGetError();
	if( errorCode != GL_NO_ERROR )
	{
		NSLog( @"Error code: 0x%x", errorCode );
	}
}

//! Call it once before first frame draw. Need to call it again if openGL surface was teared down.
- (void) prepareSurface
{
	if( !self.displayLink ) return;
	
	// test for depth
	glEnable(GL_DEPTH_TEST);
	[self probeGLError];
	
	// depth function for depth
	glDepthFunc(GL_LEQUAL);
	[self probeGLError];

	// ??
	glDisable(GL_DITHER);
	[self probeGLError];
	
	// set line parameters. super-smooth lines.
	glEnable(GL_LINE_SMOOTH);
	[self probeGLError];
	glHint( GL_LINE_SMOOTH_HINT, GL_NICEST );
	[self probeGLError];

	self.isSurfacePrepared = YES;
}

- (void) setPreset:(NSUInteger)preset
{
	[self.graph3D setPreset:preset];
	_preset = preset;
}


#pragma mark - Animation control methods

- (IBAction) startAnimation:(id)sender
{
	if( self.displayLink ) return; 
	
	CADisplayLink *displayLink = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(drawFrame)];
	[displayLink setFrameInterval:1];
	[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

	self.displayLink = displayLink;
}

- (IBAction) stopAnimation:(id)sender
{
	[self.displayLink invalidate];
	
	self.displayLink = nil;
	self.isSurfacePrepared = NO;
	
	[self.view setNeedsDisplay];
}


- (IBAction) nextPreset:(id)sender
{
	self.preset++;
}

#pragma mark - 
- (IBAction)swipeAction:(id)sender
{
	NSLog( @"swiped!" );
	
    TESTGLViewController *testgl = (TESTGLViewController *)self.presentingViewController;
	if( [testgl isKindOfClass:[TESTGLViewController class]] )
	{
		[testgl stopAnimation];
	}

	//__weak id me = self;
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^
	{
		[self stopAnimation:NO];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"showOPneGLView" object:self userInfo:@{@"HZ":@(_preset)}];
	}];
}

@end

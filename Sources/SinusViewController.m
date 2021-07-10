//
//  SinusViewController.m
//  Sinus
//
//  Created by Serge Gorbachev on 10/12/11.
//  Copyright 2011 Rosberry. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "SinusViewController.h"
#import "EAGLView.h"
static int iter=800;
static double scaleY1=1,scaleY2=1,scaleY3=1,scaleY4=1;
// Uniform index.
enum {
    UNIFORM_TRANSLATE,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum {
    ATTRIB_VERTEX,
    ATTRIB_COLOR,
    NUM_ATTRIBUTES
};

@interface SinusViewController ()
@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, unsafe_unretained) CADisplayLink *displayLink;
- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation SinusViewController

@synthesize animating, context, displayLink;
@synthesize pointArray;
@synthesize mode;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil mode:(int)md
{
    self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self)
    {
        mode=md;
    }
    return self;
}

- (void)awakeFromNib
{
 //   mode=1;
    
    NSMutableArray *ar=[NSMutableArray array];
    self.pointArray=ar;
    EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    if (!aContext) {
        aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    step1=0;step2=0;step3=0;step4=0;
    if (!aContext)
        NSLog(@"Failed to create ES context");
    else if (![EAGLContext setCurrentContext:aContext])
        NSLog(@"Failed to set ES context current");
    
	self.context = aContext;
	
    [(EAGLView *)self.view setContext:context];
    [(EAGLView *)self.view setFramebuffer];
    
    if ([context API] == kEAGLRenderingAPIOpenGLES2)
        [self loadShaders];
    
    animating = FALSE;
    animationFrameInterval = 1;
    self.displayLink = nil;
}

- (void)dealloc
{
    free(colorVertices1);
    free(colorVertices2);
    free(colorVertices3);
    free(colorVertices4);
    if (program) {
        glDeleteProgram(program);
        program = 0;
    }
    
    // Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewWillAppear:(BOOL)animated
{
    curentHZ=-1;
    [self awakeFromNib];

    colorVertices1 =(GLubyte*)malloc(iter*4*sizeof(GLubyte)); 
    colorVertices2 =(GLubyte*)malloc(iter*4*sizeof(GLubyte));
    colorVertices3 =(GLubyte*)malloc(iter*4*sizeof(GLubyte));
    colorVertices4 =(GLubyte*)malloc(iter*4*sizeof(GLubyte));
    for (int i=0; i<iter; i++) {
        colorVertices1[i*4]=246;
        colorVertices1[i*4+1]=0;
        colorVertices1[i*4+2]=29;
        colorVertices1[i*4+3]=255;
        
        colorVertices2[i*4]=243;
        colorVertices2[i*4+1]=255;
        colorVertices2[i*4+2]=18;
        colorVertices2[i*4+3]=255;
        
        colorVertices3[i*4]=58;
        colorVertices3[i*4+1]=0;
        colorVertices3[i*4+2]=254;
        colorVertices3[i*4+3]=255;
        
        colorVertices4[i*4]=165;
        colorVertices4[i*4+1]=0;
        colorVertices4[i*4+2]=220;
        colorVertices4[i*4+3]=255;
    }
    [self startAnimation];
    [super viewWillAppear:animated];
   
}

- (void)viewWillDisappear:(BOOL)animated
{
//    [self performSelectorOnMainThread:@selector(stopAnimation) withObject:nil waitUntilDone:YES];
    [self stopAnimation];
    self.context=nil;
    self.displayLink=nil;
    [super viewWillDisappear:animated];
    
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
    if (program) {
        glDeleteProgram(program);
        program = 0;
    }
    
    // Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	self.context = nil;	
}

- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    /*
	 Frame interval defines how many display frames must pass between each time the display link fires.
	 The display link will only fire 30 times a second when the frame internal is two on a display that refreshes 60 times a second. The default frame interval setting of one will fire 60 times a second when the display refreshes at 60 times a second. A frame interval setting of less than one results in undefined behavior.
	 */
    if (frameInterval >= 1) {
        animationFrameInterval = frameInterval;
        
        if (animating) {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
    if (!animating) {
        CADisplayLink *aDisplayLink = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(drawFrame)];
        [aDisplayLink setFrameInterval:animationFrameInterval];
        [aDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.displayLink = aDisplayLink;
        animating = TRUE;
    }
}

- (void) stopAnimation
{
    if (animating)
	{
		[self.displayLink invalidate];
		self.displayLink = nil;
		animating = FALSE;
    }
}

- (void) setScale:(NSDictionary*)scl
{
	if ([[scl objectForKey:@"poorSignal"] doubleValue]>70)
	{
		// show flat graph if poor signal
		scaleY1=scaleY2=scaleY3=scaleY4=0;
	}
	else
	{
		// Normalize and make scale logarithmic
		scaleY1 = [self getNormalizedLogScaleValue:[scl[@"scale1"] floatValue]];
		scaleY2 = [self getNormalizedLogScaleValue:[scl[@"scale2"] floatValue]];
		scaleY3 = [self getNormalizedLogScaleValue:[scl[@"scale3"] floatValue]];
		scaleY4 = [self getNormalizedLogScaleValue:[scl[@"scale4"] floatValue]];
	}
	
	if ([scl objectForKey:@"lineWave"])
	{
		 curentHZ=[[scl objectForKey:@"lineWave"] intValue];
	}
	else
	{
		curentHZ=-1;
	}
}

/** Normalize value to 1.0 for showing sinus wave
 *	Use logarithmic scale
 *	Assume max malue is 10**7  10000000
 */
- (float) getNormalizedLogScaleValue:(float)value
{
	float log = log10f(value+1); // add 1 for random 0 values;
	return log / 7.0f;
}


-(void) drawFrame {
    double sc1,sc2,sc3,sc4;
    sc1=scaleY1;
    sc2=scaleY2;
    sc3=scaleY3;
    sc4=scaleY4;
    [(EAGLView *)self.view setFramebuffer];
    
    //     GL_COLOR_BUFFER_BIT, GL_DEPTH_BUFFER_BIT, GL_ACCUM_BUFFER_BIT, and GL_STENCIL_BUFFER_BIT.

    double x,y; 
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    GLfloat *squareVertices1 = (GLfloat*)malloc(iter*2*sizeof(GLfloat));
    GLfloat *squareVertices2 = (GLfloat*)malloc(iter*2*sizeof(GLfloat));
    GLfloat *squareVertices3 = (GLfloat*)malloc(iter*2*sizeof(GLfloat));
    
    GLfloat *squareVertices4 = (GLfloat*)malloc(iter*2*sizeof(GLfloat));
    x=-1;
    
    if (mode==0) {
        if(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) {
            for (int i=0; i<iter; i++) {

                                
                y=sc1*sin((6*x+step1)*M_PI)+2.8;
                squareVertices1[2*i]=x; 
                squareVertices1[2*i+1]=y*0.89*1/4;
              
                y=sc2*sin((4.5*x+step2)*M_PI)+1.0;
                squareVertices2[2*i]=x;
                squareVertices2[2*i+1]=y*0.89*1/4;
                
                y=sc3*sin((3.5*x+step3)*M_PI)-0.7;
                squareVertices3[2*i]=x;
                squareVertices3[2*i+1]=y*0.89*1/4;
                
                y=sc4*sin((2.0*x+step4)*M_PI)-2.5;
                squareVertices4[2*i]=x;
                squareVertices4[2*i+1]=y*0.89*1/4;
                
                x+=0.0025;
            }
        } else
		{
            for (int i=0; i<iter; i++)
			{
                
                y=0.4*sin((14*x+step1)*M_PI+40)+2.8;
                squareVertices1[2*i]=x; 
                squareVertices1[2*i+1]=y*0.89*1/4;
                
                y=sc2*sin((9*x+step2)*M_PI)+1.0;
                squareVertices2[2*i]=x;
                squareVertices2[2*i+1]=y*0.89*1/4;
                
                y=sc3*sin((3.5*x+step3)*M_PI)-0.9;
                squareVertices3[2*i]=x;
                squareVertices3[2*i+1]=y*0.89*1/4;
                
                y=sc4*sin((0.8*x+step4)*M_PI+33)-2.9;
                squareVertices4[2*i]=x;
                squareVertices4[2*i+1]=y*0.89*1/4;
                
                x+=0.0025;
            }
        }
    } else if(mode==1) {
        glLineWidth(2.0);
        for (int i=0; i<iter; i++) {
            y=sc1*sin((6*x+step1)*M_PI);
            squareVertices1[2*i]=x; 
            squareVertices1[2*i+1]=y*0.89;
            
            y=sc2*sin((4.5*x+step2)*M_PI);
            squareVertices2[2*i]=x;
            squareVertices2[2*i+1]=y*0.99;
            
            y=sc3*sin((3.5*x+step3)*M_PI);
            squareVertices3[2*i]=x;
            squareVertices3[2*i+1]=y*0.89;
            
            y=sc4*sin((2.0*x+step4)*M_PI);
            squareVertices4[2*i]=x;
            squareVertices4[2*i+1]=y*0.70;
            
            x+=0.0025;
        }
    }
    switch (curentHZ) {
        case 0:
        case 1:
            step1+=0.025;
            step2+=0.08;
            step3+=0.025;
            step4+=0.025;
            break;
        case 2:
        case 3:
            step1+=0.08;
            step4+=0.025;
            step3+=0.025;
            step2+=0.025;
            break;
        case 4:
        case 5:
            step1+=0.025;
            step4+=0.08;
            step3+=0.025;
            step2+=0.025;               
            break;
        case 6:
        case 7:
            step1+=0.025;
            step4+=0.025;
            step3+=0.08;
            step2+=0.025; 
            break;
        default:
            step1+=0.025;
            step4+=0.025;
            step3+=0.025;
            step2+=0.025; 
            break;
    }
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glVertexPointer(2, GL_FLOAT, 0, squareVertices1);
    glEnableClientState(GL_VERTEX_ARRAY);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, colorVertices1);
    glEnableClientState(GL_COLOR_ARRAY);
    glDrawArrays(GL_LINE_STRIP, 0, iter);
  
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glVertexPointer(2, GL_FLOAT, 0, squareVertices2);
    glEnableClientState(GL_VERTEX_ARRAY);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, colorVertices2);
    glEnableClientState(GL_COLOR_ARRAY);
    glDrawArrays(GL_LINE_STRIP, 0, iter);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glVertexPointer(2, GL_FLOAT, 0, squareVertices3);
    glEnableClientState(GL_VERTEX_ARRAY);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, colorVertices3);
    glEnableClientState(GL_COLOR_ARRAY);
    glDrawArrays(GL_LINE_STRIP, 0, iter);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glVertexPointer(2, GL_FLOAT, 0, squareVertices4);
    glEnableClientState(GL_VERTEX_ARRAY);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, colorVertices4);
    glEnableClientState(GL_COLOR_ARRAY);
    glDrawArrays(GL_LINE_STRIP, 0, iter);
  
    free(squareVertices1);
    free(squareVertices2);
    free(squareVertices3);
    free(squareVertices4);
    [(EAGLView *)self.view presentFramebuffer];
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    // Attach vertex shader to program.
    glAttachShader(program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(program, ATTRIB_COLOR, "color");
    
    // Link program.
    if (![self linkProgram:program])
    {
        NSLog(@"Failed to link program: %d", program);
        
        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program)
        {
            glDeleteProgram(program);
            program = 0;
        }
        
        return FALSE;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_TRANSLATE] = glGetUniformLocation(program, "translate");
    
    // Release vertex and fragment shaders.
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    return TRUE;
}

@end

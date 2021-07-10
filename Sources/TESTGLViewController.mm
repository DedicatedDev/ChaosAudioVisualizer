//
//  testglViewController.m
//  testgl
//
//  Created by Serge Gorbachev on 9/28/11.
//  Copyright 2011 Rosberry. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "TESTGLViewController.h"
#import "EAGLView.h"
#import "Graph3DViewController.h"
//#include "ColorScale.h"


GLenum doubleBuffer;
static int iter=8000;
static double rez=0;
typedef struct _vertexStruct
{
    GLfloat position[2];
    GLubyte color[4];
} vertexStruct;

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

class THarmoniGraph {
    
public:
    
    double f1,f2,f3,f4,
    p1,p2,p3,p4,
	r,
    _x, _y, t, tInc;
    GLubyte *colorVertices;    
    void SetPreset(int ix=-1)
    {
#define NVP 24
        // preset values
        struct _presetTag{ double f1, f2, f3,f4; } Preset[NVP]={
            {2, 2, 4, 32},
            { 17, 17,  34,  7 }, { 19, 19,  44,  14 }, { 2, 6,  2, 12}, { 9, 22,  6,  44},
            { 17, 5,  3,  25}, { 37, 34,  68,  14} , { 30, 30,  60,  40}, { 4, 12,  16,  8},
            { 64,30,100,40}, {64,30,20,74}, {60,30,86,43}, {36,66,11,22}, {11,33,66,97},
            {11,33,66,0}, {87,56,7,70}, {11,33,59,81}, {11,33,55,81}, {11,33,33,100},
            {33,33,33,89},{41,41,43,80}, {43,43,43,86}, {43,43,44,44}, {43,43,69,26}
        };
        
        static int r=0;
        
        if (ix==-1) r=r; // sequential index
        else { // check bounds
            if (ix<0) r=0; else 
                if (ix>=NVP) r=NVP-1; else r=ix;
        }
        
        f1=Preset[r].f1;   f2=Preset[r].f2;   f3=Preset[r].f3;   f4=Preset[r].f4;
        ++r%=NVP;
    }
    void initColor()
    {
        srand(time(NULL));
        colorVertices =new GLubyte[iter*4];// (GLubyte*)malloc(iter*sizeof(GLubyte)); 
        int star=arc4random()%155+100;
        int r=star;//  =arc4random()%200+55;
        int g=star;//=arc4random()%200+55;
        int b=star;//=arc4random()%200+55;
         for (int i=0; i<iter; i++) {
         //   int tc=ColorScaleHSL(0xff0000,0x0000ff,(double)i/iter); 
           // NSLog(@"%i %i %i",(tc&0xff),((tc&0xff00)>>8),((tc&0xff0000)>>16));
//            colorVertices[i*4]=(tc&0xff);
//            colorVertices[i*4+1]=((tc&0xff00)>>8);
//            colorVertices[i*4+2]=((tc&0xff0000)>>16);

//            
//            float r=arc4random()%255;
//            float g=arc4random()%255;
//            float b=arc4random()%255;
            colorVertices[i*4]=r;
            colorVertices[i*4+1]=g;
            colorVertices[i*4+2]=b;
            colorVertices[i*4+3]=255;
          
            if (g==star && b==star) { //r++
                if(++r==star+100)
                {
                    b++;
                }
            }
            else if(r==star+100 && g==star)//b++
            {
                if(++b==star+100)
                {
                    r--;
                }
            }
            else if(b==star+100 && g==star)//r--
            {
                if(--r==star)
                {
                    g++;
                }
            }
            else if(b==star+100 && r==star)//g++
            {
                if(++g==star+100)
                {
                    b--;
                }
            }
            else if(r==star && g==star+100)//g++
            {
                if(--b==star)
                {
                    g--;
                }
            }
            else if(r==star && b==star)//g--
            {
                if(--g==star)
                {
                    r++;
                }
            }
          // NSLog(@"%i %i %i",r,g,b);
        }
    }
    void clearColor()
    {
        delete [] colorVertices;
    }
    void calc(double&x, double&y)
    {
        _x=x=exp(-r*t) * ( sin(f1*t+p1) + sin(f2*t+p2) );
        _y=y=exp(-r*t) * ( sin(f3*t+p3) + sin(f4*t+p4) );
        t+=tInc;
    }
    void releazeColor()
    {
         delete [] colorVertices;
    }
    void SetFreq(double _f1,double _f2,double _f3,double _f4)
    {  f1=_f1; f2=_f2; f3=_f3; f4=_f4;  }
    
    
    void SelectHz(double hz) // select a preset plot from a hz in the range 300..1000 hz
    {
        if (hz<300)  hz=300; else
            if (hz>1000) hz=1000;
        
        int ix=NVP * ((hz-300.)/700.);
        SetPreset(ix);
        
    }
    
    void SetPhase(double _p1,double _p2,double _p3,double _p4)
    {  p1=_p1; p2=_p2; p3=_p3; p4=_p4;  }
    
    void init(void)
    {
        t=0;
    }
    
    void plot()
    {
        double x,y; 
        init();
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        GLfloat *squareVertices = new GLfloat[iter*2];
        
        for (int i=0; i<iter; i++) {
            calc(x,y);
            squareVertices[2*i]= x/2;
            squareVertices[2*i+1]=y/2; 
        }
        
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
         
        
        glVertexPointer(2, GL_FLOAT, 0, squareVertices);
        glEnableClientState(GL_VERTEX_ARRAY);
        glColorPointer(4, GL_UNSIGNED_BYTE, 0, colorVertices);
        glEnableClientState(GL_COLOR_ARRAY);
        glLineWidth(1.1);
        glDrawArrays(GL_LINE_STRIP, 0, iter);//GL_TRIANGLE_STRIP  GL_LINE_STRIP
        delete [] squareVertices;
    }
    
    THarmoniGraph(void)
    {
        f1=5; f2=3; f3=10; f4=4;
        p1=p2=p3=p4=0;
        r=0.001;
        tInc=0.0031;
        //GLubyte *colorVertices ;
        init();
    }
};
THarmoniGraph hg;

void Init(void)
{
	hg.SetPreset(); // select preset value
}


void Key(unsigned char key, int x, int y)
{
    switch (key) {
        case 27 : exit(0); break;
        case ' ': hg.SetPreset(); break; // next preset
        case 'f': hg.SelectHz((double)1000.*random()/RAND_MAX); break; // select a certain freq
    }
}


//    typedef struct _vertexStruct
//    {
//        GLfloat position[2];
//        GLubyte color[4];
//    } vertexStruct;

//void DrawGeometry()
//{
//    const vertexStruct vertices[] = {...};
//    const GLubyte indices[] = {...};
//    
//    glEnableClientState(GL_VERTEX_ARRAY);
//    glVertexPointer(2, GL_FLOAT, sizeof(vertexStruct), &vertices[0].position);
//    glEnableClientState(GL_COLOR_ARRAY);
//    glColorPointer(4, GL_UNSIGNED_BYTE, sizeof(vertexStruct), &vertices[0].color);
//    
//    glDrawElements(GL_TRIANGLE_STRIP, sizeof(indices)/sizeof(GLubyte), GL_UNSIGNED_BYTE, indices);
//}




// Uniform index.

@interface TESTGLViewController ()
@property (nonatomic, strong) EAGLContext *context;
- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation TESTGLViewController

@synthesize animating, context;

- (void)awakeFromNib
{
    EAGLContext *aContext = nil;
	@try
	{
		aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
	}
	@catch(...)
	{
		aContext = nil;
	}
    freq=3;
    if (!aContext) {
        aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    
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
    [self awakeFromNib];
    [super viewWillAppear:animated];
}

- (void) setHZ_internal
{
	srand(time(0));
	double h1,h2,h3,h4;
	
	h1=rand()%100;
	h2=rand()%100;
	h3=rand()%100;
	h4=rand()%100;

	NSLog(@"rez %f",rez);
	hg.SetFreq(h1,h2,h3,h4);
	hg.SelectHz(rez);
}


-(void)setHZ:(float)hz
{
    rez=hz;
	[self setHZ_internal];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [self stopAnimation];
//    hg.releazeColor();
    self.context=nil;
    self.displayLink=nil;
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
	[self setGestureSwipe:nil];
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

#pragma mark - Custom Actions
- (IBAction)swipeAction:(id)sender
{
	NSLog( @"swiped!");

	Graph3DViewController *graph3D = [[Graph3DViewController alloc] init];
	[graph3D setPreset:[@(rez) integerValue]];
	
//	AuraAppAppDelegate *appDelegate = (AuraAppAppDelegate *)[UIApplication sharedApplication].delegate;
    [self presentViewController:graph3D animated:YES completion:nil];
	[graph3D performSelector:@selector(startAnimation:) withObject:nil afterDelay:0.4f];
	[self stopAnimation];
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
        hg.initColor();
        CADisplayLink *aDisplayLink = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(drawFrame)];
        [aDisplayLink setFrameInterval:animationFrameInterval];
        [aDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.displayLink = aDisplayLink;
        
        animating = TRUE;
    }
}

- (void)stopAnimation
{
    if (animating) {
        hg.clearColor();
        [self.displayLink invalidate];
        self.displayLink = nil;
        animating = FALSE;
    }
}


- (void)drawFrame
{
    [(EAGLView *)self.view setFramebuffer];
    
    glLoadIdentity();
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT ); // clear screen
    glTranslatef(0, -6, -60); // zoom, loca
    
    hg.plot();
    hg.p1+=freq/200.; // 0.02; animation ratio
    hg.p3+=freq/100.;
    
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

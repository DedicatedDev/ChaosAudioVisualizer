//
//  Graph3DHarmonicsDrawPreset.m
//  Graph3DHarmonics
//
//  Created by Megal on 12.08.13.
//  Copyright (c) 2013 Lodoss Team Ltd. All rights reserved.
//

#import "Graph3DHarmonicsDrawPreset.h"
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>


#ifdef __cplusplus
extern "C"
{
#endif
	
float clampf(const float value, const float min, const float max )
{
	return ( value<min ) ? min : ( value>max ) ? max : value;
}

int clampi(const int value, const int min, const int max )
{
	return ( value<min ) ? min : ( value>max ) ? max : value;
}

#ifdef __cplusplus
}
#endif

// presets structure p1 p2 p3 f1 f2 colorMode
const GLfloat presets[][6]=
{
	{1,2,3, 0.46f, 1.5e-8f,	1},		{2,3,4,.25f,0,	2},			{1,3,1,.25f,1.5e-8f,4},		{2,1,3,0.37f,0,	2},
	{2,2,11,0.25f,1.5e-8f,	2},		{1,1,1.01f,.25f,.29f,0},	{4,4,22,.25f,0,4},			{1,1,4,.43f,1.5e-8f, 3},
	{1,2,0,.1f,.3f,2},				{6,3,2,.21f,.3f,0},			{1,2,-1,.1f,.3f,2},			{6,-3,2,.21f,.3f,0}
};

const size_t kInterpolationFractionCount = 64;

@interface Graph3DHarmonicsDrawPreset ()
{
	GLfloat	*_arrayVetrex;
	GLfloat	*_arrayColor;
	size_t	_countVertex;
	
	/** local variables for calculations
	 *  position(xyz) and color(rgba)
	 */
	GLfloat x,y,z,a,r,g,b;

	float period; // ??
	float spSpace; // segment length
	float size; // is 1, don't change it
	float distance; // is 1, affects color in some presets
	float range; // ??
}

@end

@implementation Graph3DHarmonicsDrawPreset

- (void) dealloc
{
	free(_arrayVetrex);
	free(_arrayColor);
}


- (id) init
{
	self = [super init];
	if( self )
	{
		[self commonInit];
	}
	
	return self;
}


- (void) commonInit
{
	spSpace=6e-5f;
	size=1;
	distance=1;
	
	[self setPreset:0];
}


- (void) draw
{
	glVertexPointer(3, GL_FLOAT, 0, _arrayVetrex);
	glColorPointer(4, GL_FLOAT, 0, _arrayColor);
	glDrawArrays(GL_LINE_STRIP, 0, _countVertex);
}


- (void) setPreset:(NSUInteger)preset
{
	_preset = preset % 12; // presets count
	[self calcCoords];
}


- (void) calcCoords
{
	_countVertex = size / spSpace;
	range=size; period=0;

	free(_arrayVetrex);
	free(_arrayColor);
	_arrayVetrex = malloc( _countVertex*3*sizeof(GLfloat)); // xyz * size of float
	_arrayColor = malloc( _countVertex*4*sizeof(GLfloat)); // RGBA * size of float
	for( int i=0; i<_countVertex; ++i )
	{
		int indexV = i*3;
		int indexC = i*4;
		
		[self calcSegment:i]; // -> xyzrgba
		
		_arrayVetrex[indexV+0]	= x;
		_arrayVetrex[indexV+1]	= y;
		_arrayVetrex[indexV+2]	= z;
		_arrayColor[indexC+0]	= r;
		_arrayColor[indexC+1]	= g;
		_arrayColor[indexC+2]	= b;
		_arrayColor[indexC+3]	= a;
	}
}


// calc position for next point
- (void) calcSegment:(NSUInteger) index
{
	// presets structure p1 p2 p3 f1 f2 colorMode
	float prop;
	period += 0.02f; range-=spSpace;
	x = range * sinf(period*presets[_preset][0]); // p2*period
	y = range * sinf(period*presets[_preset][1] + (float)M_PI_2*presets[_preset][3]); // p1*period + 0.5*pi*f1
	z = range * sinf(period*presets[_preset][2] + (float)M_PI_2*presets[_preset][4]);
	
	int colorMode = (int)presets[_preset][5];
	switch( colorMode )
	{
		case 0:		prop=((float)index)/_countVertex; break;
		case 1:		prop=fmodf( (z/(size*2) + 0.5f), 1.0f ); break;
		case 2:		prop=(x*x+y*y+z*z) / 1.71; break; // modified.. original : sqrt(x**2+y**2+z**2)
		case 3:		prop=fmodf( period/M_PI_2, 1.0f ); break;
		case 4:		prop=fmodf( period/M_PI_2/8, 1.0f ); break;
		default:	prop=1; break;
	}
	
	static UIColor *fromColor;
	static UIColor *toColor;
	static CGFloat rgbaInterpolated[kInterpolationFractionCount][4];
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^
	{
		// colorIndex.. skip implementation - interpolated color between RED and BLUE.. hsv-interpolated
		fromColor = [UIColor colorWithHue:1.0 saturation:1.0 brightness:1.0 alpha:1.0];
		toColor = [UIColor colorWithHue:0.66667 saturation:1.0 brightness:1.0 alpha:0.6667];
		
		// pre-calculate kInterpolationFractionCount interpolations
		for( int ratioindex = 0; ratioindex<kInterpolationFractionCount; ++ratioindex )
		@autoreleasepool
		{
			float ratio = 1.0f * (ratioindex / (float)(kInterpolationFractionCount-1));
			UIColor *interpolatedColor = [self interpolatedFromColor:fromColor toColor:toColor ratio:ratio];
			[interpolatedColor getRed:&r green:&g blue:&b alpha:&a];
			rgbaInterpolated[ratioindex][0] = r;
			rgbaInterpolated[ratioindex][1] = g;
			rgbaInterpolated[ratioindex][2] = b;
			rgbaInterpolated[ratioindex][3] = a;
		}
	});

	// get color from interpolated table
	int ratioindex = clampi( (int)floorf(prop*(kInterpolationFractionCount-1) + FLT_EPSILON), 0, kInterpolationFractionCount-1);
	assert( ratioindex>=0 && ratioindex<kInterpolationFractionCount );
	r = rgbaInterpolated[ratioindex][0];
	g = rgbaInterpolated[ratioindex][1];
	b = rgbaInterpolated[ratioindex][2];
	a = rgbaInterpolated[ratioindex][3];
}


//! HSVA hue[0..1] -> [0.. 2pi], saturation = [0..1], value = [0..1]
- (UIColor *) interpolatedFromColor:(UIColor *)fromColor toColor:(UIColor *)toColor ratio:(float)ratio
{
	float antiratio = 1.0f - ratio;
	CGFloat hStart, sStart, vStart, aStart,
			hEnd, sEnd, vEnd, aEnd,
			hInterpolated, sInterpolated, vInterpolated, aInterpolated;
	
	[fromColor getHue:&hStart saturation:&sStart brightness:&vStart alpha:&aStart];
	[toColor getHue:&hEnd saturation:&sEnd brightness:&vEnd alpha:&aEnd];
	
	// iterpalate in proportion ratio, on longest Hue path
	hInterpolated = ( fabsf(hStart - hEnd) > 0.5f )
			?(ratio*hStart + antiratio*hEnd)
			:(ratio*hStart + antiratio*(1+hEnd));
	hInterpolated = fmodf(hInterpolated, 1.0f);
	
	sInterpolated = (ratio*sStart + antiratio*sEnd);
	vInterpolated = (ratio*vStart + antiratio*vEnd);
	aInterpolated = (ratio*aStart + antiratio*aEnd);
 	
	UIColor *interpolatedColor = [UIColor colorWithHue:hInterpolated
											saturation:sInterpolated
											brightness:vInterpolated
												 alpha:aInterpolated];
	
	return interpolatedColor;
}


@end

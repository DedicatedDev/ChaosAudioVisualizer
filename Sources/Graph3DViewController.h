//
//  Graph3DViewController.h
//  AuraApp
//
//  Created by (´・ω・`) on 09.08.13.
//  Copyright (c) 2013 Quantum Life LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EAGLView.h"
#import "Graph3DHarmonicsDrawPreset.h"
#import "testglViewController.h"

@interface Graph3DViewController : UIViewController

@property (strong, nonatomic) IBOutlet EAGLView 			*view;
@property (weak, nonatomic) CADisplayLink					*displayLink;
@property (atomic, assign) BOOL								isSurfacePrepared;
@property (strong, nonatomic) Graph3DHarmonicsDrawPreset	*graph3D;
@property (nonatomic, assign) NSUInteger					preset;

#pragma mark - Animation control methods
- (IBAction) startAnimation:(id)sender;
- (IBAction) stopAnimation:(id)sender;
- (IBAction) nextPreset:(id)sender;

@end

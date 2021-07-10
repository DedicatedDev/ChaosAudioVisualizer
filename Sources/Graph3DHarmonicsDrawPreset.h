//
//  Graph3DHarmonicsDrawPreset.h
//  Graph3DHarmonics
//
//  Created by Megal on 12.08.13.
//  Copyright (c) 2013 Lodoss Team Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Graph3DHarmonicsDrawPreset : NSObject

@property ( nonatomic, assign ) NSUInteger	preset;

//! will set 3d graph vertexes, colors, and will draw lines
- (void) draw;

- (void) setPreset:(NSUInteger)preset;

@end

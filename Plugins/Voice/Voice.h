//
//  Voice.h
//  malpais
//
//  Created by ole kristensen on 16/02/11.
//  Copyright 2011 Recoil Performance Group. All rights reserved.
//

#pragma once
#include "Plugin.h"
#include "MSAInterpolator.h"
#include "Wave.h"
#include "ofxPoint2f.h"

@interface Voice : ofPlugin {
	
	NSDictionary * voice;
	NSMutableArray * waveForms;
	
}

- (float) aspect;



@end

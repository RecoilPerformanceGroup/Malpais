//
//  Beach.h
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

@interface Beach : ofPlugin {
	
	MSA::Interpolator1D	* waveForm[NUM_VOICES+1];
	
	NSMutableArray * waves;
	
}

- (float) aspect;
- (void) drawWave:(int)iVoice from:(ofxPoint2f*)begin to:(ofxPoint2f*)end;



@end

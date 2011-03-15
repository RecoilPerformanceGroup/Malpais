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

#define ROLL_POS_HISTORY_LENGTH 600

@interface Beach : ofPlugin {
	
	MSA::Interpolator1D	* waveForm[NUM_VOICES+1];
	float waveFormYpos[NUM_VOICES+1];
	NSMutableArray * voices;
	vector<float> rollPosHistory;
	ofImage gradient;
	
}

- (float) aspect;
- (void) drawWave:(int)iVoice from:(ofxPoint2f*)begin to:(ofxPoint2f*)end;



@end

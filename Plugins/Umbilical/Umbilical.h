#pragma once

#include "Plugin.h"
#include "MSAInterpolator.h"
#include "ofxVec2f.h"

@interface Umbilical : ofPlugin {
	
	float mousex,mousey,mouseh;

	MSA::Interpolator1D		* distortion;
	
	NSMutableArray * wave;
	
	bool reversed;
	
	ofxVec2f startPos;
	ofxVec2f endPos;
	
}

-(float) aspect;


@end
